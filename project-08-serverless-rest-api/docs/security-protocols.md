# Security Protocols

## IAM — Lambda Execution Role

### Role: `lambda-users-api-role`

The Lambda function assumes this role at runtime. Every AWS SDK call made inside the function uses the credentials vended by this role.

**Trust policy** — allows Lambda service to assume the role:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "lambda.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
```

**Attached managed policy**: `AWSLambdaBasicExecutionRole`
```json
{
  "Effect": "Allow",
  "Action": [
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents"
  ],
  "Resource": "*"
}
```
This allows Lambda to write execution logs to CloudWatch. Without it, Lambda cannot log — debugging becomes impossible.

**Inline policy**: `dynamodb-users-access`
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
      "dynamodb:Query"
    ],
    "Resource": "arn:aws:dynamodb:us-east-1:ACCOUNT_ID:table/users"
  }]
}
```

### Least Privilege Analysis

| What is allowed | Why |
|---|---|
| `dynamodb:GetItem` | Read single user by ID |
| `dynamodb:PutItem` | Create new user |
| `dynamodb:UpdateItem` | Update user attributes |
| `dynamodb:DeleteItem` | Delete user |
| `dynamodb:Scan` | List all users |
| `dynamodb:Query` | Future: query by GSI |

| What is NOT allowed | Why excluded |
|---|---|
| `dynamodb:*` | Would grant all DynamoDB permissions — not needed |
| `dynamodb:CreateTable` | Lambda should not create infrastructure |
| `dynamodb:DeleteTable` | Lambda should not destroy infrastructure |
| Access to other tables | Resource is scoped to `table/users` ARN only |
| S3, EC2, IAM, etc. | Lambda has no business accessing other services |

The resource constraint `arn:aws:dynamodb:us-east-1:ACCOUNT_ID:table/users` means even if another table exists in the same account, this Lambda cannot access it.

---

## API Gateway — Access Control

### Current Configuration (Development)

The API in this project uses `NONE` authorization — all endpoints are publicly accessible to anyone with the URL. This is acceptable for a portfolio/learning project.

```
Authorization type: NONE
API key required:   false
```

### Production Hardening Options

**API Key authentication**:
```
Authorization type: API_KEY
Usage plan: 1000 requests/day
```
Clients must include `x-api-key: YOUR_KEY` header. Prevents casual public access.

**IAM authorization**:
Callers must sign requests with AWS Signature V4. Suitable for service-to-service APIs within AWS.

**Lambda authorizer** (custom auth):
A separate Lambda function validates a JWT or session token before the main Lambda is invoked. Used for user authentication.

**Cognito User Pool authorizer**:
API Gateway validates a Cognito-issued JWT token. Standard for user-facing APIs.

For this project, the URL itself provides minimal security through obscurity — the random API ID means it cannot be guessed.

---

## Lambda Permission for API Gateway

API Gateway must have explicit permission to invoke the Lambda function:

```powershell
aws lambda add-permission `
  --function-name users-api `
  --statement-id apigateway-invoke `
  --action lambda:InvokeFunction `
  --principal apigateway.amazonaws.com `
  --source-arn "arn:aws:execute-api:us-east-1:ACCOUNT_ID:API_ID/*/*"
```

The `source-arn` wildcards allow any stage (`*`) and any method/route (`*`) of this specific API to invoke the function. A more restrictive policy would limit to specific stages or routes.

This permission is separate from the IAM role — it controls who can invoke Lambda, not what Lambda can do.

---

## CORS Configuration

Every Lambda response includes:
```python
'Access-Control-Allow-Origin': '*',
'Access-Control-Allow-Headers': 'Content-Type',
'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
```

**`Access-Control-Allow-Origin: *`** means any website can call this API from a browser. In production, restrict to your specific frontend domain:
```python
'Access-Control-Allow-Origin': 'https://yourdomain.com'
```

The `OPTIONS` method handler returns 200 immediately — this handles browser preflight requests that check CORS headers before the actual request.

---

## Data Security

**No authentication on user data**: Any caller can read, create, update, or delete any user. This is acceptable for a learning project with test data only.

**No input sanitisation beyond field whitelist**: The update whitelist `['name', 'email', 'role']` prevents attribute injection. A production API would also validate email format, enforce name length limits, and sanitize for XSS.

**No encryption at application layer**: DynamoDB storage is encrypted at rest using AWS-owned KMS keys (default). Data in transit uses TLS enforced by API Gateway and AWS SDK.

**No rate limiting**: API Gateway allows unlimited requests without throttling in this configuration. Production APIs set usage plans with request quotas and throttling limits (requests per second).

---

## Security Posture Summary

| Control | Status | Notes |
|---|---|---|
| IAM least privilege | ✅ Implemented | Scoped to 6 actions on 1 table |
| CloudWatch logging | ✅ Implemented | Full invocation logs |
| TLS in transit | ✅ AWS default | API Gateway enforces HTTPS |
| Storage encryption | ✅ AWS default | DynamoDB encrypted at rest |
| API authentication | ❌ Not implemented | Acceptable for dev/portfolio |
| Input validation | ⚠️ Minimal | Required fields only; no format checks |
| Rate limiting | ❌ Not implemented | Add usage plan for production |
| CORS restriction | ⚠️ Permissive | `*` allows all origins |


