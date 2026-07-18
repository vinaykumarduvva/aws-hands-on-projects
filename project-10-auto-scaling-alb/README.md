<div align="center">
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="36" height="36" style="vertical-align: middle"/> Project 10: Auto Scaling Group with Application Load Balancer</h1>

  <p><i>Implement elastic compute infrastructure using an Auto Scaling Group (ASG) behind an Application Load Balancer (ALB). This project covers launch templates, scaling policies (target tracking, step, and scheduled), health checks, sticky sessions, and cross-zone load balancing — the backbone of every highly-available AWS deployment.</i></p>

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

</div>

<br/>

<div align="center">

## 🏗️ Architecture Overview

<img src="./architecture/asg-alb-architecture.svg" alt="Auto Scaling Group with Application Load Balancer — System Architecture" width="800"/>

<p><i>▲ High-level architecture diagram showing the interaction between EC2, ALB, ASG, CloudWatch, VPC services</i></p>

</div>

## 📐 Infrastructure Specifications

| Resource | Configuration |
|:---------|:--------------|
| **Application Load Balancer** | Internet-facing; HTTP listener (80) → target group; cross-zone load balancing enabled |
| **Target Group** | Health check: HTTP:80 `/health` path; 30s interval, 5s timeout, 3 healthy/2 unhealthy thresholds |
| **Launch Template** | t2.micro; Amazon Linux 2023; user data installs httpd; instance metadata v2 enforced |
| **Auto Scaling Group** | Min: 2, Desired: 2, Max: 6; spans 2 AZs; ELB health check type (not EC2) |
| **Target Tracking Policy** | Scale out when average CPU > 70% across the group; 300s cooldown |
| **Scheduled Action** | Scale to min=4 on weekdays 09:00 UTC; scale to min=2 on weekdays 18:00 UTC |
| **SNS Notifications** | ASG lifecycle events (launch, terminate) trigger SNS → email alerts |
| **Region** | ap-south-1 (using VPC from Project 05) |

## 🧩 Key Components

### Application Load Balancer
Layer-7 load balancer with HTTP/HTTPS listeners, path-based routing, and WebSocket support

### Target Group
Logical grouping of targets (EC2 instances) with configurable health checks and deregistration delay

### Launch Template
Versioned instance configuration (AMI, instance type, security groups, user data) for ASG

### Auto Scaling Group
Fleet manager that maintains desired capacity, replaces unhealthy instances, and scales on demand

### Target Tracking Policy
Automatic scaling that maintains a specified CloudWatch metric target (e.g., CPU 70%)

### Scheduled Scaling
Cron-based scaling actions for predictable traffic patterns (business hours vs. off-hours)

## ⚡ Core Features

- **Self-Healing Infrastructure** – ASG automatically replaces instances failing ALB health checks within 90 seconds
- **Target Tracking Scaling** – Maintains 70% CPU utilization; automatically adds/removes instances as load changes
- **Scheduled Scaling** – Pre-warms capacity to min=4 before business hours; scales down to min=2 after hours
- **Cross-Zone Load Balancing** – ALB distributes traffic evenly across AZs even with unequal instance counts
- **Rolling Updates** – Launch template versioning enables zero-downtime AMI updates with instance refresh
- **Connection Draining** – 300s deregistration delay allows in-flight requests to complete before termination
- **Lifecycle Hooks** – Custom actions (warm-up scripts, log flushing) execute during launch and terminate transitions

## ✅ Free Tier Status

| Resource | Cost |
|:---------|:-----|
| **EC2 t2.micro** (ASG instances, 750 hrs/month total) | Free (12 months) |
| **ALB** | ⚠️ ~$0.0225/hr + LCU charges |
| **EBS gp3** (up to 30 GB total) | Free (12 months) |
| **CloudWatch Alarms** (first 10) | Always free |
| **SNS** (first 1,000 emails/month) | Always free |

> [!WARNING]
> **ALB is NOT included in the AWS Free Tier.** It costs approximately $0.0225/hour (~$16/month if left running). We create it, test scaling behavior, then tear it down immediately. Total exposure is **under $1.00** if you follow the cleanup steps promptly.

## 🛠️ Setup & Installation

### Prerequisites

- Completed Project 05 (Custom VPC with public subnets across 2 AZs)
- AWS CLI v2 configured with IAM credentials (from Project 01)
- Understanding of CloudWatch metrics and alarms (from Project 07)
- An SSH key pair (from Project 03) for debugging individual instances

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
cd project-10-auto-scaling-alb

