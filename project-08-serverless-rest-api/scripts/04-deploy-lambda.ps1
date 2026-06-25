# =============================================================================
# Project 8 — Script 04: Deploy Lambda Function
# Creates the users-api Lambda function and tests it directly
# =============================================================================

Write-Host "=== Project 8 — Deploy Lambda Function ===" -ForegroundColor Cyan
Write-Host ""

if (-not $LAMBDA_ROLE_ARN) {
    $LAMBDA_ROLE_ARN = aws iam get-role `
      --role-name lambda-users-api-role `
      --query "Role.Arn" --output text
    Write-Host "Fetched role ARN: $LAMBDA_ROLE_ARN"
}

if (-not (Test-Path "lambda\function.zip")) {
    Write-Host "ERROR: lambda\function.zip not found. Run 03-package-lambda.ps1 first." -ForegroundColor Red
    exit 1
}

# ── DEPLOY ────────────────────────────────────────────────────────────────────
Write-Host "Deploying Lambda function: users-api..." -ForegroundColor Yellow
Write-Host "  Runtime:  python3.12"
Write-Host "  Memory:   128 MB"
Write-Host "  Timeout:  30 seconds"
Write-Host "  Handler:  lambda_function.lambda_handler"
Write-Host ""

$LAMBDA_ARN = aws lambda create-function `
  --function-name users-api `
  --runtime python3.12 `
  --role $LAMBDA_ROLE_ARN `
  --handler lambda_function.lambda_handler `
  --zip-file fileb://lambda/function.zip `
  --timeout 30 `
  --memory-size 128 `
  --description "Serverless Users CRUD API — Project 8" `
  --environment Variables="{TABLE_NAME=users,REGION=us-east-1}" `
  --tags Project=project-08-serverless `
  --query "FunctionArn" --output text

Write-Host "Lambda ARN: $LAMBDA_ARN" -ForegroundColor Green
Write-Host "Waiting for function to become active..." -ForegroundColor Yellow

aws lambda wait function-active --function-name users-api
Write-Host "Function is active." -ForegroundColor Green

# ── VERIFY CONFIGURATION ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "Function configuration:" -ForegroundColor Yellow
aws lambda get-function-configuration `
  --function-name users-api `
  --query "Configuration.{Name:FunctionName,Runtime:Runtime,State:State,Memory:MemorySize,Timeout:Timeout,Handler:Handler}" `
  --output table

# ── DIRECT TEST ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Running direct Lambda test (GET /users)..." -ForegroundColor Yellow

aws lambda invoke `
  --function-name users-api `
  --payload '{"httpMethod":"GET","path":"/users","pathParameters":null}' `
  --cli-binary-format raw-in-base64-out `
  response.json | Out-Null

$result = Get-Content response.json | ConvertFrom-Json
Write-Host "Status code: $($result.statusCode)"
if ($result.statusCode -eq 200) {
    Write-Host "Lambda test PASSED." -ForegroundColor Green
} else {
    Write-Host "Lambda test returned unexpected status. Check CloudWatch Logs." -ForegroundColor Yellow
    Write-Host "Logs: aws logs tail /aws/lambda/users-api --follow"
}

Write-Host ""
Write-Host "=== Lambda Deployment Complete ===" -ForegroundColor Cyan
Write-Host "  LAMBDA_ARN = $LAMBDA_ARN"
Write-Host ""
Write-Host "Next step: Run 05-create-api-gateway.ps1" -ForegroundColor Cyan