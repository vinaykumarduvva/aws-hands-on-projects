<div align="center">
  <img src="https://raw.githubusercontent.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/main/project-12-event-driven-pipeline/architecture/architecture.svg" alt="Project 12 Architecture" width="800">
  
  <br/>
  
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="32" height="32" style="vertical-align: middle"/> Project 12: Event-Driven Pipeline</h1>

  <p><b>Intermediate Level &nbsp; • &nbsp; 4-5 Hours &nbsp; • &nbsp; Cost: $0.00 (Free Tier)</b></p>
  
  <p>
    <a href="#purpose">Purpose</a> • 
    <a href="#architecture">Architecture</a> • 
    <a href="#deployment">Deployment</a> • 
    <a href="#testing">Testing</a> • 
    <a href="#docs">Docs</a>
  </p>
</div>

<br/>

## 🎯 Purpose
This project builds a fully decoupled, event-driven data processing pipeline. When a file is uploaded to **Amazon S3**, it automatically triggers an event notification sent to an **Amazon SQS** queue, which is then processed asynchronously by an **AWS Lambda** function. 

This architecture pattern is heavily used in production environments for:
- 📊 ETL data processing pipelines
- 🖼️ Image and video rendering
- 📝 Log aggregation and analysis
- 📥 Asynchronous data ingestion at massive scale

## 🚀 Learning Objectives
- **Event-Driven Architectures:** Understand how to decouple systems using asynchronous messaging.
- **S3 Event Notifications:** Trigger workflows natively based on `ObjectCreated` events.
- **Amazon SQS Deep Dive:** Create Standard queues and configure Dead Letter Queues (DLQ).
- **Lambda Event Source Mapping:** Efficiently poll queues, parse messages, and process batch files.
- **Failure Handling:** Understand message visibility timeout, retries, and error isolation.
- **CloudWatch Monitoring:** Track lambda invocations and queue depths end-to-end.

## 🏗️ Architecture Design

The solution implements a robust retry mechanism and decoupled logic:
1. **Developer / App** uploads a `.csv` or `.json` file to the Source S3 Bucket.
2. **S3** fires an `ObjectCreated:*` notification payload to SQS.
3. **SQS Queue** holds the message securely. It provides a visibility timeout and retention period.
4. **Lambda** uses an event source mapping to poll the queue, parses the message to find the S3 Key, downloads the file, processes it, and writes the output.
5. **Output S3 Bucket** receives the summarized processing results.
6. **DLQ** automatically catches any messages that Lambda fails to process after 3 retries.

## 🛠️ AWS Services Utilized

| Service | Role in Pipeline | Configuration |
|---------|------------------|---------------|
| **S3** (Source) | Event Trigger | Filters on `uploads/` prefix and `.csv`/`.json` |
| **SQS** | Message Broker | 30s visibility timeout, 4-day retention |
| **SQS (DLQ)** | Error Handling | Receives messages after 3 failed attempts |
| **Lambda** | Consumer | Python 3.12, 256MB memory, 60s timeout |
| **S3** (Target) | Output Storage | Receives JSON computation summaries |
| **IAM** | Security | Least privilege role for S3 Read/Write and SQS polling |
| **CloudWatch** | Observability | Tracks execution logs and errors |

## 📚 Documentation
For an in-depth understanding, please refer to the detailed guides inside the `docs/` folder:

- 📄 [Project Overview](docs/project-overview.md)
- 🏗️ [Architecture Details](docs/architecture.md)
- 🚀 [Deployment Guide](docs/deployment-guide.md)
- 🔐 [Security Protocols](docs/security-protocols.md)
- 🧪 [Testing Procedures](docs/testing-procedures.md)
- 🛠️ [Troubleshooting](docs/troubleshooting.md)
- 🧹 [Cleanup Guide](docs/cleanup-guide.md)

## 💻 Automation Scripts
This project contains ready-to-run automation scripts for both **PowerShell** and **Bash**.
These scripts handle everything from provisioning buckets and queues to deploying Lambda and cleaning up.

- 🖥️ **Windows Users:** Use `scripts/powershell/`
- 🐧 **Linux/Mac Users:** Use `scripts/bash/`

## 💰 Free Tier Status
This project utilizes the **AWS Free Tier** exclusively. As long as your account is eligible and you clean up resources promptly, it will cost exactly **$0.00**.
- **S3:** Less than a few KBs used.
- **SQS:** Far below the 1M requests per month limit.
- **Lambda:** Far below the 1M invocations per month limit.

## 📜 License
Distributed under the MIT License. See [LICENSE](LICENSE) for more information.
