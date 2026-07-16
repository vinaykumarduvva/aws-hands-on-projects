# Cleanup Guide: Event-Driven Pipeline

> [!CAUTION]
> Deleting these resources is an irreversible action. Ensure you have backed up any critical data from the output S3 bucket before proceeding. 

## 📋 Resources to Delete

| Resource | Service | Deletion Order Rationale |
|:---|:---|:---|
| Event Source Mapping | Lambda | Must be deleted first to stop polling and unbind Lambda from SQS. |
| `file-processor` | Lambda | Delete compute before queues to prevent orphan executions. |
| `file-processing-queue` | SQS | Delete main queue. |
| `file-processing-dlq` | SQS | Delete DLQ. |
| `event-pipeline-source-*` | S3 | Buckets must be manually emptied (all objects deleted) before bucket deletion. |
| `event-pipeline-output-*` | S3 | Same as above. |
| `lambda-file-processor-role` | IAM | Delete last. Ensures no race conditions during resource detachment. |
| `/aws/lambda/file-processor` | CloudWatch | Clean up execution logs to prevent storage accumulation. |

## 🧹 TEARDOWN ALL RESOURCES AUTOMATICALLY

### 🖥️ Method 1: AWS Management Console

1. **Delete Event Source Mapping & Lambda Function**
   - Navigate to the Lambda Console.
   - Select `file-processor`.
   - Go to **Configuration > Triggers**, select SQS, and click **Delete**.
   - Go back to the main Lambda list, select `file-processor`, click **Actions** > **Delete**, and confirm.
2. **Delete SQS Queues**
   - Navigate to the SQS Console.
   - Select `file-processing-queue`, click **Delete**, type `delete`, and confirm.
   - Repeat for `file-processing-dlq`.
3. **Empty and Delete S3 Buckets**
   - Navigate to the S3 Console.
   - Select the source bucket, click **Empty**, type `permanently delete`, and confirm.
   - Click **Delete**, type the bucket name, and confirm.
   - Repeat for the output bucket.
4. **Delete IAM Role**
   - Navigate to the IAM Console > Roles.
   - Search for `lambda-file-processor-role`.
   - Select it, click **Delete**, and confirm.
5. **Delete CloudWatch Logs**
   - Navigate to CloudWatch > Log groups.
   - Select `/aws/lambda/file-processor`, click **Actions** > **Delete log group**, and confirm.

### 🐧 Method 2: AWS CLI (Bash)

```bash
#!/bin/bash
# 10-cleanup.sh
source ./00-pre-flight.sh

ESM_UUID=$(aws lambda list-event-source-mappings --function-name $LAMBDA_NAME --query "EventSourceMappings[0].UUID" --output text)
if [ "$ESM_UUID" != "None" ]; then
  aws lambda delete-event-source-mapping --uuid $ESM_UUID
  echo "Event source mapping deleted"
fi

aws lambda delete-function --function-name $LAMBDA_NAME
echo "Lambda deleted"

QUEUE_URL=$(aws sqs get-queue-url --queue-name $QUEUE_NAME --query "QueueUrl" --output text 2>/dev/null)
DLQ_URL=$(aws sqs get-queue-url --queue-name $DLQ_NAME --query "QueueUrl" --output text 2>/dev/null)
[ -n "$QUEUE_URL" ] && aws sqs delete-queue --queue-url $QUEUE_URL
[ -n "$DLQ_URL" ] && aws sqs delete-queue --queue-url $DLQ_URL
echo "SQS queues deleted"

for BUCKET in $SOURCE_BUCKET $OUTPUT_BUCKET; do
  aws s3 rm s3://$BUCKET --recursive
  aws s3api delete-bucket --bucket $BUCKET --region ap-south-1
  echo "Bucket deleted: $BUCKET"
done

aws iam detach-role-policy --role-name $LAMBDA_ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam detach-role-policy --role-name $LAMBDA_ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole
aws iam delete-role-policy --role-name $LAMBDA_ROLE --policy-name s3-pipeline-access
aws iam delete-role --role-name $LAMBDA_ROLE
echo "IAM role deleted"

aws logs delete-log-group --log-group-name "/aws/lambda/$LAMBDA_NAME" 2>/dev/null
echo "Log group deleted"
```

### 🪟 Method 3: AWS CLI (PowerShell)

```powershell
. .\00-pre-flight.ps1

# 1. Delete event source mapping
$ESM_UUID = aws lambda list-event-source-mappings --function-name $LAMBDA_NAME --query "EventSourceMappings[0].UUID" --output text
if ($ESM_UUID -ne "None") {
  aws lambda delete-event-source-mapping --uuid $ESM_UUID
  Write-Host "Event source mapping deleted"
}

# 2. Delete Lambda
aws lambda delete-function --function-name $LAMBDA_NAME
Write-Host "Lambda deleted"

# 3. Delete SQS queues
$QUEUE_URL = aws sqs get-queue-url --queue-name $QUEUE_NAME --query "QueueUrl" --output text
$DLQ_URL = aws sqs get-queue-url --queue-name $DLQ_NAME --query "QueueUrl" --output text
if ($QUEUE_URL -ne "None") { aws sqs delete-queue --queue-url $QUEUE_URL }
if ($DLQ_URL -ne "None") { aws sqs delete-queue --queue-url $DLQ_URL }
Write-Host "SQS queues deleted"

# 4. Empty and delete S3 buckets
foreach ($BUCKET in @($SOURCE_BUCKET, $OUTPUT_BUCKET)) {
  aws s3 rm s3://$BUCKET --recursive
  aws s3api delete-bucket --bucket $BUCKET --region ap-south-1
  Write-Host "Bucket deleted: $BUCKET"
}

# 5. Delete IAM role
aws iam detach-role-policy --role-name $LAMBDA_ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam detach-role-policy --role-name $LAMBDA_ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole
aws iam delete-role-policy --role-name $LAMBDA_ROLE --policy-name s3-pipeline-access
aws iam delete-role --role-name $LAMBDA_ROLE
Write-Host "IAM role deleted"

# 6. Delete CloudWatch log group
aws logs delete-log-group --log-group-name "/aws/lambda/$LAMBDA_NAME"
Write-Host "Log group deleted"
```

## ✅ Cleanup Verification

Run the following commands to guarantee all resources have been permanently removed:

```bash
aws lambda list-functions --query "Functions[?FunctionName=='file-processor'].FunctionName"
aws sqs list-queues --queue-name-prefix file-processing
aws s3api head-bucket --bucket event-pipeline-source-[ACCOUNT_ID] 2>&1
aws iam get-role --role-name lambda-file-processor-role 2>&1
```
*(All commands should return empty arrays or `NoSuchBucket`/`NoSuchEntity` errors)*

## 💰 Cost Implications

By completing this cleanup, you will immediately stop accruing charges for:
- S3 storage per GB/month for objects residing in the source and output buckets.
- SQS request charges (polling, sending, receiving messages).
- CloudWatch Logs storage per GB/month for Lambda execution logs.
- Lambda invocations and compute duration (which are billed per millisecond when active).
