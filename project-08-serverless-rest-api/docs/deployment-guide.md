# Comprehensive Deployment Guide

This guide details the complete process for deploying this project's resources.

## 🏗️ PART 1 — CREATE DYNAMODB TABLE

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **DynamoDB** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# Create DynamoDB table with on-demand billing
aws dynamodb create-table \
  --table-name users \
  --attribute-definitions AttributeName=userId,AttributeType=S \
  --key-schema AttributeName=userId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --tags Key=Project,Value=project-08-serverless

# Wait for table to become active
aws dynamodb wait table-exists --table-name users
echo "DynamoDB table created and active"

# Verify table
aws dynamodb describe-table \
  --table-name users \
  --query "Table.{Name:TableName,Status:TableStatus,BillingMode:BillingModeSummary.BillingMode}" \
  --output table
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Create DynamoDB table with on-demand billing
aws dynamodb create-table `
  --table-name users `
  --attribute-definitions AttributeName=userId,AttributeType=S `
  --key-schema AttributeName=userId,KeyType=HASH `
  --billing-mode PAY_PER_REQUEST `
  --tags Key=Project,Value=project-08-serverless

# Wait for table to become active
aws dynamodb wait table-exists --table-name users
Write-Host "DynamoDB table created and active"

# Verify table
aws dynamodb describe-table `
  --table-name users `
  --query "Table.{Name:TableName,Status:TableStatus,BillingMode:BillingModeSummary.BillingMode}" `
  --output table
