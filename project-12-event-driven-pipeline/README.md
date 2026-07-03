<div align="center">
  <img src="https://raw.githubusercontent.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/main/project-12-event-driven-pipeline/architecture/architecture.svg" alt="Event-Driven Data Pipeline with S3, SQS & Lambda Architecture" width="820"/>
  <br/><br/>
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="36" height="36" style="vertical-align: middle"/> Project 12: Event-Driven Data Pipeline with S3, SQS & Lambda</h1>

  <p><i>Architect a fully event-driven data processing pipeline where S3 object uploads trigger SQS messages consumed by Lambda functions for transformation and loading. This project implements dead-letter queues, batch processing windows, message visibility timeouts, and idempotent processing — the foundation of modern serverless data engineering on AWS.</i></p>

  <p>
    <img src="https://img.shields.io/badge/Level-Intermediate/Advanced-blue" alt="Level"/>
    <img src="https://img.shields.io/badge/Time-4--5%20Hours-orange" alt="Time"/>
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

  <p><b>🔗 <a href="#">Live Demo</a></b> &nbsp;·&nbsp; <b>📹 <a href="#">Video Walkthrough</a></b></p>

</div>

<br/>

<div align="center">

## 🏗️ Architecture Overview

<img src="https://raw.githubusercontent.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/main/project-12-event-driven-pipeline/architecture/architecture.svg" alt="Event-Driven Data Pipeline with S3, SQS & Lambda — System Architecture" width="800"/>

<p><i>▲ High-level architecture diagram showing the interaction between S3, SQS, Lambda, DynamoDB, CloudWatch services</i></p>

</div>

## 📐 Infrastructure Specifications

| Resource | Configuration |
|:---------|:--------------|
| **S3 Source Bucket** | Event notifications enabled; triggers on `s3:ObjectCreated:*` → SQS queue |
| **SQS Main Queue** | Standard queue; visibility timeout 300s (6× Lambda timeout); message retention 4 days |
| **SQS Dead-Letter Queue** | Receives messages after 3 failed processing attempts; 14-day retention for analysis |
| **Lambda Processor** | Python 3.12; 256MB memory, 50s timeout; batch size 10 messages; concurrent executions 5 |
| **DynamoDB Results Table** | On-demand capacity; stores processed records with idempotency key (message ID) |
| **S3 Event Notification** | Suffix filter `.csv` ensures only CSV uploads trigger the pipeline |
| **CloudWatch Alarms** | DLQ message count > 0 triggers SNS alert; Lambda errors > 5% triggers investigation |
| **Region** | ap-south-1 |

## 🧩 Key Components

### S3 Event Notifications
Object-level triggers filtering by prefix/suffix that publish to SQS, SNS, or Lambda

### SQS Standard Queue
Managed message buffer decoupling S3 events from Lambda processing; at-least-once delivery

### SQS Dead-Letter Queue (DLQ)
Poison-message quarantine after maxReceiveCount failures; enables error analysis

### Lambda Event Source Mapping
Polls SQS queue in batches of 10; automatic scaling of concurrent invocations

### DynamoDB Idempotency Table
Conditional writes using message ID prevent duplicate processing on retry

### CloudWatch DLQ Alarm
Monitors `ApproximateNumberOfMessagesVisible` on DLQ; alerts on first failed message

## ⚡ Core Features

- **Fully Event-Driven** – No polling, no cron; S3 upload → SQS → Lambda fires automatically within seconds
- **Dead-Letter Queue Safety Net** – Failed messages quarantined after 3 attempts; zero data loss guarantee
- **Batch Processing** – Lambda processes up to 10 SQS messages per invocation for throughput optimization
- **Idempotent Processing** – DynamoDB conditional writes prevent duplicate records on Lambda retries
- **Suffix Filtering** – S3 notifications trigger only for `.csv` files; ignores metadata and temp uploads
- **Visibility Timeout Tuning** – 300s timeout (6× Lambda 50s timeout) prevents message reprocessing during execution
- **Operational Observability** – CloudWatch alarms on DLQ depth and Lambda error rate for proactive incident response

## 🛠️ Setup & Installation

### Prerequisites

- AWS CLI v2 configured with IAM credentials (from Project 01)
- Python 3.12+ installed locally for Lambda function development
- Sample CSV data files for testing the pipeline
- Understanding of SQS message lifecycle (send → receive → delete → DLQ)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects.git
cd project-12-event-driven-pipeline

# 2. Configure environment variables
cp .env.example .env
# Edit .env with your specific values (see Environment Variables below)
```

### Environment Variables

Create a `.env` file in the project root:

```bash
export AWS_REGION="ap-south-1"
export SOURCE_BUCKET="event-pipeline-source"
export QUEUE_NAME="event-pipeline-queue"
export DLQ_NAME="event-pipeline-dlq"
export TABLE_NAME="ProcessedRecords"
export LAMBDA_FUNCTION="event-pipeline-processor"
```

### Run Commands

Choose your platform and execute the scripts in order:

<table>
<tr><th>Step</th><th>Script</th><th>Description</th></tr>
<tr><td>🐧</td><td><code>scripts/bash/01-create-sqs.sh</code></td><td>Creates main queue with DLQ redrive policy (maxReceiveCount: 3)</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/01-create-sqs.ps1</code></td><td>Creates main queue with DLQ redrive policy (maxReceiveCount: 3)</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/02-create-dynamodb.sh</code></td><td>Creates results table with on-demand capacity and idempotency key</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/02-create-dynamodb.ps1</code></td><td>Creates results table with on-demand capacity and idempotency key</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/03-deploy-lambda.sh</code></td><td>Packages and deploys processing Lambda with SQS event source mapping</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/03-deploy-lambda.ps1</code></td><td>Packages and deploys processing Lambda with SQS event source mapping</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/04-create-s3-trigger.sh</code></td><td>Creates source bucket with event notification → SQS for .csv suffix</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/04-create-s3-trigger.ps1</code></td><td>Creates source bucket with event notification → SQS for .csv suffix</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/05-test-pipeline.sh</code></td><td>Uploads sample CSV to S3 and verifies processing in DynamoDB</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/05-test-pipeline.ps1</code></td><td>Uploads sample CSV to S3 and verifies processing in DynamoDB</td></tr>
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

- `aws s3 cp sample.csv s3://$SOURCE_BUCKET/` – Upload triggers pipeline within 5 seconds
- `aws dynamodb scan --table-name ProcessedRecords` – Verify processed records appear
- `aws sqs get-queue-attributes --attribute-names ApproximateNumberOfMessagesVisible` – Queue should be 0
- Upload malformed CSV → verify message lands in DLQ after 3 retries
- `aws cloudwatch describe-alarms --alarm-names dlq-alarm` – Confirm alarm transitions to ALARM

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
  <b>[⬅️ Previous: Project 11](../project-11-infrastructure-as-code)</b>
</div>
