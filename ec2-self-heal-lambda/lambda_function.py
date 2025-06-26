import boto3
import os
import json
import datetime
import requests

# Constants (update as needed)
INSTANCE_ID = os.environ.get("INSTANCE_ID")
SERVICE_NAME = os.environ.get("SERVICE_NAME", "nginx")
S3_BUCKET = os.environ.get("S3_BUCKET")
SLACK_WEBHOOK = os.environ.get("SLACK_WEBHOOK")

ssm = boto3.client('ssm')
ec2 = boto3.client('ec2')
s3 = boto3.client('s3')

def send_slack(message):
    if SLACK_WEBHOOK:
        requests.post(SLACK_WEBHOOK, json={"text": message})

def run_command(instance_id, command):
    response = ssm.send_command(
        InstanceIds=[instance_id],
        DocumentName="AWS-RunShellScript",
        Parameters={"commands": [command]},
    )
    return response["Command"]["CommandId"]

def get_command_output(command_id, instance_id):
    output = ssm.get_command_invocation(
        CommandId=command_id,
        InstanceId=instance_id,
    )
    return output.get("StandardOutputContent", ""), output.get("StandardErrorContent", "")

def lambda_handler(event, context):
    now = datetime.datetime.utcnow().strftime("%Y-%m-%d-%H%M%S")
    print(f"Checking service {SERVICE_NAME} on {INSTANCE_ID}...")

    # 1. Check service status
    cmd_id = run_command(INSTANCE_ID, f"systemctl is-active {SERVICE_NAME}")
    stdout, stderr = get_command_output(cmd_id, INSTANCE_ID)

    if "active" in stdout:
        print("Service is running.")
        return {"status": "healthy"}

    print(" Service is not running. Attempting restart...")
    send_slack(f"[Auto-Heal] {SERVICE_NAME} on {INSTANCE_ID} is down. Attempting to restart...")

    # 2. Try restarting the service
    run_command(INSTANCE_ID, f"systemctl restart {SERVICE_NAME}")
    
    # 3. Re-check status
    cmd_id = run_command(INSTANCE_ID, f"systemctl is-active {SERVICE_NAME}")
    stdout, stderr = get_command_output(cmd_id, INSTANCE_ID)

    if "active" in stdout:
        send_slack(f" {SERVICE_NAME} restarted successfully on {INSTANCE_ID}.")
    else:
        # 4. Reboot EC2 instance
        send_slack(f"Failed to restart {SERVICE_NAME}. Rebooting {INSTANCE_ID}...")
        ec2.reboot_instances(InstanceIds=[INSTANCE_ID])

    # 5. Save logs to S3
    log_cmd_id = run_command(INSTANCE_ID, f"journalctl -u {SERVICE_NAME} --since '5 minutes ago'")
    stdout, _ = get_command_output(log_cmd_id, INSTANCE_ID)

    log_key = f"logs/{INSTANCE_ID}/{SERVICE_NAME}_{now}.log"
    s3.put_object(Bucket=S3_BUCKET, Key=log_key, Body=stdout.encode("utf-8"))
    print(f" Logs uploaded to s3://{S3_BUCKET}/{log_key}")

    return {
        "status": "handled",
        "log_file": log_key
    }
