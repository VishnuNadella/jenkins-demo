# resource "aws_iam_role" "lambda_role" {
#   name = "lambda_role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "lambda.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_policy" "iam_lambda_policy" {
#   name        = "aws_iam_policy_for_terraform_aws_lambda_role"
#   path        = "/"
#   description = "AWS IAM Policy for managing aws lambda role"

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = ["lambda:InvokeFunction"]
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
#   role        = aws_iam_role.lambda_role.name
#   policy_arn  = aws_iam_policy.iam_lambda_policy.arn
# }

# data "archive_file" "zip_the_python_code" {
#  type        = "zip"
#  source_dir  = "${path.module}/python/"
#  output_path = "${path.module}/python/main.zip"
# }








# data "aws_iam_policy_document" "assume_role" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }

# resource "aws_iam_role" "iam_for_lambda" {
#   name               = "iam_for_lambda"
#   assume_role_policy = data.aws_iam_policy_document.assume_role.json
# }

# data "archive_file" "lambda" {
#   type        = "zip"
#   source_dir  = "${path.module}/python/"
#   output_path = "${path.module}/python/main.zip"
# }

# resource "aws_lambda_function" "test_lambda" {
#   # If the file is not in the current working directory you will need to include a
#   # path.module in the filename.
#   filename      = "${path.module}/python/main.zip"
#   function_name = "IAMUpdate_lambda_function"
#   role          = aws_iam_role.iam_for_lambda.arn
#   handler       = "main.lambda_handler"

#   source_code_hash = data.archive_file.lambda.output_base64sha256

#   runtime = "python3.8"
# }