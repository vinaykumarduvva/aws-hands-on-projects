# Security Protocols & IAM Permissions

Security is paramount. This project strictly adheres to the **Principle of Least Privilege (PoLP)**.

## 🔒 Resource Policies

### 1. SQS Queue Policy
By default, SQS queues reject all incoming messages unless authenticated. Since S3 is an AWS Service sending the message, we must grant it permission via a Resource Policy attached to the Queue.

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "s3.amazonaws.com"},
    "Action": "sqs:SendMessage",
    "Resource": "<QUEUE_ARN>",
    "Condition": {
      "ArnLike": {
        "aws:SourceArn": "arn:aws:s3:::<SOURCE_BUCKET_NAME>"
      }
    }
  }]
}
```
*Notice the `Condition` block:* This prevents the "Confused Deputy" problem by ensuring only *our specific bucket* can send messages to the queue.

### 2. S3 Block Public Access
Both the Source and Output buckets are locked down entirely from public access using the `BlockPublicAccess` configuration (blocking all ACLs and public policies).

## 🛡️ Lambda IAM Role (Execution Role)

The Lambda function requires permissions to interact with other services. 

1. **AWSLambdaBasicExecutionRole:** Allows Lambda to write `stdout` logs to CloudWatch Logs.
2. **AWSLambdaSQSQueueExecutionRole:** Allows Lambda to `sqs:ReceiveMessage`, `sqs:DeleteMessage`, and `sqs:GetQueueAttributes` on our queue.
3. **Custom S3 Inline Policy:** 
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::<SOURCE_BUCKET>/*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject"],
      "Resource": "arn:aws:s3:::<OUTPUT_BUCKET>/*"
    }
  ]
}
```
*Note:* Lambda can only Read from the source bucket and Write to the output bucket. It cannot delete files or read from the output bucket.