```

---

## 🏗️ PART 2 — CREATE IAM ROLE FOR LAMBDA

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **Lambda** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# Create Lambda execution role
aws iam create-role \
  --role-name lambda-users-api-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach basic execution policy (CloudWatch Logs)
aws iam attach-role-policy \
  --role-name lambda-users-api-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# Add DynamoDB inline policy
aws iam put-role-policy \
  --role-name lambda-users-api-role \
  --policy-name dynamodb-users-access \
  --policy-document "{
    \"Version\":\"2012-10-17\",
    \"Statement\":[{
      \"Effect\":\"Allow\",
      \"Action\":[
        \"dynamodb:GetItem\",
        \"dynamodb:PutItem\",
        \"dynamodb:UpdateItem\",
        \"dynamodb:DeleteItem\",
        \"dynamodb:Scan\",
        \"dynamodb:Query\"
      ],
      \"Resource\":\"arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/users\"
    }]
  }"

# Get role ARN for Lambda creation
LAMBDA_ROLE_ARN=$(aws iam get-role \
  --role-name lambda-users-api-role \
  --query "Role.Arn" --output text)

echo "Lambda Role ARN: $LAMBDA_ROLE_ARN"

# Wait for role to propagate (IAM changes take ~10 seconds)
sleep 10
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Create Lambda execution role
aws iam create-role `
  --role-name lambda-users-api-role `
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach basic execution policy (CloudWatch Logs)
aws iam attach-role-policy `
  --role-name lambda-users-api-role `
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text

# Add DynamoDB inline policy
aws iam put-role-policy `
  --role-name lambda-users-api-role `
  --policy-name dynamodb-users-access `
  --policy-document "{
    `"Version`":`"2012-10-17`",
    `"Statement`":[{
      `"Effect`":`"Allow`",
      `"Action`":[
        `"dynamodb:GetItem`",
        `"dynamodb:PutItem`",
        `"dynamodb:UpdateItem`",
        `"dynamodb:DeleteItem`",
        `"dynamodb:Scan`",
        `"dynamodb:Query`"
      ],
      `"Resource`":`"arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/users`"
    }]
  }"

# Get role ARN for Lambda creation
$LAMBDA_ROLE_ARN = aws iam get-role `
  --role-name lambda-users-api-role `
  --query "Role.Arn" --output text

Write-Host "Lambda Role ARN: $LAMBDA_ROLE_ARN"

# Wait for role to propagate (IAM changes take ~10 seconds)
Start-Sleep -Seconds 10
```

---

## 🏗️ PART 3 — WRITE, PACKAGE AND DEPLOY LAMBDA FUNCTION

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **Lambda** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# Package Lambda into a ZIP file
zip -j lambda/function.zip lambda/lambda_function.py

echo "Lambda packaged into function.zip"

LAMBDA_ROLE_ARN=$(aws iam get-role --role-name lambda-users-api-role --query "Role.Arn" --output text)

# Deploy Lambda function
LAMBDA_ARN=$(aws lambda create-function \
  --function-name users-api \
  --runtime python3.12 \
  --role $LAMBDA_ROLE_ARN \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://lambda/function.zip \
  --timeout 30 \
  --memory-size 128 \
  --description "Serverless Users CRUD API - Project 8" \
  --environment Variables="{TABLE_NAME=users,REGION=us-east-1}" \
  --tags Project=project-08-serverless \
  --query "FunctionArn" --output text)

echo "Lambda ARN: $LAMBDA_ARN"

# Wait for Lambda to be active
aws lambda wait function-active --function-name users-api
echo "Lambda function is active"

# Verify
aws lambda get-function \
  --function-name users-api \
  --query "Configuration.{Name:FunctionName,Runtime:Runtime,State:State,Memory:MemorySize,Timeout:Timeout}" \
  --output table
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Package Lambda into a ZIP file
Compress-Archive `
  -Path lambda\lambda_function.py `
  -DestinationPath lambdaunction.zip `
  -Force

Write-Host "Lambda packaged into function.zip"

$LAMBDA_ROLE_ARN = aws iam get-role --role-name lambda-users-api-role --query "Role.Arn" --output text

# Deploy Lambda function
$LAMBDA_ARN = aws lambda create-function `
  --function-name users-api `
  --runtime python3.12 `
  --role $LAMBDA_ROLE_ARN `
  --handler lambda_function.lambda_handler `
  --zip-file fileb://lambda/function.zip `
  --timeout 30 `
  --memory-size 128 `
  --description "Serverless Users CRUD API - Project 8" `
  --environment Variables="{TABLE_NAME=users,REGION=us-east-1}" `
  --tags Project=project-08-serverless `
  --query "FunctionArn" --output text

Write-Host "Lambda ARN: $LAMBDA_ARN"

# Wait for Lambda to be active
aws lambda wait function-active --function-name users-api
Write-Host "Lambda function is active"

# Verify
aws lambda get-function `
  --function-name users-api `
  --query "Configuration.{Name:FunctionName,Runtime:Runtime,State:State,Memory:MemorySize,Timeout:Timeout}" `
  --output table
```

---

## 🏗️ PART 4 — TEST LAMBDA EXECUTION NATIVELY

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **VPC** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# Test 1 - Create a user
CREATE_PAYLOAD='{"body":"{\"name\":\"Vinay Kumar\",\"email\":\"vinay@example.com\",\"role\":\"admin\"}","httpMethod":"POST","path":"/users"}'

aws lambda invoke \
  --function-name users-api \
  --payload "$CREATE_PAYLOAD" \
  --cli-binary-format raw-in-base64-out \
  response.json

cat response.json

# Test 2 - List all users
LIST_PAYLOAD='{"httpMethod":"GET","path":"/users"}'

aws lambda invoke \
  --function-name users-api \
  --payload "$LIST_PAYLOAD" \
  --cli-binary-format raw-in-base64-out \
  response-list.json

cat response-list.json
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Test 1 - Create a user
$CREATE_PAYLOAD = '{"body":"{"name":"Vinay Kumar","email":"vinay@example.com","role":"admin"}","httpMethod":"POST","path":"/users"}'

aws lambda invoke `
  --function-name users-api `
  --payload $CREATE_PAYLOAD `
  --cli-binary-format raw-in-base64-out `
  response.json

cat response.json

# Test 2 - List all users
$LIST_PAYLOAD = '{"httpMethod":"GET","path":"/users"}'

aws lambda invoke `
  --function-name users-api `
  --payload $LIST_PAYLOAD `
  --cli-binary-format raw-in-base64-out `
  response-list.json

cat response-list.json
```

---

## 🏗️ PART 5 — CREATE AND CONFIGURE API GATEWAY

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **API Gateway** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# Step 1 - Create REST API
API_ID=$(aws apigateway create-rest-api \
  --name users-api \
  --description "Serverless Users REST API - Project 8" \
  --endpoint-configuration types=REGIONAL \
  --query "id" --output text)

echo "API ID: $API_ID"

# Step 2 - Get root resource ID
ROOT_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --query "items[?path=='/'].id" \
  --output text)

# Step 3 - Create /users resource
USERS_RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_ID \
  --path-part users \
  --query "id" --output text)

