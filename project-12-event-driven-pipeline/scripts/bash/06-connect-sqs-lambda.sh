#!/bin/bash
# 06-connect-sqs-lambda.sh
source ./00-pre-flight.sh

QUEUE_URL=$(aws sqs get-queue-url --queue-name $QUEUE_NAME --query "QueueUrl" --output text)
QUEUE_ARN=$(aws sqs get-queue-attributes --queue-url $QUEUE_URL --attribute-names QueueArn --query "Attributes.QueueArn" --output text)

ESM_UUID=$(aws lambda create-event-source-mapping \
  --function-name $LAMBDA_NAME \
  --event-source-arn $QUEUE_ARN \
  --batch-size 1 \
  --maximum-batching-window-in-seconds 0 \
  --query "UUID" --output text)

echo "Event source mapping UUID: $ESM_UUID"

aws lambda get-event-source-mapping \
  --uuid $ESM_UUID \
  --query "{State:State,BatchSize:BatchSize,Queue:EventSourceArn}" \
  --output table
