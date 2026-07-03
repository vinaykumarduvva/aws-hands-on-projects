#!/bin/bash
# 05-deploy-lambda.sh
source ./00-pre-flight.sh

LAMBDA_ROLE_ARN=$(aws iam get-role --role-name $LAMBDA_ROLE --query "Role.Arn" --output text)

cd ../../lambda || exit
zip -r function.zip lambda_function.py
cd - || exit

LAMBDA_ARN=$(aws lambda create-function \
  --function-name $LAMBDA_NAME \
  --runtime python3.12 \
  --role $LAMBDA_ROLE_ARN \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://../../lambda/function.zip \
  --timeout 60 \
  --memory-size 256 \
  --environment Variables="{OUTPUT_BUCKET=$OUTPUT_BUCKET,REGION=ap-south-1}" \
  --description "Event-driven file processor — Project 12" \
  --tags Project=project-12-event-pipeline \
  --query "FunctionArn" --output text)

echo "Lambda ARN: $LAMBDA_ARN"
aws lambda wait function-active --function-name $LAMBDA_NAME
echo "Lambda is active"

rm ../../lambda/function.zip
