. .\00-pre-flight.ps1

$LOG_STREAM = aws logs describe-log-streams `
  --log-group-name "/aws/lambda/$LAMBDA_NAME" `
  --order-by LastEventTime --descending `
  --max-items 1 `
  --query "logStreams[0].logStreamName" `
  --output text

Write-Host "Log stream: $LOG_STREAM"

if ($LOG_STREAM -ne "None") {
  aws logs get-log-events `
    --log-group-name "/aws/lambda/$LAMBDA_NAME" `
    --log-stream-name $LOG_STREAM `
    --query "events[*].message" `
    --output text
} else {
  Write-Host "No log stream found yet."
}
