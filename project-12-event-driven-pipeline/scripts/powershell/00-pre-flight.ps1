# Confirm region ap-south-1
aws configure get region

# Get account ID
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
Write-Host "Account ID: $ACCOUNT_ID"

# Set bucket names (must be globally unique)
$SOURCE_BUCKET  = "event-pipeline-source-$ACCOUNT_ID"
$OUTPUT_BUCKET  = "event-pipeline-output-$ACCOUNT_ID"
$QUEUE_NAME     = "file-processing-queue"
$DLQ_NAME       = "file-processing-dlq"
$LAMBDA_NAME    = "file-processor"
$LAMBDA_ROLE    = "lambda-file-processor-role"

Write-Host "Source bucket:  $SOURCE_BUCKET"
Write-Host "Output bucket:  $OUTPUT_BUCKET"