# Step 4 - Create /users/{userId} resource
USER_ID_RESOURCE=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $USERS_RESOURCE_ID \
  --path-part "{userId}" \
  --query "id" --output text)

# Get Lambda ARN
LAMBDA_ARN=$(aws lambda get-function --function-name users-api --query "Configuration.FunctionArn" --output text)

add_api_method() {
  local RESOURCE_ID=$1
  local HTTP_METHOD=$2

  aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method $HTTP_METHOD \
    --authorization-type NONE > /dev/null

  aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method $HTTP_METHOD \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations" > /dev/null

  echo "Created: $HTTP_METHOD on resource $RESOURCE_ID"
}

# Step 5 - Add methods
add_api_method $USERS_RESOURCE_ID "POST"
add_api_method $USERS_RESOURCE_ID "GET"
add_api_method $USER_ID_RESOURCE "GET"
add_api_method $USER_ID_RESOURCE "PUT"
add_api_method $USER_ID_RESOURCE "DELETE"

# Step 7 - Grant API Gateway permission to invoke Lambda
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
TIMESTAMP=$(date +%s)

aws lambda add-permission \
  --function-name users-api \
  --statement-id "apigateway-invoke-$TIMESTAMP" \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:${ACCOUNT_ID}:${API_ID}/*/*"

echo "Lambda permission granted to API Gateway"

# Step 8 - Deploy to prod stage
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --description "Initial deployment - Project 8" > /dev/null

API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"
echo "API deployed at: $API_URL"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Step 1 - Create REST API
$API_ID = aws apigateway create-rest-api `
  --name users-api `
  --description "Serverless Users REST API - Project 8" `
  --endpoint-configuration types=REGIONAL `
  --query "id" --output text

Write-Host "API ID: $API_ID"

# Step 2 - Get root resource ID
$ROOT_ID = aws apigateway get-resources `
  --rest-api-id $API_ID `
  --query "items[?path=='/'].id" `
  --output text

# Step 3 - Create /users resource
$USERS_RESOURCE_ID = aws apigateway create-resource `
  --rest-api-id $API_ID `
  --parent-id $ROOT_ID `
  --path-part users `
  --query "id" --output text

# Step 4 - Create /users/{userId} resource
$USER_ID_RESOURCE = aws apigateway create-resource `
  --rest-api-id $API_ID `
  --parent-id $USERS_RESOURCE_ID `
  --path-part "{userId}" `
  --query "id" --output text

# Get Lambda ARN
$LAMBDA_ARN = aws lambda get-function --function-name users-api --query "Configuration.FunctionArn" --output text

function Add-ApiMethod {
  param($ResourceId, $HttpMethod)

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
    --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations" | Out-Null

  Write-Host "Created: $HttpMethod on resource $ResourceId"
}

# Step 5 - Add methods
Add-ApiMethod -ResourceId $USERS_RESOURCE_ID -HttpMethod "POST"
Add-ApiMethod -ResourceId $USERS_RESOURCE_ID -HttpMethod "GET"
Add-ApiMethod -ResourceId $USER_ID_RESOURCE -HttpMethod "GET"
Add-ApiMethod -ResourceId $USER_ID_RESOURCE -HttpMethod "PUT"
Add-ApiMethod -ResourceId $USER_ID_RESOURCE -HttpMethod "DELETE"

# Step 7 - Grant API Gateway permission to invoke Lambda
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text

aws lambda add-permission `
  --function-name users-api `
  --statement-id apigateway-invoke `
  --action lambda:InvokeFunction `
  --principal apigateway.amazonaws.com `
  --source-arn "arn:aws:execute-api:us-east-1:${ACCOUNT_ID}:${API_ID}/*/*"

