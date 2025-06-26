A Lambda function that:
Checks EC2 instance health
Restarts a service (via SSM Run Command)
Reboots the instance if the service fails
Sends notifications via Slack
Uploads logs to S3
Can be triggered by CloudWatch Events (e.g., every 5 minutes)

Architecture Summary
 Lambda Function (Python 3.12)
 SSM Agent installed on EC2 (for remote commands)
 IAM role with ec2, ssm, s3, and logs permissions
 Optional Slack webhook for notifications

 Required IAM Permissions for Lambda Role

Attach this to the Lambda execution role:
-------------------------------------------
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation",
        "ec2:RebootInstances",
        "s3:PutObject",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
------------------------------------------
Environment Variables for Lambda
Variable	Description
INSTANCE_ID	EC2 instance ID to monitor
SERVICE_NAME	Name of the Linux service 
S3_BUCKET	S3 bucket name to upload logs
SLACK_WEBHOOK	Slack incoming webhook URL

Trigger with CloudWatch Rule
To run every 5 minutes:

Go to EventBridge → Create Rule
Schedule: rate(5 minutes)
Target: Your Lambda function