# Testing Procedures

This document outlines how to validate the pipeline and verify failure scenarios.

## ✅ Test 1: End-to-End Success Path

1. **Upload a File:**
   Upload a sample `.csv` file into the Source Bucket under the `uploads/` prefix.
   ```bash
   aws s3 cp test.csv s3://<SOURCE_BUCKET>/uploads/test.csv
   ```
2. **Verify Queue Processing:**
   Wait a few seconds. Check CloudWatch Metrics for the Lambda function and ensure `Invocations` spiked to 1 and `Errors` remained at 0.
3. **Check Output:**
   Navigate to the Output Bucket and verify that `processed/YYYY-MM-DD/test-result.json` was created.

## 🚨 Test 2: Dead Letter Queue (DLQ) Fallback

1. **Intentionally Break the Lambda:**
   Update the Lambda function's configuration to point to a non-existent handler (e.g., `lambda_function.broken_handler`).
2. **Upload a File:**
   Upload a file to the Source Bucket.
3. **Observe Retries:**
   The event reaches SQS. Lambda attempts to process it but immediately crashes because the handler is missing. SQS will wait for the Visibility Timeout (e.g., 60s) and retry. This happens 3 times (`maxReceiveCount = 3`).
4. **Check DLQ:**
   After the retries exhaust, check the DLQ.
   ```bash
   aws sqs get-queue-attributes --queue-url <DLQ_URL> --attribute-names ApproximateNumberOfMessages
   ```
   You should see `1` message waiting in the DLQ.
5. **Restore Lambda:**
   Fix the Lambda handler so it works again.
6. **Redrive (Optional):**
   You can manually pull the message from the DLQ or use a DLQ Redrive task to send it back to the main queue for processing now that the bug is fixed.