Write-Host "Lambda permission granted to API Gateway"

# Step 8 - Deploy to prod stage
aws apigateway create-deployment `
  --rest-api-id $API_ID `
  --stage-name prod `
  --description "Initial deployment - Project 8" | Out-Null

$API_URL = "https://$API_ID.execute-api.us-east-1.amazonaws.com/prod"
Write-Host "API deployed at: $API_URL"
```

---

## 🏗️ PART 6 — TEST THE FULL API THROUGH API GATEWAY

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **API Gateway** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='users-api'].id | [0]" --output text)
API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"

echo -e "\e[36m=== TEST 1: Create User ===\e[0m"
RESPONSE1=$(curl -s -X POST "$API_URL/users" -H "Content-Type: application/json" -d '{"name":"Vinay Kumar","email":"vinay@example.com","role":"admin"}')
USER_ID=$(echo $RESPONSE1 | grep -o '"userId": "[^"]*' | cut -d'"' -f4)
echo "Created user ID: $USER_ID"

echo -e "\e[36m=== TEST 2: Create Second User ===\e[0m"
curl -s -X POST "$API_URL/users" -H "Content-Type: application/json" -d '{"name":"AWS Engineer","email":"aws@example.com","role":"developer"}'

echo -e "\n\e[36m=== TEST 3: List All Users ===\e[0m"
curl -s -X GET "$API_URL/users"

echo -e "\n\n\e[36m=== TEST 4: Get Single User ===\e[0m"
curl -s -X GET "$API_URL/users/$USER_ID"

echo -e "\n\n\e[36m=== TEST 5: Update User ===\e[0m"
curl -s -X PUT "$API_URL/users/$USER_ID" -H "Content-Type: application/json" -d '{"role":"superadmin","name":"Vinay Kumar - Updated"}'

echo -e "\n\n\e[36m=== TEST 6: Test 404 ===\e[0m"
curl -s -X GET "$API_URL/users/non-existent-id-12345"

echo -e "\n\n\e[36m=== TEST 7: Delete User ===\e[0m"
curl -s -X DELETE "$API_URL/users/$USER_ID"

echo -e "\n\n\e[36m=== TEST 8: Verify Deletion ===\e[0m"
curl -s -X GET "$API_URL/users"

echo -e "\n\n\e[32m=== ALL TESTS PASSED ===\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Set your API URL (retrieve if not set)
$API_ID = aws apigateway get-rest-apis --query "items[?name=='users-api'].id | [0]" --output text
$API_URL = "https://$API_ID.execute-api.us-east-1.amazonaws.com/prod"

# TEST 1: Create User
Write-Host "=== TEST 1: Create User ===" -ForegroundColor Cyan
$user1 = Invoke-RestMethod -Uri "$API_URL/users" -Method POST -ContentType "application/json" -Body '{"name":"Vinay Kumar","email":"vinay@example.com","role":"admin"}'
Write-Host "Created user ID: $($user1.user.userId)"
$USER_ID = $user1.user.userId

# TEST 2: Create Second User
Write-Host "=== TEST 2: Create Second User ===" -ForegroundColor Cyan
$user2 = Invoke-RestMethod -Uri "$API_URL/users" -Method POST -ContentType "application/json" -Body '{"name":"AWS Engineer","email":"aws@example.com","role":"developer"}'
Write-Host "Created user ID: $($user2.user.userId)"

# TEST 3: List All Users
Write-Host "=== TEST 3: List All Users ===" -ForegroundColor Cyan
$allUsers = Invoke-RestMethod -Uri "$API_URL/users" -Method GET
Write-Host "Total users: $($allUsers.count)"

# TEST 4: Get Single User
Write-Host "=== TEST 4: Get Single User ===" -ForegroundColor Cyan
$singleUser = Invoke-RestMethod -Uri "$API_URL/users/$USER_ID" -Method GET
Write-Host "Got user: $($singleUser.user.name)"

