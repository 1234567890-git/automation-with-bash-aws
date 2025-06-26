#!/bin/bash

TODAY=$(date +%F)
LOG_FILE="cleanup_users.log"

# List users tagged as temporary
TEMP_USERS=$(aws iam list-users --query "Users[?contains(Tags[?Key=='Purpose'].Value | [0], 'temp-user')].UserName" --output text)

for user in $TEMP_USERS; do
  EXPIRY_DATE=$(aws iam list-user-tags --user-name "$user" \
    --query "Tags[?Key=='ExpiryDate'].Value | [0]" --output text)

  if [[ "$EXPIRY_DATE" < "$TODAY" ]]; then
    echo "Cleaning up expired user: $user"

    # Deactivate and delete keys
    KEY_IDS=$(aws iam list-access-keys --user-name "$user" --query "AccessKeyMetadata[*].AccessKeyId" --output text)
    for key in $KEY_IDS; do
      aws iam delete-access-key --user-name "$user" --access-key-id "$key" >> $LOG_FILE 2>&1
    done

    # Detach policies
    POLICIES=$(aws iam list-attached-user-policies --user-name "$user" --query "AttachedPolicies[*].PolicyArn" --output text)
    for policy in $POLICIES; do
      aws iam detach-user-policy --user-name "$user" --policy-arn "$policy" >> $LOG_FILE 2>&1
    done

    # Delete user
    aws iam delete-user --user-name "$user" >> $LOG_FILE 2>&1
    echo "$user deleted"
  fi
done
