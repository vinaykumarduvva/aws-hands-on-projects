. .\00-pre-flight.ps1

# Create DLQ first
$DLQ_URL = aws sqs create-queue `
  --queue-name $DLQ_NAME `
  --attributes '{"MessageRetentionPeriod": "1209600", "Tags": {"Project": "project-12"}}' `
  --query "QueueUrl" --output text

$DLQ_ARN = aws sqs get-queue-attributes `
  --queue-url $DLQ_URL `
  --attribute-names QueueArn `
  --query "Attributes.QueueArn" --output text

Write-Host "DLQ URL: $DLQ_URL"
Write-Host "DLQ ARN: $DLQ_ARN"

# Create main queue with DLQ configured
$QUEUE_URL = aws sqs create-queue `
  --queue-name $QUEUE_NAME `
  --attributes "{
    `"VisibilityTimeout`": `"60`",
    `"MessageRetentionPeriod`": `"345600`",
    `"ReceiveMessageWaitTimeSeconds`": `"20`",
    `"RedrivePolicy`": `"{ \\`"deadLetterTargetArn\\`":\\`"$DLQ_ARN\\`", \\`"maxReceiveCount\\`":\\`"3\\`" }`"
  }"  `
  --query "QueueUrl" --output text

$QUEUE_ARN = aws sqs get-queue-attributes `
  --queue-url $QUEUE_URL `
  --attribute-names QueueArn `
  --query "Attributes.QueueArn" --output text

Write-Host "Queue URL: $QUEUE_URL"
Write-Host "Queue ARN: $QUEUE_ARN"

# Allow S3 to publish messages to SQS
$SQS_POLICY = "{
  `"Version`":`"2012-10-17`",
  `"Statement`":[{
    `"Sid`":`"AllowS3ToSendMessages`",
    `"Effect`":`"Allow`",
    `"Principal`":{`"Service`":`"s3.amazonaws.com`"},
    `"Action`":`"sqs:SendMessage`",
    `"Resource`":`"$QUEUE_ARN`",
    `"Condition`":{
      `"ArnLike`":{
        `"aws:SourceArn`":`"arn:aws:s3:::$SOURCE_BUCKET`"
      }
    }
  }]
}"

aws sqs set-queue-attributes `
  --queue-url $QUEUE_URL `
  --attributes "Policy=$SQS_POLICY"

Write-Host "SQS policy applied"
