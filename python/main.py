import boto3
import datetime

# AWS services
ec2 = boto3.client('ec2', region_name='ap-south-1')
sns = boto3.client('sns')

# Tag key and value to identify instances for backup
TAG_KEY = 'Backup'
TAG_VALUE = 'Weekly'

def get_instances_for_backup():
    instances = []
    response = ec2.describe_instances(
        Filters=[
            {
                'Name': f'tag:{TAG_KEY}',
                'Values': [TAG_VALUE]
            }
        ]
    )
    # response = ec2.describe_instances()
    
    print("Instances", *instances)

    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instances.append(instance['InstanceId'])

    return instances

def create_ami(instance_id):
    current_time = datetime.datetime.now()
    ami_name = f'Weekly-Backup-{instance_id}-{current_time.strftime("%Y-%m-%d-%H-%M-%S")}'

    response = ec2.create_image(
        InstanceId=instance_id,
        Name=ami_name,
        Description=f'AMI created on {current_time}',
        NoReboot=True  # You can choose to reboot or not
    )

    return response['ImageId']

def delete_old_amis():
    current_time = datetime.datetime.now()
    ami_creation_date = current_time - datetime.timedelta(days=30)
    amis = ec2.describe_images(Filters=[{'Name': 'name', 'Values': ['Weekly-Backup-*']}])['Images']

    for ami in amis:
        if ami['CreationDate'] < ami_creation_date.isoformat():
            ec2.deregister_image(ImageId=ami['ImageId'])
            print(f"Deleted old AMI: {ami['ImageId']}")

def lambda_handler(event, context):
    # Get EC2 instances to back up based on tags
    # instance_ids = get_instances_for_backup()
    instance_ids = ["i-013075a9d0537eb4f", "i-0ddc67f401c400cde", "i-049f7882df97a83dd", "i-049f7882df97a83dd", "i-0e5e5d97e79e072ca"]

    ami_ids = []

    for instance_id in instance_ids:
        ami_id = create_ami(instance_id)
        ami_ids.append(ami_id)

    # Delete AMIs older than 30 days
    delete_old_amis()

    # Send a notification using Amazon SNS
    sns_topic_arn = 'arn:aws:sns:ap-south-1:778694034991:AMIUpdate'  # Replace with your SNS topic ARN
    sns_message = f"AMI(s) {', '.join(ami_ids)} created on {datetime.datetime.now()}."

    sns.publish(
        TopicArn=sns_topic_arn,
        Message=sns_message,
        Subject='AMI Backup Notification'
    )

    return {
        'statusCode': 200,
        'body': 'AMI backup process completed successfully.'
    }


# get_instances_for_backup()