# Project Overview — Serverless REST API

## What This Project Builds

A fully serverless REST API that performs CRUD operations on a `users` resource. The entire stack — compute, routing, and storage — is managed by AWS. There are no servers to provision, no operating systems to patch, no capacity to pre-plan.

The three services work together:

| Service | Role | Billing model |
|---|---|---|
| API Gateway | HTTP frontend, request routing | Per API call |
| Lambda | Business logic execution | Per invocation + compute time |
| DynamoDB | Persistent NoSQL storage | Per read/write request |

At zero traffic, this API costs exactly $0. At 1 million requests per month it stays within free tier. At 10 million requests per month the cost is roughly $3–5 — far below any EC2 equivalent.

---

## Serverless vs Traditional

| Aspect | EC2 + RDS (Project 6) | Lambda + DynamoDB (Project 8) |
|---|---|---|
| Server management | You manage OS, patches, AMIs | AWS manages everything |
| Scaling | Manual ASG configuration | Automatic — instant, to 1000 concurrent |
| Idle cost | ~$15/month for t2.micro + db.t3.micro | $0 — no requests = no cost |
| Cold starts | None (always warm) | ~100ms–1s on first invocation |
| Max execution time | Unlimited | 15 minutes per invocation |
| Deployment | AMI bake or user data scripts | Zip file upload |
| Database schema | Fixed — ALTER TABLE required | Flexible — add attributes freely |
| Use case | Long-running, stateful workloads | Event-driven, short-burst APIs |

---

## Why One Lambda Function (Not One Per Route)

This project uses a single Lambda function (`users-api`) to handle all five HTTP methods. An alternative pattern — one Lambda per route — is called the "microfunction" or "nano-function" pattern.

**Single function (this project)**:
- Simpler deployment — one ZIP, one function version
- Shared code (helpers, DynamoDB client) initialized once per container
- All routes visible in one file — easier to understand
- Cold starts affect all routes proportionally

**One function per route** (more common at scale):
- Independent deployments per route
- Fine-grained IAM policies per operation
- Independent scaling per endpoint
- More complexity — more Lambda functions to manage

For a beginner/intermediate portfolio project, the single-function approach demonstrates routing logic clearly.

---

## Lambda Proxy Integration

The key configuration choice in API Gateway is **Lambda Proxy Integration** (enabled for all methods). With it:

**API Gateway forwards the entire request as a JSON event**:
```json
{
  "httpMethod": "POST",
  "path": "/users",
  "pathParameters": null,
  "queryStringParameters": null,
  "headers": {"Content-Type": "application/json", ...},
  "body": "{\"name\":\"Vinay Kumar\",\"email\":\"vinay@example.com\"}"
}
```

**Lambda returns a complete HTTP response**:
```json
{
  "statusCode": 201,
  "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
  "body": "{\"message\":\"User created successfully\",\"user\":{...}}"
}
```

API Gateway does no transformation — it passes everything through. This gives the Lambda function full control over routing, status codes, and headers.

Without proxy integration, you must configure request/response mappings in API Gateway for every method — significantly more work and harder to maintain.

---

## Data Model

The `users` table stores records with this shape:

```json
{
  "userId":    "550e8400-e29b-41d4-a716-446655440000",
  "name":      "Vinay Kumar",
  "email":     "vinay@example.com",
  "role":      "admin",
  "createdAt": "2025-06-01T10:30:00.123456",
  "updatedAt": "2025-06-01T10:30:00.123456"
}
```

DynamoDB is schema-flexible — you can add any attribute to any item without altering a table schema. Only the partition key (`userId`) is required on every item.

---

## Request Lifecycle

```
1. Client sends: POST https://abc123.execute-api.us-east-1.amazonaws.com/prod/users

2. API Gateway:
   - Receives HTTP request
   - Validates route: POST /users exists
   - Wraps request in Lambda event JSON
   - Invokes Lambda function synchronously

3. Lambda:
   - Container starts (cold start) or reuses warm container
   - lambda_handler() called with event
   - Routes to create_user()
   - Generates UUID, builds item dict
   - Calls DynamoDB put_item()
   - Returns structured response dict

4. DynamoDB:
   - Writes item to users table
   - Returns success acknowledgement

5. Lambda returns response to API Gateway

6. API Gateway:
   - Extracts statusCode, headers, body from Lambda response
   - Returns HTTP 201 to client

7. Client receives JSON response with created user
```

Total time: typically 50–200ms (warm Lambda + DynamoDB write latency).