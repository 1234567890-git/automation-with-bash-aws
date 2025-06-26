#!/bin/bash

CSV_FILE="users.csv"
POLICY_ARN="arn:aws:iam::aws:policy/ReadOnlyAccess"
LOG_FILE="create_users.log"
EXPIRATION_TAG="temp-user"

while IFS=, read -r username email; do
  echo "Processing user: $username"

  # 1. Create IAM user
  aws iam create-user --user-name "$username" --tags Key=Purpose,Value=$EXPIRATION_TAG Key=ExpiryDate,Value=$(date -d "+7 days" +%F) >> $LOG_FILE 2>&1

  # 2. Attach policy
  aws iam attach-user-policy --user-name "$username" --policy-arn "$POLICY_ARN" >> $LOG_FILE 2>&1

  # 3. Create access keys
  CREDENTIALS=$(aws iam create-access-key --user-name "$username" --output json)
  ACCESS_KEY_ID=$(echo "$CREDENTIALS" | jq -r '.AccessKey.AccessKeyId')
  SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.AccessKey.SecretAccessKey')

  # 4. Send credentials via email (requires AWS SES setup)
  BODY="Hello $username,\n\nYour temporary AWS credentials:\n\nAccess Key: $ACCESS_KEY_ID\nSecret Key: $SECRET_ACCESS_KEY\n\nPlease expire on: $(date -d '+7 days' +%F)"
  aws ses send-email \
    --from "admin@yourdomain.com" \
    --destination "ToAddresses=$email" \
    --message "Subject={Data=Temporary AWS Access},Body={Text={Data=$BODY}}" >> $LOG_FILE 2>&1

  echo "$username provisioned and notified."

done < "$CSV_FILE"
