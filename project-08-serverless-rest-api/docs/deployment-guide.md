# Deployment Guide — Serverless REST API

## Prerequisites

Before running any scripts, verify:

```powershell
# AWS CLI configured
aws sts get-caller-identity

# Region set to us-east-1
aws configure get region

# Python installed (needed to inspect/edit Lambda code locally)
python --version
# Expected: Python 3.12.x

# Store account ID for use in scripts
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
Write-Host "Account: $ACCOUNT_ID"
```

---

## Part 1 — DynamoDB Table

Script: `scripts/01-create-dynamodb.ps1`

```powershell
aws dynamodb create-table `
  --table-name users `
  --attribute-definitions AttributeName=userId,AttributeType=S `
  --key-schema AttributeName=userId,KeyType=HASH `
  --billing-mode PAY_PER_REQUEST `
  --tags Key=Project,Value=project-08-serverless

aws dynamodb wait table-exists --table-name users
```

**Checkpoint**: `aws dynamodb describe-table --table-name users --query "Table.TableStatus"` returns `ACTIVE`.

---

## Part 2 — IAM Role

Script: `scripts/02-create-lambda-role.ps1`

Creates `lambda-users-api-role` with:
- Trust policy allowing Lambda to assume the role
- `AWSLambdaBasicExecutionRole` managed policy (CloudWatch Logs)
- Inline `dynamodb-users-access` policy (6 DynamoDB actions on `table/users`)

**IAM propagation**: After creating a role, wait 10 seconds before using the ARN in Lambda creation. IAM changes are eventually consistent and immediately-created Lambda functions using a brand-new role may get `InvalidParameterValueException`.

**Checkpoint**: `aws iam get-role --role-name lambda-users-api-role` returns the role ARN.

---

## Part 3 — Package and Deploy Lambda

Script: `scripts/03-package-lambda.ps1` then `scripts/04-deploy-lambda.ps1`

**Package**:
```powershell
Compress-Archive `
  -Path lambda\lambda_function.py `
  -DestinationPath lambda\function.zip `
  -Force
```

**Deploy**:
```powershell
$LAMBDA_ARN = aws lambda create-function `
  --function-name users-api `
  --runtime python3.12 `
  --role $LAMBDA_ROLE_ARN `
  --handler lambda_function.lambda_handler `
  --zip-file fileb://lambda/function.zip `
  --timeout 30 `
  --memory-size 128 `
  --query "FunctionArn" --output text
```

**Handler format**: `filename.function_name` — the file is `lambda_function.py` and the entry point is `lambda_handler`, so the handler is `lambda_function.lambda_handler`.

**Checkpoint**: `aws lambda get-function --function-name users-api --query "Configuration.State"` returns `Active`.

---

## Part 4 — Direct Lambda Test

Before API Gateway, verify Lambda logic works:

```powershell
$PAYLOAD = '{"body":"{\"name\":\"Vinay Kumar\",\"email\":\"vinay@example.com\"}","httpMethod":"POST","path":"/users"}'

aws lambda invoke `
  --function-name users-api `
  --payload $PAYLOAD `
  --cli-binary-format raw-in-base64-out `
  response.json

cat response.json
```

Expected: `{"statusCode": 201, "body": "{\"message\": \"User created\", ...}"}`

If you see a 500 or an error, check CloudWatch Logs before proceeding to API Gateway:
```powershell
aws logs tail /aws/lambda/users-api --follow
```

---

## Part 5 — API Gateway

Script: `scripts/05-create-api-gateway.ps1`

Steps performed:
1. Create REST API (`users-api`, Regional endpoint)
2. Get root resource ID (`/`)
3. Create `/users` resource
4. Create `/users/{userId}` resource
5. Add POST + GET methods to `/users`
6. Add GET + PUT + DELETE methods to `/users/{userId}`
7. Add Lambda permission for API Gateway invoke
8. Deploy to `prod` stage

**Lambda proxy integration**: All methods use `type=AWS_PROXY` with `integration-http-method=POST`. The HTTP method in the integration is always POST regardless of the API method — this is how Lambda proxy integration works.

**Checkpoint**: `$API_URL` is printed. Curl or browser `GET $API_URL/users` returns `{"message":"Found 0 users","count":0,"users":[]}`.

---

## Part 6 — Full API Test

Script: `scripts/06-test-api.ps1`

Set your API URL first:
```powershell
$API_URL = "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod"
```

Then run `06-test-api.ps1`. All 8 test cases should pass with expected status codes and response bodies.

---

## Updating Lambda Code

When you modify `lambda/lambda_function.py`:

```powershell
# 1. Repackage
Compress-Archive `
  -Path lambda\lambda_function.py `
  -DestinationPath lambda\function.zip `
  -Force

# 2. Deploy update
aws lambda update-function-code `
  --function-name users-api `
  --zip-file fileb://lambda/function.zip

# 3. Wait for update
aws lambda wait function-updated --function-name users-api
```

No API Gateway changes needed — the Lambda ARN stays the same across code updates.

---

## Console Paths Summary

| Resource | Console Path |
|---|---|
| DynamoDB table | DynamoDB → Tables → users |
| Lambda function | Lambda → Functions → users-api |
| API Gateway | API Gateway → APIs → users-api |
| API stages | API Gateway → users-api → Stages → prod |
| IAM role | IAM → Roles → lambda-users-api-role |
| Lambda logs | CloudWatch → Log groups → /aws/lambda/users-api |
| Lambda metrics | Lambda → Monitor tab or CloudWatch → Metrics → Lambda |