# automation-with-bash-aws
# IAM User Management Automation (Bash + AWS CLI)

#  IAM User Management Automation (Bash + AWS CLI)

This project provides a set of Bash scripts to automate the lifecycle of **temporary IAM users** in AWS, including:

- Creating IAM users from a CSV file
- Assigning policies (inline or managed)
- Generating access credentials
- Sending credentials securely via AWS SES
- Automatically cleaning up expired users

---

##  Project Structure
iam-user-automation/
 ├── users.csv # Input file with usernames and emails
 ├── policy.json # Custom IAM policy document
 ├── create_users.sh # Script to create IAM users and email credentials
 ├── cleanup_users.sh # Script to delete expired IAM users and their credentials
 ├── create_users.log # Logs generated during user creation
 ├── cleanup_users.log # Logs generated during cleanup


---

##  Prerequisites

- AWS CLI configured (`aws configure`)
- IAM permissions to manage users, policies, access keys, and SES
- AWS SES verified domain or email to send emails
- `jq` command-line tool (for parsing JSON)
- Linux/macOS environment (or Git Bash on Windows)


##  users.csv Format

Create a file named `users.csv` in the following format:
---------------------------------
username,email
AliMo,Ali.mo@example.com
janedoe,jane.doe@example.com
---------------------------------

Each row represents a temporary IAM user to be created.

---

##  Setup Instructions

###
1. Clone the Repo

2. Create IAM Users

 create_users.sh
 Reads usernames from users.csv
 Creates IAM users with ReadOnlyAccess or your custom policy.json
 Generates access keys
 Sends credentials to users via AWS SES

3. Cleanup Expired Users
 cleanup_users.sh
 Identifies users tagged with Purpose=temp-user
 Checks for expired tag ExpiryDate
 Deletes access keys, detaches policies, removes users

4. Run this on a schedule using cron:
 0 1 * * * /path/to/cleanup_users.sh >> /var/log/iam_cleanup.log 2>&1

5.  Email Delivery (via AWS SES)
 Ensure you have:
A verified sender email in SES
Production SES access or verified recipients
Update create_users.sh with your sender domain:
--from "admin@yourdomain.com"

Notes
Temporary users are tagged with Purpose=temp-user and ExpiryDate=YYYY-MM-DD.

The cleanup_users.sh script relies on these tags to identify deletable accounts.

Use CloudTrail to audit IAM changes and confirm activity.

