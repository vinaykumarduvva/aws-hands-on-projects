# Cleanup Guide — Serverless REST API

## Why Cleanup Matters

All three core services (Lambda, API Gateway, DynamoDB) are within permanent free tier for typical usage. However:
- Leaving resources running is a habit risk — future projects may compound
- DynamoDB items persist until deleted
- Lambda versions accumulate storage if you deploy many updates
- API Gateway stages stay deployed and accessible

Script: `scripts/09-cleanup.ps1`

---

## Cleanup Sequence

No hard dependency order (unlike EC2/VPC projects), but this sequence is clean:

### Step 1 — Delete API Gateway

```powershell
aws apigateway delete-rest-api --rest-api-id $API_ID
Write-Host "API Gateway deleted"
```

This immediately makes all endpoints return 404. The Lambda function and DynamoDB table remain untouched.

### Step 2 — Delete Lambda Function

```powershell
aws lambda delete-function --function-name users-api
Write-Host "Lambda deleted"
```

Deletes the function and all its versions. Does not delete the log group (retained for debugging).

### Step 3 — Delete DynamoDB Table

```powershell
aws dynamodb delete-table --table-name users
Write-Host "DynamoDB table deleted"
```

Deletes all items. Cannot be undone — all user data is gone. If you want to preserve data, export first:
```powershell
aws dynamodb scan --table-name users > users-backup.json
```

### Step 4 — Delete IAM Role

```powershell
# Must remove inline policy and detach managed policy before deleting role

aws iam delete-role-policy `
  --role-name lambda-users-api-role `
  --policy-name dynamodb-users-access

aws iam detach-role-policy `
  --role-name lambda-users-api-role `
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam delete-role --role-name lambda-users-api-role
Write-Host "IAM role deleted"
```

IAM roles cannot be deleted while they have attached policies — both must be removed first.

### Step 5 — Delete CloudWatch Log Group

```powershell
aws logs delete-log-group `
  --log-group-name "/aws/lambda/users-api"
Write-Host "Log group deleted"
```

Optional — logs are retained automatically after Lambda deletion but accrue minimal storage cost.

---

## Verification

```powershell
# Lambda gone
aws lambda get-function --function-name users-api 2>&1
# Expected: ResourceNotFoundException

# API gone
aws apigateway get-rest-api --rest-api-id $API_ID 2>&1
# Expected: NotFoundException

# DynamoDB gone
aws dynamodb describe-table --table-name users 2>&1
# Expected: ResourceNotFoundException

# IAM role gone
aws iam get-role --role-name lambda-users-api-role 2>&1
# Expected: NoSuchEntityException
```

---

## Re-fetch IDs Before Cleanup

If variables were lost:

```powershell
$LAMBDA_ARN = aws lambda get-function `
  --function-name users-api `
  --query "Configuration.FunctionArn" --output text

$API_ID = aws apigateway get-rest-apis `
  --query "items[?name=='users-api'].id | [0]" `
  --output text

Write-Host "Lambda ARN: $LAMBDA_ARN"
Write-Host "API ID:     $API_ID"
```

---

## Cost Check

After cleanup, check **AWS Billing → Cost Explorer** in 24 hours.

Expected charges:
- Lambda: $0.00 (well within 1M free requests)
- API Gateway: $0.00 (within 1M free calls / 12 months)
- DynamoDB: $0.00 (on-demand, minimal requests, within free tier)
- CloudWatch Logs: $0.00 (minimal ingestion)

Total: **$0.00**