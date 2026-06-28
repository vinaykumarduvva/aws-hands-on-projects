# Project 8 — Serverless REST API: Lambda + API Gateway + DynamoDB

![AWS](https://img.shields.io/badge/AWS-Lambda%20%2B%20API%20Gateway%20%2B%20DynamoDB-orange?logo=amazonaws)
![Level](https://img.shields.io/badge/Level-Intermediate-blue)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)
![Free Tier](https://img.shields.io/badge/Cost-Free%20Tier%20Forever-green)

Build a fully serverless REST API from scratch — no servers to manage, no EC2 to patch, scales automatically from zero to millions of requests. This is the most in-demand intermediate AWS skill and appears in virtually every Solutions Architect and Cloud Engineer interview.

---

## Architecture Overview

```text
Client (Browser / curl / Postman)
         │
         │ HTTPS Request
         ▼
┌──────────────────────────────────────────────┐
│         API Gateway (REST API)               │
│                                              │
│  POST   /users       → create user           │
│  GET    /users       → list all users        │
│  GET    /users/{id}  → get single user       │
│  PUT    /users/{id}  → update user           │
│  DELETE /users/{id}  → delete user           │
└──────────────────┬───────────────────────────┘
                   │ Lambda Proxy Integration
                   ▼
       ┌───────────────────────┐
       │     AWS Lambda        │
       │   users-api           │
       │   Python 3.12         │
       │   128 MB / 30 sec     │
       └───────────┬───────────┘
                   │ IAM Role (least privilege)
                   ▼
       ┌───────────────────────┐
       │      DynamoDB         │
       │   Table: users        │
       │   PK: userId (String) │
       │   On-demand billing   │
       └───────────────────────┘
```

---

## AWS Services Used

| Service | Role |
| --- | --- |
| AWS Lambda | Serverless compute — runs Python code on demand |
| API Gateway | HTTP endpoint — routes requests to Lambda |
| DynamoDB | Serverless NoSQL database — stores user records |
| IAM | Lambda execution role with scoped DynamoDB permissions |
| CloudWatch Logs | Automatic Lambda execution logs |
| CloudWatch | Lambda metrics — invocations, errors, duration |

---

## API Endpoints

| Method | Endpoint | Action | Status Codes |
| --- | --- | --- | --- |
| `POST` | `/users` | Create a new user | 201, 400, 500 |
| `GET` | `/users` | List all users | 200, 500 |
| `GET` | `/users/{userId}` | Get a single user | 200, 404, 500 |
| `PUT` | `/users/{userId}` | Update user fields | 200, 404, 500 |
| `DELETE` | `/users/{userId}` | Delete a user | 200, 404, 500 |

---

## Free Tier Status

| Resource | Free Tier | Duration |
| --- | --- | --- |
| Lambda | 1M requests/month + 400K GB-seconds | **Forever** |
| API Gateway | 1M API calls/month | 12 months |
| DynamoDB | 25 GB + 25 WCU + 25 RCU | **Forever** |

**Cost estimate: $0.00** — all three services within free tier.

---

## Project Structure

```text
project-08-serverless-rest-api/
├── README.md
├── LICENSE
├── .gitignore
├── docs/               — architecture, design, guides
├── lambda/             — Python function code + zip
├── scripts/            — PowerShell deployment scripts
├── architecture/       — SVG diagrams
└── images/             — Console screenshots
```

---

## Execution Order

| Script | Part | Task |
| --- | --- | --- |
| `01-create-dynamodb.ps1` | 1 | Create users table |
| `02-create-lambda-role.ps1` | 2 | IAM role + DynamoDB policy |
| `03-package-lambda.ps1` | 3 | Zip Lambda code |
| `04-deploy-lambda.ps1` | 3 | Deploy Lambda function |
| `05-create-api-gateway.ps1` | 5 | REST API + routes + deploy |
| `06-test-api.ps1` | 6 | Run all 8 API tests |
| `07-monitor-cloudwatch.ps1` | 8 | View logs and metrics |
| `08-update-lambda.ps1` | 9 | Update deployed code |
| `09-cleanup.ps1` | 10 | Full teardown |

---

## Key Concepts Demonstrated

**Lambda Proxy Integration**: API Gateway forwards the entire HTTP request as a JSON event to Lambda. Lambda returns a structured response with `statusCode`, `headers`, and `body`. This pattern gives full routing control to the Lambda function.

**Serverless vs Traditional**: Zero infrastructure management, automatic scaling, pay-per-invocation billing. The `users-api` Lambda function handles all 5 HTTP methods — routing is done in Python code, not via separate Lambda functions per route.

**DynamoDB On-Demand**: No capacity planning, no pre-provisioned read/write units. Scales instantly to any traffic level. Cost is per request, not per hour.

**IAM Least Privilege**: The Lambda execution role has exactly the DynamoDB operations it needs — `GetItem`, `PutItem`, `UpdateItem`, `DeleteItem`, `Scan`, `Query` — scoped to the specific `users` table ARN. Nothing more.

**CORS Headers**: Every response includes `Access-Control-Allow-Origin: *` so the API can be called from browser-based frontends without a proxy.

---

*Part of the AWS Cloud Projects portfolio — hands-on infrastructure built and documented end to end.*