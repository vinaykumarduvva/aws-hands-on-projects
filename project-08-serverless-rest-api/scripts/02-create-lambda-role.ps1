# =============================================================================
# Project 8 — Script 02: Create Lambda IAM Role
# Creates execution role with CloudWatch Logs + scoped DynamoDB access
# =============================================================================

Write-Host "=== Project 8 — Create Lambda IAM Role ===" -ForegroundColor Cyan
Write-Host ""

$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
Write-Host "Account ID: $ACCOUNT_ID"
Write-Host ""

# ── CREATE ROLE ───────────────────────────────────────────────────────────────
Write-Host "[1/4] Creating role: lambda-users-api-role..." -ForegroundColor Yellow

aws iam create-role `
  --role-name lambda-users-api-role `
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' | Out-Null

Write-Host "Role created." -ForegroundColor Green

# ── ATTACH BASIC EXECUTION POLICY ────────────────────────────────────────────
Write-Host "[2/4] Attaching AWSLambdaBasicExecutionRole (CloudWatch Logs)..." -ForegroundColor Yellow

aws iam attach-role-policy `
  --role-name lambda-users-api-role `
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

Write-Host "Managed policy attached." -ForegroundColor Green

# ── ADD DYNAMODB INLINE POLICY ────────────────────────────────────────────────
Write-Host "[3/4] Adding DynamoDB inline policy (least privilege)..." -ForegroundColor Yellow

$DYNAMODB_POLICY = "{
  `"Version`": `"2012-10-17`",
  `"Statement`": [{
    `"Effect`": `"Allow`",
    `"Action`": [
      `"dynamodb:GetItem`",
      `"dynamodb:PutItem`",
      `"dynamodb:UpdateItem`",
      `"dynamodb:DeleteItem`",
      `"dynamodb:Scan`",
      `"dynamodb:Query`"
    ],
    `"Resource`": `"arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/users`"
  }]
}"

aws iam put-role-policy `
  --role-name lambda-users-api-role `
  --policy-name dynamodb-users-access `
  --policy-document $DYNAMODB_POLICY

Write-Host "DynamoDB policy attached (scoped to table/users ARN)." -ForegroundColor Green

# ── GET ROLE ARN ──────────────────────────────────────────────────────────────
Write-Host "[4/4] Fetching role ARN..." -ForegroundColor Yellow

$LAMBDA_ROLE_ARN = aws iam get-role `
  --role-name lambda-users-api-role `
  --query "Role.Arn" --output text

Write-Host "Role ARN: $LAMBDA_ROLE_ARN" -ForegroundColor Green

# IAM propagation delay
Write-Host ""
Write-Host "Waiting 10 seconds for IAM changes to propagate globally..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
Write-Host "Ready." -ForegroundColor Green

Write-Host ""
Write-Host "=== IAM Role Complete ===" -ForegroundColor Cyan
Write-Host "  LAMBDA_ROLE_ARN = $LAMBDA_ROLE_ARN"
Write-Host ""
Write-Host "Next step: Run 03-package-lambda.ps1" -ForegroundColor Cyan