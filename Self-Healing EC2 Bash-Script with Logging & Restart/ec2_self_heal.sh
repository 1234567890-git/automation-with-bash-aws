#!/bin/bash

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
SERVICE="nginx"  # Replace with your service name
LOG_DIR="/var/log/selfheal"
S3_BUCKET="your-s3-bucket-name"
SLACK_WEBHOOK="https://hooks.slack.com/services/your/webhook/url"
JIRA_WEBHOOK="https://your.jira.webhook.url"

mkdir -p $LOG_DIR
TIMESTAMP=$(date +%F-%H%M%S)
LOG_FILE="$LOG_DIR/heal-$TIMESTAMP.log"

check_service() {
  systemctl is-active --quiet $SERVICE
  return $?
}

restart_service() {
  echo "Restarting $SERVICE" >> $LOG_FILE
  systemctl restart $SERVICE
  sleep 10
}

notify_slack() {
  curl -X POST -H 'Content-type: application/json' --data "{
    \"text\": \"[$INSTANCE_ID] - $SERVICE was unresponsive. Action taken: $1\"
  }" $SLACK_WEBHOOK
}

notify_jira() {
  curl -X POST -H 'Content-type: application/json' --data "{
    \"summary\": \"Auto-Heal Triggered on $INSTANCE_ID\",
    \"description\": \"$1\"
  }" $JIRA_WEBHOOK
}

# Step 1: Check service
if ! check_service; then
  echo "$SERVICE is down on $INSTANCE_ID" >> $LOG_FILE

  # Step 2: Collect logs
  journalctl -u $SERVICE > "$LOG_DIR/${SERVICE}_log_$TIMESTAMP.txt"
  aws s3 cp "$LOG_DIR/${SERVICE}_log_$TIMESTAMP.txt" s3://$S3_BUCKET/logs/$INSTANCE_ID/

  # Step 3: Attempt restart
  restart_service

  if ! check_service; then
    echo "Service restart failed. Rebooting EC2..." >> $LOG_FILE
    aws ec2 reboot-instances --instance-ids $INSTANCE_ID
    notify_slack "Service restart failed. EC2 rebooted."
    notify_jira "Service restart failed. EC2 rebooted."
  else
    echo "Service restarted successfully." >> $LOG_FILE
    notify_slack "Service was restarted successfully."
    notify_jira "Service was restarted successfully."
  fi
else
  echo "$SERVICE is running fine." >> $LOG_FILE
fi