# TEST 5: Update User
Write-Host "=== TEST 5: Update User ===" -ForegroundColor Cyan
$updatedUser = Invoke-RestMethod -Uri "$API_URL/users/$USER_ID" -Method PUT -ContentType "application/json" -Body '{"role":"superadmin","name":"Vinay Kumar - Updated"}'
Write-Host "Updated user role: $($updatedUser.user.role)"

# TEST 6: Get 404
Write-Host "=== TEST 6: Test 404 ===" -ForegroundColor Cyan
try { Invoke-RestMethod -Uri "$API_URL/users/non-existent-id-12345" -Method GET } catch { Write-Host "404 received as expected: $($_.Exception.Message)" }

# TEST 7: Delete User
Write-Host "=== TEST 7: Delete User ===" -ForegroundColor Cyan
$deleted = Invoke-RestMethod -Uri "$API_URL/users/$USER_ID" -Method DELETE
Write-Host "Delete response: $($deleted.message)"

# TEST 8: Verify Deletion
Write-Host "=== TEST 8: Verify Deletion ===" -ForegroundColor Cyan
$finalList = Invoke-RestMethod -Uri "$API_URL/users" -Method GET
Write-Host "Users remaining: $($finalList.count)"

Write-Host "`n=== ALL TESTS PASSED ===" -ForegroundColor Green
```

---

## 🏗️ PART 7 — VERIFY DATA PERSISTENCE IN DYNAMODB

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **DynamoDB** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# Check items in DynamoDB via CLI
aws dynamodb scan \
  --table-name users \
  --query "Items[*].{ID:userId.S,Name:name.S,Email:email.S,Role:role.S}" \
  --output table
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Check items in DynamoDB via CLI
aws dynamodb scan `
  --table-name users `
  --query "Items[*].{ID:userId.S,Name:name.S,Email:email.S,Role:role.S}" `
  --output table
```

---

## 🏗️ PART 8 — MONITOR EXECUTION LOGS IN CLOUDWATCH

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **CloudWatch** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# List Lambda log groups
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/lambda/users-api" \
  --query "logGroups[*].{Name:logGroupName,Retention:retentionInDays}" \
  --output table

# Get latest log stream
LOG_STREAM=$(aws logs describe-log-streams \
  --log-group-name "/aws/lambda/users-api" \
  --order-by LastEventTime \
  --descending \
  --max-items 1 \
  --query "logStreams[0].logStreamName" \
  --output text)

# Read the latest logs
aws logs get-log-events \
  --log-group-name "/aws/lambda/users-api" \
  --log-stream-name "$LOG_STREAM" \
  --query "events[*].message" \
  --output text
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# List Lambda log groups
aws logs describe-log-groups `
  --log-group-name-prefix "/aws/lambda/users-api" `
  --query "logGroups[*].{Name:logGroupName,Retention:retentionInDays}" `
  --output table

# Get latest log stream
$LOG_STREAM = aws logs describe-log-streams `
  --log-group-name "/aws/lambda/users-api" `
  --order-by LastEventTime `
  --descending `
  --max-items 1 `
  --query "logStreams[0].logStreamName" `
  --output text

# Read the latest logs
aws logs get-log-events `
  --log-group-name "/aws/lambda/users-api" `
  --log-stream-name $LOG_STREAM `
  --query "events[*].message" `
  --output text
```

---

## 🏗️ PART 9 — UPDATE AND REDEPLOY LAMBDA FUNCTION CODE

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **Lambda** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# Repackage
zip -j lambda/function.zip lambda/lambda_function.py

# Deploy update
aws lambda update-function-code \
  --function-name users-api \
  --zip-file fileb://lambda/function.zip

# Wait for update to complete
aws lambda wait function-updated --function-name users-api
echo "Lambda updated successfully"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Repackage
Compress-Archive `
  -Path lambda\lambda_function.py `
  -DestinationPath lambdaunction.zip `
  -Force

# Deploy update
aws lambda update-function-code `
  --function-name users-api `
  --zip-file fileb://lambda/function.zip

# Wait for update to complete
aws lambda wait function-updated --function-name users-api
Write-Host "Lambda updated successfully"
```

---

## 🧹 TEARDOWN
To prevent recurring AWS charges, proceed to the `docs/cleanup-guide.md` to run the tear-down scripts.
