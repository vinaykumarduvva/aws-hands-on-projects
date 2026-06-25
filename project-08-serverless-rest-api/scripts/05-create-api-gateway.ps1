# =============================================================================
# Project 8 — Script 05: Create API Gateway REST API
# Creates resources, methods (Lambda proxy), and deploys to prod stage
# =============================================================================

Write-Host "=== Project 8 — Create API Gateway ===" -ForegroundColor Cyan
Write-Host ""

# Re-fetch IDs
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
$LAMBDA_ARN = aws lambda get-function `
  --function-name users-api `
  --query "Configuration.FunctionArn" --output text

Write-Host "Account ID:  $ACCOUNT_ID"
Write-Host "Lambda ARN:  $LAMBDA_ARN"
Write-Host ""

# ── CREATE REST API ───────────────────────────────────────────────────────────
Write-Host "[1/8] Creating REST API: users-api..." -ForegroundColor Yellow

$API_ID = aws apigateway create-rest-api `
  --name users-api `
  --description "Serverless Users REST API — Project 8" `
  --endpoint-configuration types=REGIONAL `
  --query "id" --output text

Write-Host "API ID: $API_ID" -ForegroundColor Green

# ── GET ROOT RESOURCE ─────────────────────────────────────────────────────────
Write-Host "[2/8] Getting root resource ID..." -ForegroundColor Yellow

$ROOT_ID = aws apigateway get-resources `
  --rest-api-id $API_ID `
  --query "items[?path=='/'].id" `
  --output text

Write-Host "Root ID: $ROOT_ID"

# ── CREATE /users RESOURCE ────────────────────────────────────────────────────
Write-Host "[3/8] Creating /users resource..." -ForegroundColor Yellow

$USERS_ID = aws apigateway create-resource `
  --rest-api-id $API_ID `
  --parent-id $ROOT_ID `
  --path-part users `
  --query "id" --output text

Write-Host "Users Resource ID: $USERS_ID"

# ── CREATE /users/{userId} RESOURCE ──────────────────────────────────────────
Write-Host "[4/8] Creating /users/{userId} resource..." -ForegroundColor Yellow

$USERID_ID = aws apigateway create-resource `
  --rest-api-id $API_ID `
  --parent-id $USERS_ID `
  --path-part "{userId}" `
  --query "id" --output text

Write-Host "UserId Resource ID: $USERID_ID"

# ── HELPER: ADD METHOD + LAMBDA PROXY INTEGRATION ────────────────────────────
$LAMBDA_URI = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations"

function Add-Method {
    param([string]$ResourceId, [string]$HttpMethod)

    aws apigateway put-method `
      --rest-api-id $API_ID `
      --resource-id $ResourceId `
      --http-method $HttpMethod `
      --authorization-type NONE | Out-Null

    aws apigateway put-integration `
      --rest-api-id $API_ID `
      --resource-id $ResourceId `
      --http-method $HttpMethod `
      --type AWS_PROXY `
      --integration-http-method POST `
      --uri $LAMBDA_URI | Out-Null

    Write-Host "  Created: $HttpMethod on resource $ResourceId"
}

# ── ADD METHODS TO /users ─────────────────────────────────────────────────────
Write-Host "[5/8] Adding POST and GET to /users..." -ForegroundColor Yellow
Add-Method -ResourceId $USERS_ID -HttpMethod "POST"
Add-Method -ResourceId $USERS_ID -HttpMethod "GET"

# ── ADD METHODS TO /users/{userId} ───────────────────────────────────────────
Write-Host "[6/8] Adding GET, PUT, DELETE to /users/{userId}..." -ForegroundColor Yellow
Add-Method -ResourceId $USERID_ID -HttpMethod "GET"
Add-Method -ResourceId $USERID_ID -HttpMethod "PUT"
Add-Method -ResourceId $USERID_ID -HttpMethod "DELETE"

# ── GRANT API GATEWAY PERMISSION TO INVOKE LAMBDA ────────────────────────────
Write-Host "[7/8] Granting API Gateway permission to invoke Lambda..." -ForegroundColor Yellow

aws lambda add-permission `
  --function-name users-api `
  --statement-id apigateway-invoke `
  --action lambda:InvokeFunction `
  --principal apigateway.amazonaws.com `
  --source-arn "arn:aws:execute-api:us-east-1:${ACCOUNT_ID}:${API_ID}/*/*" | Out-Null

Write-Host "Lambda permission granted."

# ── DEPLOY TO PROD ────────────────────────────────────────────────────────────
Write-Host "[8/8] Deploying API to prod stage..." -ForegroundColor Yellow

aws apigateway create-deployment `
  --rest-api-id $API_ID `
  --stage-name prod `
  --description "Initial deployment — Project 8" | Out-Null

$API_URL = "https://$API_ID.execute-api.us-east-1.amazonaws.com/prod"
Write-Host "API deployed." -ForegroundColor Green

# ── QUICK SMOKE TEST ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Smoke test: GET /users..." -ForegroundColor Yellow
Start-Sleep -Seconds 3  # Brief pause for deployment propagation

try {
    $test = Invoke-RestMethod -Uri "$API_URL/users" -Method GET
    Write-Host "GET /users returned HTTP 200 — API is live!" -ForegroundColor Green
    Write-Host "User count: $($test.count)"
} catch {
    Write-Host "Smoke test failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Try again in 30 seconds — deployments take a moment to propagate."
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== API Gateway Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  API_ID  = $API_ID"
Write-Host "  API_URL = $API_URL"
Write-Host ""
Write-Host "Endpoints:"
Write-Host "  POST   $API_URL/users"
Write-Host "  GET    $API_URL/users"
Write-Host "  GET    $API_URL/users/{userId}"
Write-Host "  PUT    $API_URL/users/{userId}"
Write-Host "  DELETE $API_URL/users/{userId}"
Write-Host ""
Write-Host "Next step: Set `$API_URL and run 06-test-api.ps1" -ForegroundColor Cyan