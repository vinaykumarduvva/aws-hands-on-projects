# Troubleshooting — Serverless REST API

---

## Lambda AccessDenied on DynamoDB

**Symptom**: Lambda returns `{"error": "An error occurred (AccessDeniedException) when calling the PutItem operation"}`

**Cause 1 — IAM role not propagated**
IAM changes take 10–15 seconds to propagate globally. If Lambda was created immediately after the role:
```powershell
Start-Sleep -Seconds 15
aws lambda update-function-configuration `
  --function-name users-api `
  --role $LAMBDA_ROLE_ARN
```

**Cause 2 — Wrong account ID in policy Resource ARN**
Verify the DynamoDB policy resource uses your actual account ID:
```powershell
aws iam get-role-policy `
  --role-name lambda-users-api-role `
  --policy-name dynamodb-users-access `
  --query "PolicyDocument.Statement[0].Resource"
```
Should return: `arn:aws:dynamodb:us-east-1:YOUR_ACCOUNT_ID:table/users`

**Cause 3 — Wrong table name**
The policy ARN references `table/users`. If you created the table with a different name, the ARN won't match.

---

## API Gateway Returns 502 Bad Gateway

**Symptom**: HTTP 502 from API Gateway with `{"message": "Internal server error"}`

**Cause**: Lambda returned a response that API Gateway could not parse. With proxy integration, the Lambda response must include `statusCode` (integer), `headers` (dict), and `body` (string).

**Debug steps**:
1. Check CloudWatch Logs: `aws logs tail /aws/lambda/users-api --follow`
2. Look for Python exceptions in the log output
3. Common causes:
   - Python syntax error → Lambda returns no response
   - `body` not JSON-serialized → API Gateway rejects it
   - Unhandled `Decimal` → `json.dumps` TypeError

**Quick check — invoke Lambda directly**:
```powershell
aws lambda invoke `
  --function-name users-api `
  --payload '{"httpMethod":"GET","path":"/users"}' `
  --cli-binary-format raw-in-base64-out `
  out.json
cat out.json
```
If this returns a valid response but API Gateway returns 502, the integration is misconfigured.

---

## `{"message": "Internal server error"}` (API Gateway generic error)

**Symptom**: Specific error message from API Gateway, not from Lambda.

**Cause**: The Lambda function threw an exception that was NOT caught by the try/except block, or the function timed out, or the response format is wrong.

**Fix**:
1. Check Lambda execution logs immediately after the failed request
2. Verify the handler name: `lambda_function.lambda_handler`
   ```powershell
   aws lambda get-function-configuration `
     --function-name users-api `
     --query "Handler"
   ```
   Must return exactly: `lambda_function.lambda_handler`

---

## API Returns 404 for Valid Routes

**Symptom**: `POST /users` returns `{"error": "Route not found: POST /users"}`

**Cause**: Lambda proxy integration is NOT enabled on the method.

With standard (non-proxy) integration, API Gateway does not pass `httpMethod` or `path` in the event. The routing code gets empty strings and falls through to the 404 handler.

**Fix (Console)**:
1. API Gateway → APIs → users-api → Resources
2. Click the method (e.g., POST under /users)
3. Click Integration Request
4. Edit → check "Use Lambda Proxy Integration"
5. Save → redeploy (Create Deployment → prod)

**Fix (CLI)**:
```powershell
aws apigateway put-integration `
  --rest-api-id $API_ID `
  --resource-id $USERS_RESOURCE_ID `
  --http-method POST `
  --type AWS_PROXY `
  --integration-http-method POST `
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations"
```

---

## Invoke-RestMethod SSL/TLS Error

**Symptom**: `Invoke-RestMethod` throws `The underlying connection was closed: An unexpected error occurred on a send`

**Cause**: PowerShell TLS version mismatch on older Windows.

**Fix**:
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```
Add this before your `Invoke-RestMethod` calls.

Alternatively add `-SkipCertificateCheck` flag (PowerShell 7+).

---

## DynamoDB Table Already Exists

**Symptom**: `aws dynamodb create-table` fails with `ResourceInUseException: Table already exists`

**Cause**: A previous run created the table and it was not cleaned up.

**Fix**:
```powershell
aws dynamodb delete-table --table-name users
aws dynamodb wait table-not-exists --table-name users
# Now recreate
```

---

## Lambda Package Error

**Symptom**: `aws lambda create-function` fails with `InvalidParameterValueException: Could not unzip uploaded file`

**Cause**: The zip file path is wrong, or `Compress-Archive` failed silently.

**Fix**:
```powershell
# Verify zip exists and has content
Get-Item lambda\function.zip | Select-Object Name, Length
# Length should be > 1000 bytes

# Recreate explicitly
Remove-Item lambda\function.zip -ErrorAction SilentlyContinue
Compress-Archive -Path lambda\lambda_function.py -DestinationPath lambda\function.zip
```

Also verify the `fileb://` prefix is present:
```powershell
--zip-file fileb://lambda/function.zip
```
Without `fileb://`, the CLI interprets the path as a string literal, not a file reference.

---

## 403 Forbidden from API Gateway

**Symptom**: `403 {"message":"Forbidden"}` on any endpoint

**Cause**: Lambda does not have permission to be invoked by API Gateway.

**Fix**:
```powershell
aws lambda add-permission `
  --function-name users-api `
  --statement-id apigateway-invoke `
  --action lambda:InvokeFunction `
  --principal apigateway.amazonaws.com `
  --source-arn "arn:aws:execute-api:us-east-1:${ACCOUNT_ID}:${API_ID}/*/*"
```

If the permission already exists (`ResourceConflictException`), remove and re-add:
```powershell
aws lambda remove-permission --function-name users-api --statement-id apigateway-invoke
# Then re-add
```

---

## Variables Lost Between Sessions

**Re-fetch all key IDs**:
```powershell
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text

$LAMBDA_ROLE_ARN = aws iam get-role `
  --role-name lambda-users-api-role `
  --query "Role.Arn" --output text

$LAMBDA_ARN = aws lambda get-function `
  --function-name users-api `
  --query "Configuration.FunctionArn" --output text

$API_ID = aws apigateway get-rest-apis `
  --query "items[?name=='users-api'].id | [0]" `
  --output text

$API_URL = "https://$API_ID.execute-api.us-east-1.amazonaws.com/prod"

Write-Host "Account:  $ACCOUNT_ID"
Write-Host "Role ARN: $LAMBDA_ROLE_ARN"
Write-Host "Lambda:   $LAMBDA_ARN"
Write-Host "API ID:   $API_ID"
Write-Host "API URL:  $API_URL"
```