Health-check app, restart service or EC2 instance, upload logs to S3, notify Slack, auto-ticket in JIRA.

Cron Job Setup (Optional)
If you want to schedule the script to run at regular intervals, you can set up a cron job
*/5 * * * * /path/to/ec2_self_heal.sh >> /var/log/selfheal/cron.log 2>&1

-------------------------------------------------