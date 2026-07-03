. .\00-pre-flight.ps1

# Break the Lambda
aws lambda update-function-configuration `
  --function-name $LAMBDA_NAME `
  --handler lambda_function.nonexistent_handler

aws lambda wait function-updated --function-name $LAMBDA_NAME

# Trigger it
"id,data`n1,broken" | Out-File -FilePath "dlq-test.csv" -Encoding utf8
aws s3 cp dlq-test.csv s3://$SOURCE_BUCKET/uploads/dlq-test.csv

Write-Host "Waiting for 3 retries to exhaust (90 seconds)..."
Start-Sleep -Seconds 90

$DLQ_URL = aws sqs get-queue-url --queue-name $DLQ_NAME --query "QueueUrl" --output text
aws sqs get-queue-attributes `
  --queue-url $DLQ_URL `
  --attribute-names ApproximateNumberOfMessages `
  --query "Attributes.ApproximateNumberOfMessages" `
  --output text

# Fix Lambda
aws lambda update-function-configuration `
  --function-name $LAMBDA_NAME `
  --handler lambda_function.lambda_handler
aws lambda wait function-updated --function-name $LAMBDA_NAME

aws sqs purge-queue --queue-url $DLQ_URL
Remove-Item dlq-test.csv -Force
