# Deployment Guide

The deployment of this pipeline has been fully automated using scripts, but this guide explains the underlying steps taken to provision the infrastructure.

## 🛠️ Prerequisites
- AWS Account with Admin privileges.
- AWS CLI v2 installed and configured (`aws configure`).
- Region: `ap-south-1` (Mumbai) selected.

## 🚀 Step-by-Step Provisioning

### 1. Provision S3 Buckets
We create two globally unique S3 buckets: one for the source and one for the output. We enforce Block Public Access on both to maintain security.

### 2. Provision SQS Queues
We first create the **Dead Letter Queue (DLQ)**, as its ARN is required to configure the **Main Queue**. 
We apply an SQS Resource Policy to the Main Queue to explicitly allow the Source S3 Bucket to `sqs:SendMessage`.

### 3. Wire S3 to SQS
We configure the Source S3 Bucket's Event Notification rules. 
- **Filter Prefix:** `uploads/`
- **Filter Suffix:** `.csv` and `.json`
This ensures only relevant files trigger the queue.

### 4. IAM & Lambda Setup
We create an IAM Execution Role for Lambda granting it:
- `AWSLambdaBasicExecutionRole` (for CloudWatch Logs)
- `AWSLambdaSQSQueueExecutionRole` (to poll SQS)
- Inline Policy to `s3:GetObject` on the Source Bucket and `s3:PutObject` on the Output Bucket.

### 5. Deploy Lambda & Connect
The Python code is zipped and deployed. Finally, an **Event Source Mapping** is created to connect the SQS Queue as the trigger for the Lambda function.

---

> [!TIP]
> **Use the Scripts!** 
> Instead of doing this manually, use the provided scripts in the `scripts/` directory to instantly deploy or tear down this entire architecture.
