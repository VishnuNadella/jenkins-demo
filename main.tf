terraform {
#   backend "remote" {
#     # cant use variables in this scope
#     # organization = var.organisation_name
#     organization = "learning-terraform-vn"
#     workspaces {
#       name = "Example-Workspace"
#     }
#   }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-south-1"
}


resource "aws_instance" "app_server" {
  ami           = "ami-067c21fb1979f0b27"
  instance_type = "t2.micro"
  count = 5

  tags = { 
    Name = "ExampleAppServerInstance.${count.index}"
    Backup = "Weekly"
  }
}


resource "aws_iam_policy" "ec2_describe_policy" {
  name        = "ec2_describe_policy"
  path        = "/"
  description = "ec2 describe policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement: [
    {
      Effect: "Allow",
      Action: [
        "ec2:Describe*",
        "ec2:Get*",
        "ec2:List*",
        "ec2:Create*"
      ],
      Resource: "*"
    }
  ]
  })
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  # policy_arn = aws_iam_policy.ec2_describe_policy.arn
}

# resource "aws_iam_user" "terraform_user" {
#   name = "learning_update"
# }

resource "aws_iam_user_policy_attachment" "attach_ec2_describe_policy" {
  user       = "learning_update"
  policy_arn = aws_iam_policy.ec2_describe_policy.arn
}




data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/python/"
  output_path = "${path.module}/python/main.zip"
}


# resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
#   role = aws_iam_role.lambda_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
# }

# resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment_2" {
#   role = aws_iam_role.lambda_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
# }



resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "${path.module}/python/main.zip"
  function_name = "IAMUpdate_lambda_function"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.8"

  depends_on = [  ]
}






resource "aws_cloudwatch_event_rule" "example" {
  name        = "example_weekly_schedule"
  description = "Schedule Lambda execution weekly on Sundays at 5 AM EST"

  schedule_expression = "cron(0 5 ? * 1 *)" # Schedule at 5 AM on Sundays (0 5) in UTC, which is 1 AM EST
}

resource "aws_cloudwatch_event_target" "example" {
  rule      = aws_cloudwatch_event_rule.example.name
  target_id = "example_target"
  arn       = aws_lambda_function.test_lambda.arn
}
