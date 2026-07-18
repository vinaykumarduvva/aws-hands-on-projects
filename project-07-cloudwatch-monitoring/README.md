<div align="center">
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="36" height="36" style="vertical-align: middle"/> Project 07: CloudWatch Monitoring, Alarms & SNS Notifications</h1>

  <p><i>Implement comprehensive AWS monitoring using CloudWatch metrics, custom dashboards, composite alarms, and SNS fan-out notifications. This project builds an observability layer that detects anomalies, triggers automated responses, and delivers real-time alerts via email and SMS — essential for production readiness.</i></p>

  <p>
    <img src="https://img.shields.io/badge/Level-Beginner/Intermediate-blue" alt="Level"/>
    <img src="https://img.shields.io/badge/Time-2--3%20Hours-orange" alt="Time"/>
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

<img src="./architecture/architecture.svg" alt="CloudWatch Monitoring, Alarms & SNS Notifications — System Architecture" width="800"/>

<p><i>▲ High-level architecture diagram showing the interaction between CloudWatch, SNS, EC2, Lambda services</i></p>

</div>

## 📐 Infrastructure Specifications

| Resource | Configuration |
|:---------|:--------------|
| **CloudWatch Alarms** | CPU > 80% (WARNING), CPU > 95% (CRITICAL), StatusCheckFailed (CRITICAL) |
| **Composite Alarm** | Triggers when both CPU > 80% AND StatusCheckFailed are in ALARM state simultaneously |
| **CloudWatch Dashboard** | Custom dashboard with CPU, Network, Disk, and StatusCheck widgets across all instances |
| **Custom Metrics** | Application-level metrics published via PutMetricData (RequestLatency, ErrorCount, QueueDepth) |
| **SNS Topics** | `ops-warnings` (email) and `ops-critical` (email + SMS); subscription confirmation required |
| **Log Group** | Application logs streamed to `/aws/ec2/app-logs` with 30-day retention |
| **Metric Filter** | Extracts `ERROR` count from log group → custom metric → alarm |
| **Region** | ap-south-1 |

## 🧩 Key Components

### CloudWatch Metric Alarms
Threshold-based alarms monitoring CPU, network, status checks with configurable evaluation periods

### Composite Alarms
Boolean logic combining multiple alarms (AND/OR/NOT) for sophisticated incident detection

### CloudWatch Dashboards
Custom visualization grids with metric widgets, text annotations, and auto-refresh

### Custom Metrics (PutMetricData)
Application-published metrics with dimensions and units for business-level monitoring

### Metric Filters
Pattern-match rules extracting structured data from CloudWatch Logs → custom metrics

### SNS Fan-Out
Multi-protocol notification topics delivering to email, SMS, Lambda, SQS, and HTTP endpoints

## ⚡ Core Features

- **Multi-Tier Alerting** – WARNING (email-only) and CRITICAL (email + SMS) severity-based notification routing
- **Composite Logic** – Alarm combining CPU + status check avoids false positives from CPU spikes alone
- **Custom Dashboard** – Real-time visualization of 8+ metrics with automatic cross-instance aggregation
- **Log-Based Metrics** – Extract ERROR counts from application logs without modifying application code
- **Auto-Scaling Integration** – Alarms can trigger Auto Scaling policies (pairs with Project 10)
- **Anomaly Detection** – ML-powered anomaly detection bands for CPU and request latency metrics
- **Cost-Zero Monitoring** – Free Tier includes 10 alarms, 3 dashboards, and 5GB log ingestion

## ✅ Free Tier Status

| Resource | Cost |
|:---------|:-----|
| **CloudWatch Alarms** (first 10) | Always free |
| **CloudWatch Dashboards** (first 3) | Always free |
| **CloudWatch Metrics** (basic, 5-min) | Always free |
| **CloudWatch Logs** (first 5 GB ingestion) | Always free |
| **SNS** (first 1,000 emails/month) | Always free |
| **EC2 t2.micro** (test instance) | Free (12 months) |

> [!TIP]
> This project is **100% free** within the AWS Free Tier. We stay well within the 10-alarm and 3-dashboard limits.

## 🛠️ Setup & Installation

### Prerequisites

- AWS CLI v2 configured with IAM credentials (from Project 01)
- At least one running EC2 instance (from Project 03) for metric collection
- Email address and phone number for SNS subscription confirmation
- Basic understanding of metric namespaces and dimensions

### Pre-flight Checks
Run these commands in PowerShell to confirm your environment is ready:
```powershell
# Confirm CLI working
aws sts get-caller-identity

# Confirm region
aws configure get region
```

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects.git
cd project-07-cloudwatch-monitoring

