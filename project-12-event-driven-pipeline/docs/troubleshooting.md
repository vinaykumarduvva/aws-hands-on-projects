# Troubleshooting Guide

| Problem | Cause | Fix |
|---|---|---|
| **S3 upload doesn't trigger SQS** | Wrong prefix/suffix filter | Verify file path starts with `uploads/` and ends in `.csv` or `.json`. S3 notifications are exact matches. |
| **Lambda not triggered by SQS** | Event source mapping disabled | Check `aws lambda get-event-source-mapping` and ensure State = `Enabled` |
| **`AccessDenied` on S3 get** | Lambda role missing S3 read | Verify the `s3-pipeline-access` inline policy is attached to the Lambda IAM execution role. |
| **SQS policy error on creation** | S3 bucket ARN wrong in condition | Check the Resource Policy's `Condition` block. It must use the Source Bucket's ARN, not just the bucket name. |
| **Messages going straight to DLQ** | Lambda failing on first attempt | Check CloudWatch logs. The Lambda is immediately throwing an unhandled exception before it can complete. |
| **Output bucket files not appearing** | Wrong `OUTPUT_BUCKET` env var | Verify Lambda environment variable matches the exact bucket name, with no trailing slashes. |
| **`s3:TestEvent` in logs** | S3 sends test on first notification | Normal behavior. Our Python code has logic to explicitly catch and skip this event: `if 'Event' in body and body['Event'] == 's3:TestEvent':` |
