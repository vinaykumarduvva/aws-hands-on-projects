#!/bin/bash
# 09-test-dlq.sh
source ./00-pre-flight.sh

aws lambda update-function-configuration \
  --function-name $LAMBDA_NAME \
  --handler lambda_function.nonexistent_handler

aws lambda wait function-updated --function-name $LAMBDA_NAME

echo -e "id,data\n1,broken" > dlq-test.csv
aws s3 cp dlq-test.csv s3://$SOURCE_BUCKET/uploads/dlq-test.csv

echo "Waiting for 3 retries to exhaust (90 seconds)..."
sleep 90

DLQ_URL=$(aws sqs get-queue-url --queue-name $DLQ_NAME --query "QueueUrl" --output text)
aws sqs get-queue-attributes \
  --queue-url $DLQ_URL \
  --attribute-names ApproximateNumberOfMessages \
  --query "Attributes.ApproximateNumberOfMessages" \
  --output text

aws lambda update-function-configuration \
  --function-name $LAMBDA_NAME \
  --handler lambda_function.lambda_handler
aws lambda wait function-updated --function-name $LAMBDA_NAME

aws sqs purge-queue --queue-url $DLQ_URL
rm dlq-test.csv
