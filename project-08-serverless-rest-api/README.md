<div align="center">
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="36" height="36" style="vertical-align: middle"/> Project 08: Serverless REST API with API Gateway, Lambda & DynamoDB</h1>

  <p><i>Build a fully serverless CRUD REST API using Amazon API Gateway as the HTTP front door, AWS Lambda for compute logic, and DynamoDB as a NoSQL data store. This project implements request validation, Lambda proxy integration, DynamoDB single-table design, and API key-based throttling — achieving zero-server, pay-per-request architecture.</i></p>

  <p>
    <img src="https://img.shields.io/badge/Level-Intermediate-blue" alt="Level"/>
    <img src="https://img.shields.io/badge/Time-3--4%20Hours-orange" alt="Time"/>
    <img src="https://img.shields.io/badge/Cost-$0.00%20(Free%20Tier)-brightgreen" alt="Cost"/>
    <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License"/>
    <img src="https://img.shields.io/badge/Build-Passing-success" alt="Build"/>
  </p>

  <p>
    <a href="#-infrastructure-specifications">Infrastructure</a> · 
    <a href="#-key-components">Components</a> · 
    <a href="#-core-features">Features</a> · 
    <a href="#-setup--installation">Setup</a> · 
    <a href="#-documentation-suite">Docs</a>
  </p>

</div>

<br/>

<div align="center">

## 🏗️ Architecture Overview

<img src="./architecture/serverless-architecture.svg" alt="Serverless REST API with API Gateway, Lambda & DynamoDB — System Architecture" width="800"/>

<p><i>▲ High-level architecture diagram showing the interaction between API Gateway, Lambda, DynamoDB, IAM, CloudWatch services</i></p>

</div>

## 📐 Infrastructure Specifications

| Resource | Configuration |
|:---------|:--------------|
| **API Gateway** | REST API (regional); stages: `dev`, `prod`; API key + usage plan (1000 req/day, 10 req/sec burst) |
| **Lambda Functions** | Python 3.12 runtime; 128MB memory, 10s timeout; 4 functions (Create, Read, Update, Delete) |
| **DynamoDB Table** | On-demand capacity; partition key `PK` (String), sort key `SK` (String); single-table design |
| **IAM Role (Lambda)** | `lambda-dynamodb-role` with `dynamodb:PutItem/GetItem/UpdateItem/DeleteItem/Query` on table ARN |
| **CloudWatch Logs** | Automatic log groups per Lambda function; 14-day retention; structured JSON logging |
| **API Models** | JSON Schema request validation on POST/PUT endpoints; 400 response on malformed payloads |
| **CORS** | Enabled on all endpoints; `Access-Control-Allow-Origin: *` for development |
| **Region** | ap-south-1 |

## 🧩 Key Components

### API Gateway (REST)
Managed HTTP endpoint with stages, request validation, API keys, and usage plans

### Lambda Functions (x4)
Stateless Python 3.12 handlers for Create, Read, Update, Delete operations

### DynamoDB (Single-Table)
NoSQL database using single-table design with `PK`/`SK` composite key pattern

### Lambda Proxy Integration
API Gateway passes full HTTP request to Lambda; Lambda returns statusCode + body

### API Key & Usage Plan
Rate limiting (10 req/sec) and quota (1000 req/day) to prevent abuse

### Request Validation
JSON Schema models on API Gateway validate request body before invoking Lambda

## ⚡ Core Features

- **Zero-Server Architecture** – No EC2, no containers; pay only for actual API invocations ($0.20/million requests)
- **Single-Table DynamoDB Design** – Partition key (`PK`) + sort key (`SK`) pattern for flexible access patterns
- **Request Validation** – API Gateway JSON Schema models reject malformed requests before Lambda is invoked
- **API Key Throttling** – Usage plans enforce rate limits (10 req/sec) and daily quotas (1000 req/day)
- **Structured Logging** – Lambda functions emit JSON-formatted logs to CloudWatch for easy parsing
- **Stage Deployment** – Separate `dev` and `prod` stages with independent configurations and endpoints
- **CORS Support** – Pre-flight OPTIONS responses enable browser-based frontend integration

## 🛠️ Setup & Installation

### Prerequisites

- AWS CLI v2 configured with IAM credentials (from Project 01)
- Python 3.12+ installed locally for Lambda function development
- `zip` utility for packaging Lambda deployment artifacts
- Postman or `curl` for API testing

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects.git
cd project-08-serverless-rest-api

