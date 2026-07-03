#!/bin/bash
# 08-check-logs.sh
source ./00-pre-flight.sh

LOG_STREAM=$(aws logs describe-log-streams \
  --log-group-name "/aws/lambda/$LAMBDA_NAME" \
  --order-by LastEventTime --descending \
  --max-items 1 \
  --query "logStreams[0].logStreamName" \
  --output text)

echo "Log stream: $LOG_STREAM"

if [ "$LOG_STREAM" != "None" ]; then
  aws logs get-log-events \
    --log-group-name "/aws/lambda/$LAMBDA_NAME" \
    --log-stream-name "$LOG_STREAM" \
    --query "events[*].message" \
    --output text
else
  echo "No log stream found yet."
fi
