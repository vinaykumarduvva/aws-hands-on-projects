# Security Protocols: Event-Driven Pipeline

This document outlines the security controls, IAM configurations, and encryption standards applied to the event-driven data pipeline to ensure data integrity and compliance.

---

## 🔐 IAM & Access Control

The architecture adheres strictly to the Principle of Least Privilege (PoLP). 

### Lambda Execution Role (`lambda-file-processor-role`)
This service role dictates exactly what the Lambda function is permitted to do during execution.
- **`AWSLambdaBasicExecutionRole` (Managed):** Allows the function to create Log Groups and write log streams to CloudWatch.
- **`AWSLambdaSQSQueueExecutionRole` (Managed):** Grants permissions for `sqs:ReceiveMessage`, `sqs:DeleteMessage`, and `sqs:GetQueueAttributes`. Crucial for the Event Source Mapping to function.
- **`s3-pipeline-access` (Inline Policy):** 
  - Restricts `s3:GetObject` strictly to `arn:aws:s3:::event-pipeline-source-ACCOUNT/*`.
  - Restricts `s3:PutObject` strictly to `arn:aws:s3:::event-pipeline-output-ACCOUNT/*`.

### SQS Resource-Based Policy
The SQS queue (`file-processing-queue`) cannot inherently receive messages from S3. A resource-based policy is attached to the queue granting `s3.amazonaws.com` permission to publish messages.
- **Confused Deputy Prevention:** The policy includes a `Condition` block specifying `StringEquals: { "aws:SourceArn": "arn:aws:s3:::event-pipeline-source-ACCOUNT" }`. This completely mitigates the "confused deputy" problem, ensuring only *our* specific S3 bucket can publish messages to the queue.

---

## 🛡️ Network Security

Because this pipeline leverages native AWS managed services (S3, SQS, Lambda) and does not utilize EC2 or RDS, customer-managed VPCs, subnets, and Security Groups are not deployed. All interactions happen over the secure AWS global network backbone.

### S3 Block Public Access (BPA)
Both the Source and Output buckets have **Block Public Access** fully enabled at the bucket level:
- `BlockPublicAcls = true`
- `IgnorePublicAcls = true`
- `BlockPublicPolicy = true`
- `RestrictPublicBuckets = true`

This guarantees that no objects can be inadvertently exposed to the public internet, completely isolating the data from unauthorized external access.

---

## 🔒 Encryption

### Encryption at Rest
- **Amazon S3 (SSE-S3):** By default, all newly created S3 buckets automatically apply Server-Side Encryption with Amazon S3 managed keys. All files uploaded to the source bucket and all results written to the output bucket are encrypted at rest using AES-256.
- **Amazon SQS (SSE-SQS):** Standard SQS queues are encrypted at rest by default using Amazon SQS-managed encryption keys. This protects the metadata payload while the message sits in the queue waiting for Lambda execution.

### Encryption in Transit
- All communications between the external Developer/Application and S3 occur over **HTTPS/TLS**.
- All internal API calls made by AWS services (e.g., S3 to SQS, Lambda polling SQS, Lambda pulling from S3) occur over the encrypted AWS backend network via TLS.

---

## 📋 Compliance & Best Practices

- **Least Privilege:** S3 read/write operations are siloed. Lambda cannot overwrite source files or delete output files, adhering to strict least privilege boundaries.
- **Audit Logging (CloudTrail):** All management events (e.g., modifying IAM roles, changing SQS policies) are automatically logged by AWS CloudTrail for 90 days.
- **Execution Auditing (CloudWatch):** Lambda execution logs provide a detailed audit trail of which files were processed and at what time, explicitly logging the `eventTime`, `size_bytes`, and the generated `output_key`.
- **IMDSv2:** While this architecture is serverless and does not use EC2 instances directly, the underlying Lambda execution environments are hardened by AWS and manage metadata retrieval securely.
