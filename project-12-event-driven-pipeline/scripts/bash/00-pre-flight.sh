#!/bin/bash
# 00-pre-flight.sh

export REGION=$(aws configure get region)
export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

echo "Region: $REGION"
echo "Account ID: $ACCOUNT_ID"

export SOURCE_BUCKET="event-pipeline-source-$ACCOUNT_ID"
export OUTPUT_BUCKET="event-pipeline-output-$ACCOUNT_ID"
export QUEUE_NAME="file-processing-queue"
export DLQ_NAME="file-processing-dlq"
export LAMBDA_NAME="file-processor"
export LAMBDA_ROLE="lambda-file-processor-role"

echo "Source bucket:  $SOURCE_BUCKET"
echo "Output bucket:  $OUTPUT_BUCKET"
