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
  aws s3 rm s3://$BUCKET --recursive
  aws s3api delete-bucket --bucket $BUCKET --region ap-south-1
  echo "Bucket deleted: $BUCKET"
done

aws iam detach-role-policy --role-name $LAMBDA_ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam detach-role-policy --role-name $LAMBDA_ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole
aws iam delete-role-policy --role-name $LAMBDA_ROLE --policy-name s3-pipeline-access
aws iam delete-role --role-name $LAMBDA_ROLE
echo "IAM role deleted"

aws logs delete-log-group --log-group-name "/aws/lambda/$LAMBDA_NAME" 2>/dev/null
echo "Log group deleted"
