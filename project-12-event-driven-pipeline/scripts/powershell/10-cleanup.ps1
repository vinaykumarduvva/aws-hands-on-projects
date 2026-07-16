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
  Write-Host "Emptying bucket: $BUCKET"
  
  # Delete all object versions
  $versions = aws s3api list-object-versions --bucket $BUCKET --query "Versions[].[Key, VersionId]" --output text
  if ($versions -and $versions -notmatch "None") {
    $versions -split "`r?`n" | Where-Object { $_ -match "\S" } | ForEach-Object {
      $parts = $_ -split "`t"
      if ($parts.Count -eq 2) {
        aws s3api delete-object --bucket $BUCKET --key $parts[0] --version-id $parts[1] | Out-Null
      }
    }
  }

  # Delete all delete markers
  $markers = aws s3api list-object-versions --bucket $BUCKET --query "DeleteMarkers[].[Key, VersionId]" --output text
  if ($markers -and $markers -notmatch "None") {
    $markers -split "`r?`n" | Where-Object { $_ -match "\S" } | ForEach-Object {
      $parts = $_ -split "`t"
      if ($parts.Count -eq 2) {
        aws s3api delete-object --bucket $BUCKET --key $parts[0] --version-id $parts[1] | Out-Null
      }
    }
  }

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
