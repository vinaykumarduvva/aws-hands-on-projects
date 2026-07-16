# Troubleshooting Guide: Event-Driven Pipeline

Event-driven architectures introduce complexity when tracing failures since interactions are asynchronous. Use this structured guide to resolve common issues encountered during the pipeline lifecycle.

---

## 📋 Quick Reference Table

| Problem | Quick Fix |
|:---|:---|
| Uploaded file doesn't trigger SQS | Check S3 Event Notification prefix (`uploads/`) and suffix (`.csv`). |
| Messages sit in SQS untouched | Check if Lambda Event Source Mapping is **Enabled**. |
| Lambda execution throws AccessDenied | Verify IAM inline policy has `s3:GetObject` on the *Source* bucket. |
| Messages keep ending up in DLQ | Investigate Lambda CloudWatch Logs for application-level crashes (Poison Pill). |
| Unable to redrive DLQ messages | Verify the DLQ Redrive policy is configured on the *Source* SQS queue, not the DLQ. |

---

## Configuration Errors

### ❌ S3 Event Notification Fails to Trigger SQS
**Symptom:** You upload a `.csv` file to the source S3 bucket, but the `file-processing-queue` remains completely empty (Messages Available: 0).

**Cause 1:** Incorrect Prefix/Suffix Configuration. S3 Event Notifications are strict. If you configured the notification to trigger on the `uploads/` prefix, but uploaded the file to the root of the bucket, no event will fire.
**Fix 1:** Verify the file path matches the exact prefix and suffix configured in **S3 Properties > Event Notifications**.

**Cause 2:** SQS Resource Policy Rejection. S3 might be trying to send the event to SQS, but SQS is actively blocking it.
**Fix 2:** Check the **Access Policy** on your SQS queue. Ensure `s3.amazonaws.com` is permitted to `sqs:SendMessage` and the `Condition` block perfectly matches your source bucket ARN.

---

## Execution Errors

### ❌ Lambda Fails to Poll SQS
**Symptom:** You see the "Messages available" count in SQS increase to 1, but it never drops to 0. The output file is not generated, and there are no CloudWatch Logs for the Lambda function.

**Cause:** The Event Source Mapping is disabled or misconfigured. Lambda must be actively polling the queue. If the mapping is deleted, disabled, or lacks permissions, the message will just sit there until the 14-day retention period expires.
**Fix:** Go to the **Lambda Console -> Configuration -> Triggers**. Ensure the SQS trigger is present and its state is **Enabled**. If it says "Error", check that your Lambda IAM role has the `AWSLambdaSQSQueueExecutionRole` policy attached.

### ❌ Messages Redirected to Dead Letter Queue (DLQ)
**Symptom:** Your main queue is empty, but your DLQ is filling up with messages.

**Cause:** A "poison pill" message is causing your Lambda function to crash every time it executes (e.g., malformed CSV data, syntax errors, timeouts). After SQS hits the `maxReceiveCount` (e.g., 3 retries), it routes the message to the DLQ.
**Fix:** This is the system working as intended. Investigate the CloudWatch Logs for the Lambda function. Look for stack traces around the exact time the message was moved to the DLQ. Fix the root bug, then use the **SQS Redrive** feature to push the messages from the DLQ back into the main queue.

---

## Authentication Errors

### ❌ AccessDenied Exception in Lambda
**Symptom:** CloudWatch Logs indicate the function ran, but it crashed on the `s3.get_object()` API call with an `AccessDenied` error.

**Cause 1:** Missing IAM Permissions. The Lambda execution role does not have permission to read from the source S3 bucket.
**Fix 1:** Review the inline IAM policy on `lambda-file-processor-role`. Ensure it explicitly grants `s3:GetObject` to `arn:aws:s3:::event-pipeline-source-ACCOUNT/*`.

**Cause 2:** Incorrect Bucket Extraction. The code is trying to parse the SQS payload but extracted the wrong bucket name string.
**Fix 2:** Log the `event` payload in Lambda to verify the JSON structure. Ensure you are traversing `event['Records'][0]['body']` correctly.

---

## 🔍 Debug Commands

Use these CLI commands to quickly probe your environment and identify bottlenecks:

**Check SQS Queue Depth (Are messages piling up?)**
```bash
aws sqs get-queue-attributes \
    --queue-url https://sqs.ap-south-1.amazonaws.com/[YOUR-ACCOUNT-ID]/file-processing-queue \
    --attribute-names ApproximateNumberOfMessages
```

**Check Lambda Event Source Mapping Status**
```bash
aws lambda list-event-source-mappings \
    --function-name file-processor \
    --query "EventSourceMappings[*].[State, LastProcessingResult]" \
    --output table
```

**Tail Lambda Logs (Stream logs in real-time)**
```bash
aws logs tail /aws/lambda/file-processor --follow
```
