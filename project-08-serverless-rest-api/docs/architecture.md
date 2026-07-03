# Architecture — Serverless REST API

## Full System Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Client Layer                                │
│                                                                     │
│   PowerShell           curl              Postman        Browser     │
│   Invoke-RestMethod    HTTP/HTTPS        REST client    fetch()     │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ HTTPS (TLS 1.2+)
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    API Gateway — REST API                           │
│                    Name: users-api                                  │
│                    Endpoint: Regional (us-east-1)                   │
│                    Stage: prod                                      │
│                                                                     │
│   Resource           Method    Integration         Handler          │
│   ─────────────────────────────────────────────────────────        │
│   /users             POST    → Lambda Proxy    →  create_user()     │
│   /users             GET     → Lambda Proxy    →  list_users()      │
│   /users/{userId}    GET     → Lambda Proxy    →  get_user()        │
│   /users/{userId}    PUT     → Lambda Proxy    →  update_user()     │
│   /users/{userId}    DELETE  → Lambda Proxy    →  delete_user()     │
│                                                                     │
│   URL: https://{API_ID}.execute-api.us-east-1.amazonaws.com/prod   │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ Lambda Proxy Invocation (sync)
                               │ JSON event with httpMethod, path,
                               │ pathParameters, body, headers
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     AWS Lambda                                      │
│                     Function: users-api                             │
│                     Runtime: Python 3.12                            │
│                     Memory: 128 MB  Timeout: 30s                    │
│                     Handler: lambda_function.lambda_handler         │
│                                                                     │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │                  lambda_function.py                          │  │
│   │                                                              │  │
│   │  lambda_handler()  ← entry point                            │  │
│   │       │                                                      │  │
│   │       ├─ POST /users         → create_user(body)            │  │
│   │       ├─ GET  /users         → list_users()                 │  │
│   │       ├─ GET  /users/{id}    → get_user(user_id)            │  │
│   │       ├─ PUT  /users/{id}    → update_user(user_id, body)   │  │
│   │       └─ DELETE /users/{id}  → delete_user(user_id)         │  │
│   │                                                              │  │
│   │  Returns: {statusCode, headers, body}                        │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                               │                                     │
│   Execution Role: lambda-users-api-role                            │
│   ├── AWSLambdaBasicExecutionRole (CloudWatch Logs)                │
│   └── dynamodb-users-access (6 DynamoDB actions on table/users)    │
└───────────────────┬───────────────────────┬─────────────────────────┘
                    │ boto3 SDK calls        │ print() logs
                    ▼                        ▼
┌──────────────────────────┐   ┌─────────────────────────────────────┐
│       DynamoDB           │   │      CloudWatch Logs                │
│   Table: users           │   │   Log group: /aws/lambda/users-api  │
│   PK: userId (S)         │   │                                     │
│   Billing: On-demand     │   │   START, END, REPORT per invocation │
│   Region: us-east-1      │   │   + Event JSON                      │
│   Encryption: AWS KMS    │   │   + Exception tracebacks            │
└──────────────────────────┘   └─────────────────────────────────────┘
```

---

## Lambda Container Lifecycle

```
First invocation (cold start):
┌────────────────────────────────────────────────────┐
│ 1. AWS downloads deployment package (~1 KB zip)    │ ~50ms
│ 2. Python interpreter initializes                  │ ~50ms
│ 3. Module-level code runs:                         │ ~20ms
│    - imports (json, boto3, uuid, datetime...)      │
│    - dynamodb = boto3.resource(...)                │
│    - table = dynamodb.Table('users')               │
│ 4. lambda_handler() is called                      │ ~20-80ms
│    (DynamoDB call dominates)                       │
└────────────────────────────────────────────────────┘
Total: ~140-200ms

Warm invocations (container reused):
┌────────────────────────────────────────────────────┐
│ Steps 1-3 are SKIPPED — container already warm     │
│ lambda_handler() is called directly                │ ~20-80ms
└────────────────────────────────────────────────────┘
Total: ~20-80ms
```

---

## IAM Permission Chain

```
API Gateway (apigateway.amazonaws.com)
    │
    │ requires: lambda:InvokeFunction
    │ granted by: resource-based policy on users-api Lambda
    │
    ▼
Lambda (users-api)
    │
    │ assumes: lambda-users-api-role (trust policy)
    │
    ▼
IAM Role (lambda-users-api-role)
    │
    ├── AWSLambdaBasicExecutionRole
    │   └── logs:CreateLogGroup/Stream/PutLogEvents on *
    │
    └── dynamodb-users-access (inline)
        └── dynamodb:{GetItem,PutItem,UpdateItem,DeleteItem,Scan,Query}
            on arn:aws:dynamodb:us-east-1:ACCOUNT:table/users
    │
    ▼
DynamoDB (table: users)
```

---

## Data Flow — POST /users

```
Client sends:
  POST /prod/users HTTP/1.1
  Content-Type: application/json
  {"name": "Vinay Kumar", "email": "vinay@example.com"}
         │
         ▼
API Gateway wraps in Lambda event:
  {
    "httpMethod": "POST",
    "path": "/users",
    "pathParameters": null,
    "body": "{\"name\": \"Vinay Kumar\", \"email\": \"vinay@example.com\"}",
    "headers": {"Content-Type": "application/json", ...}
  }
         │
         ▼
Lambda lambda_handler() routes to create_user(body)
  - json.loads(body) → {"name": "Vinay Kumar", "email": "vinay@example.com"}
  - uuid.uuid4() → "550e8400-e29b-41d4-a716-446655440000"
  - datetime.utcnow().isoformat() → "2025-06-01T10:30:00.123456"
  - table.put_item(Item={userId, name, email, role, createdAt, updatedAt})
         │
         ▼
DynamoDB writes item, returns success
         │
         ▼
Lambda returns to API Gateway:
  {
    "statusCode": 201,
    "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
    "body": "{\"message\": \"User created successfully\", \"user\": {...}}"
  }
         │
         ▼
API Gateway extracts statusCode, headers, body
Returns to client:
  HTTP/1.1 201 Created
  Content-Type: application/json
  Access-Control-Allow-Origin: *
  {"message": "User created successfully", "user": {...}}
```

---

## Resource Inventory

| Resource | Name | Key Details |
|---|---|---|
| DynamoDB table | `users` | PK: userId (S), on-demand |
| Lambda function | `users-api` | Python 3.12, 128MB, 30s |
| IAM role | `lambda-users-api-role` | Trust: lambda.amazonaws.com |
| IAM policy (managed) | AWSLambdaBasicExecutionRole | CloudWatch Logs access |
| IAM policy (inline) | dynamodb-users-access | 6 DynamoDB actions |
| API Gateway | `users-api` | REST, Regional |
| API stage | `prod` | Deployed stage |
| CloudWatch log group | `/aws/lambda/users-api` | Auto-created by Lambda |