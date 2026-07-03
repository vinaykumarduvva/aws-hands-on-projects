. .\00-pre-flight.ps1

$QUEUE_URL = aws sqs get-queue-url --queue-name $QUEUE_NAME --query "QueueUrl" --output text
$QUEUE_ARN = aws sqs get-queue-attributes --queue-url $QUEUE_URL --attribute-names QueueArn --query "Attributes.QueueArn" --output text

# Create event source mapping (SQS triggers Lambda)
$ESM_UUID = aws lambda create-event-source-mapping `
  --function-name $LAMBDA_NAME `
  --event-source-arn $QUEUE_ARN `
  --batch-size 1 `
  --maximum-batching-window-in-seconds 0 `
  --function-response-types ReportBatchItemFailures `
  --query "UUID" --output text

Write-Host "Event source mapping UUID: $ESM_UUID"

# Verify it is enabled
aws lambda get-event-source-mapping `
  --uuid $ESM_UUID `
  --query "{State:State,BatchSize:BatchSize,Queue:EventSourceArn}" `
  --output table