# 2. Configure environment variables
cp .env.example .env
# Edit .env with your specific values (see Environment Variables below)
```

### Environment Variables

Create a `.env` file in the project root:

```bash
export AWS_REGION="ap-south-1"
export TABLE_NAME="ServerlessAPI"
export API_NAME="serverless-crud-api"
export STAGE_NAME="dev"
export LAMBDA_ROLE_ARN="arn:aws:iam::ACCOUNT_ID:role/lambda-dynamodb-role"
```

### Run Commands

Choose your platform and execute the scripts in order:

<table>
<tr><th>Step</th><th>Script</th><th>Description</th></tr>
<tr><td>🐧</td><td><code>scripts/bash/01-create-dynamodb.sh</code></td><td>Creates DynamoDB table with on-demand capacity and PK/SK schema</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/01-create-dynamodb.ps1</code></td><td>Creates DynamoDB table with on-demand capacity and PK/SK schema</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/02-create-lambda-role.sh</code></td><td>Creates IAM role with DynamoDB and CloudWatch Logs permissions</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/02-create-lambda-role.ps1</code></td><td>Creates IAM role with DynamoDB and CloudWatch Logs permissions</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/03-deploy-lambdas.sh</code></td><td>Packages and deploys 4 Lambda functions (CRUD) with Python 3.12 runtime</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/03-deploy-lambdas.ps1</code></td><td>Packages and deploys 4 Lambda functions (CRUD) with Python 3.12 runtime</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/04-create-api-gateway.sh</code></td><td>Creates REST API with resources, methods, Lambda integrations, and CORS</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/04-create-api-gateway.ps1</code></td><td>Creates REST API with resources, methods, Lambda integrations, and CORS</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/05-test-api.sh</code></td><td>Runs curl commands against all CRUD endpoints and validates responses</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/05-test-api.ps1</code></td><td>Runs curl commands against all CRUD endpoints and validates responses</td></tr>
</table>

## 📚 Documentation Suite

| Document | Description |
|:---------|:------------|
| 📄 [Project Overview](docs/project-overview.md) | Comprehensive project context, goals, and learning outcomes |
| 🏗️ [Architecture Details](docs/architecture.md) | Deep-dive into system design, data flow, and component interactions |
| 🚀 [Deployment Guide](docs/deployment-guide.md) | Step-by-step deployment procedures for dev, staging, and production |
| 🔐 [Security Protocols](docs/security-protocols.md) | IAM policies, encryption, network security, and compliance controls |
| 🧪 [Testing Procedures](docs/testing-procedures.md) | Validation scripts, smoke tests, and integration test suites |
| 🛠️ [Troubleshooting](docs/troubleshooting.md) | Common issues, error codes, debugging steps, and resolution guides |

## 🤝 Contribution & Maintenance

### Testing

- `curl -X POST https://<api-id>.execute-api.<region>.amazonaws.com/dev/items -d '{...}'` – Create item
- `curl https://<api-id>.execute-api.<region>.amazonaws.com/dev/items/<id>` – Read item
- `aws dynamodb scan --table-name ServerlessAPI` – Verify items stored in DynamoDB
- `aws apigateway get-rest-api --rest-api-id <id>` – Validate API Gateway configuration
- Send malformed JSON body → expect 400 response from request validation

### Deployment

For full production deployment procedures, see the [Deployment Guide](docs/deployment-guide.md).

### Contributing

1. **Fork** the repository and create a feature branch (`git checkout -b feature/amazing-feature`)
2. **Commit** your changes (`git commit -m "Add amazing feature"`)
3. **Push** to the branch (`git push origin feature/amazing-feature`)
4. **Open** a Pull Request with a detailed description
5. Ensure all scripts exist in **both** `scripts/powershell/` and `scripts/bash/`

### License

This project is licensed under the **MIT License** — see the [LICENSE](../LICENSE) file for details.

### Contact & Credits

- **Author:** Vinay Kumar
- **GitHub:** [@vinay1515](https://github.com/vinay1515)
- **Repository:** [Vinay_kumar_AWS_Beginner_level_projects](https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects)

---

<div align="center">
  <b>[⬅️ Previous: Project 07](../project-07-cloudwatch-monitoring) &nbsp;|&nbsp; [Next: Project 09 ➡️](../project-09-cicd-pipeline)</b>
</div>