# 2. Configure environment variables
cp .env.example .env
# Edit .env with your specific values (see Environment Variables below)
```

### Environment Variables

Create a `.env` file in the project root:

```bash
export AWS_REGION="ap-south-1"
export VPC_ID="vpc-xxxxxxxxx"
export SUBNET_IDS="subnet-aaa,subnet-bbb"
export KEY_NAME="my-ec2-keypair"
export AMI_ID="ami-0c55b159cbfafe1f0"
export ASG_MIN="2"
export ASG_MAX="6"
export CPU_TARGET="70"
```

### Run Commands

Choose your platform and execute the scripts in order:

| Step | Bash Script | PowerShell Script | Description |
| :---: | :--- | :--- | :--- |
| 01 | `scripts/bash/01-preflight-check.sh` | `scripts/powershell/01-preflight-check.ps1` | Verify region, identity, and key pair |
| 02 | `scripts/bash/02-setup-vpc-subnets.sh` | `scripts/powershell/02-setup-vpc-subnets.ps1` | Discover default VPC and select subnets |
| 03 | `scripts/bash/03-create-security-groups.sh` | `scripts/powershell/03-create-security-groups.ps1` | Create ALB and EC2 security groups |
| 04 | `scripts/bash/04-create-launch-template.sh` | `scripts/powershell/04-create-launch-template.ps1` | Create Launch Template with Apache User Data |
| 05 | `scripts/bash/05-create-target-group.sh` | `scripts/powershell/05-create-target-group.ps1` | Create Target Group for instances |
| 06 | `scripts/bash/06-create-alb.sh` | `scripts/powershell/06-create-alb.ps1` | Create Application Load Balancer and Listener |
| 07 | `scripts/bash/07-create-auto-scaling-group.sh` | `scripts/powershell/07-create-auto-scaling-group.ps1` | Create ASG with Target Tracking scaling |
| 08 | `scripts/bash/08-verify-and-test.sh` | `scripts/powershell/08-verify-and-test.ps1` | Verify load balancing across instances |
| 09 | `scripts/bash/09-test-auto-scaling.sh` | `scripts/powershell/09-test-auto-scaling.ps1` | SSH and run stress tool to spike CPU |
| 10 | `scripts/bash/10-simulate-failure.sh` | `scripts/powershell/10-simulate-failure.ps1` | Terminate an instance to verify self-healing |
| 11 | `scripts/bash/11-cleanup.sh` | `scripts/powershell/11-cleanup.ps1` | Teardown all resources automatically |

### 📸 Screenshots & Validation
Throughout the documentation and `images/` directory, you will find screenshots captured during the deployment process. These visual artifacts serve as verification that the UI steps were successfully executed and validate the final architecture.

## 📚 Documentation Suite

| Document | Description |
|:---------|:------------|
| 📄 [Project Overview](docs/project-overview.md) | Comprehensive project context, goals, and learning outcomes |
| 🏗️ [Architecture Details](docs/architecture.md) | Deep-dive into system design, data flow, and component interactions |
| 🚀 [Deployment Guide](docs/deployment-guide.md) | Step-by-step deployment procedures for dev, staging, and production |
| 📝 [Testing Procedures](docs/testing-procedures.md) | Validation scripts, smoke tests, and integration test suites |
| 🛠️ [Troubleshooting](docs/troubleshooting.md) | Common issues, error codes, debugging steps, and resolution guides |
| 🧹 [Cleanup Guide](docs/cleanup-guide.md) | Instructions for tearing down AWS resources to avoid charges |
| 🔐 [Security Protocols](docs/security-protocols.md) | IAM roles, security groups, encryption, and compliance controls |
| 📈 [Auto Scaling Deep Dive](docs/auto-scaling-deep-dive.md) | Scaling policies, cooldown periods, and capacity management |
| ⚖️ [Load Balancer Deep Dive](docs/load-balancer-deep-dive.md) | ALB listeners, target groups, health checks, and routing rules |

## 🤝 Contribution & Maintenance

### Testing

- `curl http://<ALB-DNS>` multiple times → verify responses come from different instance IDs
- `aws autoscaling describe-auto-scaling-groups` → verify desired=2, min=2, max=6
- Run `stress --cpu 2` on all instances → watch ASG scale out to 4+ instances within 5 minutes
- Terminate an instance manually → verify ASG launches replacement within 90 seconds
- `aws elbv2 describe-target-health` → confirm all registered targets are `healthy`

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
  <b><a href="../project-09-cicd-pipeline">⬅️ Previous: Project 09</a> &nbsp;|&nbsp; <a href="../project-11-infrastructure-as-code">Next: Project 11 ➡️</a></b>
</div>
