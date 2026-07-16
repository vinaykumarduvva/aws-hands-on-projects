#!/bin/bash
# 10-cleanup.sh
source ./00-pre-flight.sh

ESM_UUID=$(aws lambda list-event-source-mappings --function-name $LAMBDA_NAME --query "EventSourceMappings[0].UUID" --output text)
if [ "$ESM_UUID" != "None" ]; then
  aws lambda delete-event-source-mapping --uuid $ESM_UUID
  echo "Event source mapping deleted"
fi

aws lambda delete-function --function-name $LAMBDA_NAME
echo "Lambda deleted"

QUEUE_URL=$(aws sqs get-queue-url --queue-name $QUEUE_NAME --query "QueueUrl" --output text 2>/dev/null)
DLQ_URL=$(aws sqs get-queue-url --queue-name $DLQ_NAME --query "QueueUrl" --output text 2>/dev/null)
[ -n "$QUEUE_URL" ] && aws sqs delete-queue --queue-url $QUEUE_URL
[ -n "$DLQ_URL" ] && aws sqs delete-queue --queue-url $DLQ_URL
echo "SQS queues deleted"

for BUCKET in $SOURCE_BUCKET $OUTPUT_BUCKET; do
  echo "Emptying bucket: $BUCKET"
  
  # Delete all object versions
  VERSIONS=$(aws s3api list-object-versions --bucket "$BUCKET" --query="Versions[].[Key, VersionId]" --output text)
  if [ -n "$VERSIONS" ] && [ "$VERSIONS" != "None" ]; then
    while read -r KEY VERSION_ID; do
      [ -n "$KEY" ] && aws s3api delete-object --bucket "$BUCKET" --key "$KEY" --version-id "$VERSION_ID" >/dev/null
    done <<< "$VERSIONS"
  fi

  # Delete all delete markers
  MARKERS=$(aws s3api list-object-versions --bucket "$BUCKET" --query="DeleteMarkers[].[Key, VersionId]" --output text)
  if [ -n "$MARKERS" ] && [ "$MARKERS" != "None" ]; then
    while read -r KEY VERSION_ID; do
      [ -n "$KEY" ] && aws s3api delete-object --bucket "$BUCKET" --key "$KEY" --version-id "$VERSION_ID" >/dev/null
    done <<< "$MARKERS"
  fi

  aws s3api delete-bucket --bucket "$BUCKET" --region ap-south-1
  echo "Bucket deleted: $BUCKET"
done

aws iam detach-role-policy --role-name $LAMBDA_ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam detach-role-policy --role-name $LAMBDA_ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole
aws iam delete-role-policy --role-name $LAMBDA_ROLE --policy-name s3-pipeline-access
aws iam delete-role --role-name $LAMBDA_ROLE
echo "IAM role deleted"

aws logs delete-log-group --log-group-name "/aws/lambda/$LAMBDA_NAME" 2>/dev/null
echo "Log group deleted"
