. .\00-pre-flight.ps1
$LAMBDA_ROLE_ARN = aws iam get-role --role-name $LAMBDA_ROLE --query "Role.Arn" --output text

# Package Lambda
Compress-Archive `
  -Path ..\..\lambda\lambda_function.py `
  -DestinationPath function.zip `
  -Force

# Deploy Lambda
$LAMBDA_ARN = aws lambda create-function `
  --function-name $LAMBDA_NAME `
  --runtime python3.12 `
  --role $LAMBDA_ROLE_ARN `
  --handler lambda_function.lambda_handler `
  --zip-file fileb://function.zip `
  --timeout 60 `
  --memory-size 256 `
  --environment Variables="{OUTPUT_BUCKET=$OUTPUT_BUCKET,REGION=ap-south-1}" `
  --description "Event-driven file processor — Project 12" `
  --tags Project=project-12-event-pipeline `
  --query "FunctionArn" --output text

Write-Host "Lambda ARN: $LAMBDA_ARN"

# Wait for Lambda to be active
aws lambda wait function-active --function-name $LAMBDA_NAME
Write-Host "Lambda is active"

Remove-Item function.zip -Force
