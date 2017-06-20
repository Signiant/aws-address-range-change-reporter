# aws-address-range-change-reporter
Notifies in slack whenever the AWS public IP address range changes

# Running
If you are running in AWS using a role, you do not need to specify the access/secret keys

```bash
docker run \
   -e WEBHOOK_ENDPOINT='https://your_slack_inbound_webhook_url' \
   -e WEBHOOK_USER='slack_name_for_the_webhook_user_to_post_as'
   -e SLACK_CHANNEL='#my_slack_channel' \
   -e S3_PREV_RUN_FILE='s3://mybucket/mykey/address_range_check.prev' \
   -e AWS_ACCESS_KEY_ID='YOUR_AK' \
   -e AWS_SECRET_ACCESS_KEY='YOUR SK' \
   signiant/aws-address-range-change-reporter
```

where...
* WEBHOOK_ENDPOINT is as provided by Slack for an inbound webhook
* WEBHOOK_USER is the name you'd like to show for the "user" making the slack post
* SLACK_CHANNEL is the slack channel to report the address range diffs to
* S3_PREV_RUN_FILE is a file in S3 that contains the previous run's values to diff against