# 2. Configure environment variables
cp .env.example .env
# Edit .env with your specific values (see Environment Variables below)
```

### Environment Variables

Create a `.env` file in the project root:

```bash
export AWS_REGION="ap-south-1"
export INSTANCE_ID="i-xxxxxxxxxxxxxxxxx"
export ALERT_EMAIL="your-email@example.com"
export ALERT_PHONE="+91XXXXXXXXXX"
export WARNING_THRESHOLD="80"
export CRITICAL_THRESHOLD="95"
```

### Run Commands

Choose your platform and execute the scripts in order:

| Step | Bash Script                                | PowerShell Script                                 | Description                                      |
| ------| --------------------------------------------| ---------------------------------------------------| --------------------------------------------------|
| 01   | `scripts/bash/01-sns-setup.sh`             | `scripts/powershell/01-sns-setup.ps1`             | Creates SNS topic and email subscription         |
| 02   | `scripts/bash/02-launch-monitoring-ec2.sh` | `scripts/powershell/02-launch-monitoring-ec2.ps1` | Launches EC2 instance for testing                |
| 03   | `scripts/bash/03-create-ec2-alarms.sh`     | `scripts/powershell/03-create-ec2-alarms.ps1`     | Creates CPU, Network, and StatusCheck alarms     |
| 04   | `scripts/bash/04-create-rds-alarms.sh`     | `scripts/powershell/04-create-rds-alarms.ps1`     | Creates RDS CPU, Storage, and Connections alarms |
| 05   | `scripts/bash/05-create-billing-alarm.sh`  | `scripts/powershell/05-create-billing-alarm.ps1`  | Creates $5 billing threshold alarm in us-east-1  |
| 06   | `scripts/bash/06-generate-cpu-load.sh`     | `scripts/powershell/06-generate-cpu-load.ps1`     | Stresses EC2 to trigger CPU alarm                |
| 07   | `scripts/bash/07-create-dashboard.sh`      | `scripts/powershell/07-create-dashboard.ps1`      | Deploys CloudWatch multi-widget dashboard        |
| 08   | `scripts/bash/08-create-log-group.sh`      | `scripts/powershell/08-create-log-group.ps1`      | Sets up CloudWatch Logs with 7-day retention     |
| 09   | `scripts/bash/09-create-metric-filter.sh`  | `scripts/powershell/09-create-metric-filter.ps1`  | Creates filter and alarm for application errors  |
| 10   | `scripts/bash/10-test-log-events.sh`       | `scripts/powershell/10-test-log-events.ps1`       | Ingests mock logs to trigger error alarm         |
| 11   | `scripts/bash/11-verify-alarms.sh`         | `scripts/powershell/11-verify-alarms.ps1`         | Queries and validates all alarm states           |
| 12   | `scripts/bash/12-cleanup.sh`               | `scripts/powershell/12-cleanup.ps1`               | Tears down all monitoring infrastructure         |

### 📸 Screenshots & Validation
Throughout the documentation and `images/` directory, you will find screenshots captured during the deployment process. These visual artifacts serve as verification that the UI steps were successfully executed and validate the final architecture.

## 📚 Documentation Suite

| Document | Description |
|:---------|:------------|
| 📄 [Project Overview](docs/project-overview.md) | Comprehensive project context, goals, and learning outcomes |
| 🏗️ [Architecture Details](docs/architecture.md) | Deep-dive into system design, data flow, and component interactions |
| 🚀 [Deployment Guide](docs/deployment-guide.md) | Step-by-step deployment procedures for dev, staging, and production |
| 🔐 [Security Protocols](docs/security-protocols.md) | IAM policies, encryption, network security, and compliance controls |
| 🧪 [Testing Procedures](docs/testing-procedures.md) | Validation scripts, smoke tests, and integration test suites |
| 🛠️ [Troubleshooting](docs/troubleshooting.md) | Common issues, error codes, debugging steps, and resolution guides |
| 🧹 [Cleanup Guide](docs/cleanup-guide.md) | Instructions for tearing down AWS resources to avoid charges |
| 🔔 [CloudWatch Alarms](docs/cloudwatch-alarms.md) | Alarm configuration, thresholds, evaluation periods, and actions |
| 📊 [Dashboards](docs/dashboards.md) | CloudWatch dashboard design, widget configuration, and layout |
| 📝 [Logs & Metric Filters](docs/logs-and-metric-filters.md) | Log group setup, metric filter patterns, and custom metric creation |
| 📈 [Monitoring Strategy](docs/monitoring-strategy.md) | Overall monitoring philosophy, alerting tiers, and escalation paths |

## 🤝 Contribution & Maintenance

### Testing

- `aws cloudwatch describe-alarms` – Verify all alarms exist with correct thresholds
- Run `stress --cpu 2 --timeout 300` on EC2 → watch alarm transition to ALARM state
- Check email/SMS inbox for SNS notification delivery within 1–2 minutes
- `aws cloudwatch get-dashboard --dashboard-name ops-dashboard` – Validate dashboard JSON
- `aws logs put-log-events` with ERROR message → verify metric filter increments custom metric

### Deployment

For full production deployment procedures, see the [Deployment Guide](docs/deployment-guide.md).

### Contributing

1. **Fork** the repository and create a feature branch (`git checkout -b feature/amazing-feature`)
2. **Commit** your changes (`git commit -m "Add amazing feature"`)
3. **Push** to the branch (`git push origin feature/amazing-feature`)
4. **Open** a Pull Request with a detailed description
5. Ensure all scripts exist in **both** `scripts/powershell/` and `scripts/bash/`

### License

This project is licensed under the **MIT License** — see the [LICENSE](./LICENSE) file for details.

### Contact & Credits

- **Author:** Vinay Kumar Duvva
- **GitHub:** [@vinaykumarduvva]( https://github.com/vinaykumarduvva)
- **Repository:** [aws-hands-on-projects]( https://github.com/vinaykumarduvva/aws-hands-on-projects)
---

<div align="center">
  <b><a href="../project-06-rds-ec2">⬅️ Previous: Project 06</a> &nbsp;|&nbsp; <a href="../project-08-serverless-rest-api">Next: Project 08 ➡️</a></b>
</div>
