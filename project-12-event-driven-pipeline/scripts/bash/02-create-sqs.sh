#!/bin/bash
# 02-create-sqs.sh
source ./00-pre-flight.sh

export DLQ_URL=$(aws sqs create-queue \
  --queue-name $DLQ_NAME \
  --attributes '{"MessageRetentionPeriod": "1209600", "Tags": {"Project": "project-12"}}' \
  --query "QueueUrl" --output text)

export DLQ_ARN=$(aws sqs get-queue-attributes \
  --queue-url $DLQ_URL \
  --attribute-names QueueArn \
  --query "Attributes.QueueArn" --output text)

echo "DLQ URL: $DLQ_URL"
echo "DLQ ARN: $DLQ_ARN"

export QUEUE_URL=$(aws sqs create-queue \
  --queue-name $QUEUE_NAME \
  --attributes "{
    \"VisibilityTimeout\": \"60\",
    \"MessageRetentionPeriod\": \"345600\",
    \"ReceiveMessageWaitTimeSeconds\": \"20\",
    \"RedrivePolicy\": \"{\\\"deadLetterTargetArn\\\":\\\"$DLQ_ARN\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"
  }" \
  --query "QueueUrl" --output text)

export QUEUE_ARN=$(aws sqs get-queue-attributes \
  --queue-url $QUEUE_URL \
  --attribute-names QueueArn \
  --query "Attributes.QueueArn" --output text)

echo "Queue URL: $QUEUE_URL"
echo "Queue ARN: $QUEUE_ARN"

SQS_POLICY="{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Sid\":\"AllowS3ToSendMessages\",
    \"Effect\":\"Allow\",
    \"Principal\":{\"Service\":\"s3.amazonaws.com\"},
    \"Action\":\"sqs:SendMessage\",
    \"Resource\":\"$QUEUE_ARN\",
    \"Condition\":{
      \"ArnLike\":{
        \"aws:SourceArn\":\"arn:aws:s3:::$SOURCE_BUCKET\"
      }
    }
  }]
}"

aws sqs set-queue-attributes \
  --queue-url $QUEUE_URL \
  --attributes "Policy=$SQS_POLICY"

echo "SQS policy applied"
