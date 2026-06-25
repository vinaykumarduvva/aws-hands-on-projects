#Requires -Version 5.1
<#
.SYNOPSIS
Tears down all resources created for Project 8 to ensure a clean AWS environment.
#>

# Parameterized for safety, but defaults to the project values
$API_NAME = "users-api"
$LAMBDA_NAME = "users-api"
$TABLE_NAME = "users"
$ROLE_NAME = "lambda-users-api-role"

Write-Host "Starting environment cleanup..." -ForegroundColor Cyan

# 1. Delete API Gateway
Write-Host "Finding and deleting API Gateway..." -ForegroundColor Yellow
$API_ID = aws apigateway get-rest-apis --query "items[?name=='$API_NAME'].id" --output text
if ($API_ID) {
  aws apigateway delete-rest-api --rest-api-id $API_ID
  Write-Host "API Gateway deleted."
}

# 2. Delete Lambda
Write-Host "Deleting Lambda function..." -ForegroundColor Yellow
aws lambda delete-function --function-name $LAMBDA_NAME
Write-Host "Lambda deleted."

# 3. Delete DynamoDB
Write-Host "Deleting DynamoDB table..." -ForegroundColor Yellow
aws dynamodb delete-table --table-name $TABLE_NAME | Out-Null
Write-Host "DynamoDB table deleted."

# 4. Delete IAM Role and Policies
Write-Host "Cleaning up IAM roles and policies..." -ForegroundColor Yellow
aws iam delete-role-policy `
  --role-name $ROLE_NAME `
  --policy-name dynamodb-users-access

aws iam detach-role-policy `
  --role-name $ROLE_NAME `
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam delete-role --role-name $ROLE_NAME
Write-Host "IAM role deleted."

# 5. Delete Log Group
Write-Host "Deleting CloudWatch log group..." -ForegroundColor Yellow
aws logs delete-log-group --log-group-name "/aws/lambda/$LAMBDA_NAME"
Write-Host "Log group deleted."

Write-Host "Cleanup complete." -ForegroundColor Green