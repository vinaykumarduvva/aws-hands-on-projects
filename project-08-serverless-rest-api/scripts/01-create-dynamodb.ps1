# =============================================================================
# Project 8 — Script 01: Create DynamoDB Table
# Creates the 'users' table with on-demand billing and userId partition key
# =============================================================================

Write-Host "=== Project 8 — Create DynamoDB Table ===" -ForegroundColor Cyan
Write-Host ""

aws sts get-caller-identity | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: AWS CLI not configured." -ForegroundColor Red; exit 1 }

Write-Host "Creating DynamoDB table: users" -ForegroundColor Yellow
Write-Host "  Partition key: userId (String)"
Write-Host "  Billing mode:  PAY_PER_REQUEST (on-demand)"
Write-Host ""

aws dynamodb create-table `
  --table-name users `
  --attribute-definitions AttributeName=userId,AttributeType=S `
  --key-schema AttributeName=userId,KeyType=HASH `
  --billing-mode PAY_PER_REQUEST `
  --tags Key=Project,Value=project-08-serverless | Out-Null

Write-Host "Table creation initiated. Waiting for ACTIVE status..." -ForegroundColor Yellow
aws dynamodb wait table-exists --table-name users
Write-Host "Table is ACTIVE." -ForegroundColor Green

# Verify
aws dynamodb describe-table `
  --table-name users `
  --query "Table.{Name:TableName,Status:TableStatus,Billing:BillingModeSummary.BillingMode,PK:KeySchema[0].AttributeName}" `
  --output table

Write-Host ""
Write-Host "=== DynamoDB Complete ===" -ForegroundColor Cyan
Write-Host "Next step: Run 02-create-lambda-role.ps1" -ForegroundColor Cyan