<div align="center">
  <img src="https://raw.githubusercontent.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/main/project-10-auto-scaling-alb/architecture/architecture.svg" alt="Auto Scaling Group with Application Load Balancer Architecture" width="820"/>
  <br/><br/>
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

  <p><b>🔗 <a href="#">Live Demo</a></b> &nbsp;·&nbsp; <b>📹 <a href="#">Video Walkthrough</a></b></p>

</div>

<br/>

<div align="center">

## 🏗️ Architecture Overview

<img src="https://raw.githubusercontent.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/main/project-10-auto-scaling-alb/architecture/architecture.svg" alt="Auto Scaling Group with Application Load Balancer — System Architecture" width="800"/>

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

## 🛠️ Setup & Installation

### Prerequisites

- Completed Project 05 (Custom VPC with public subnets across 2 AZs)
- AWS CLI v2 configured with IAM credentials (from Project 01)
- Understanding of CloudWatch metrics and alarms (from Project 07)
- An SSH key pair (from Project 03) for debugging individual instances

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

<table>
<tr><th>Step</th><th>Script</th><th>Description</th></tr>
<tr><td>🐧</td><td><code>scripts/bash/01-create-launch-template.sh</code></td><td>Creates versioned launch template with user data and IMDSv2 enforcement</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/01-create-launch-template.ps1</code></td><td>Creates versioned launch template with user data and IMDSv2 enforcement</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/02-create-alb.sh</code></td><td>Creates ALB, target group, and HTTP listener with health check configuration</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/02-create-alb.ps1</code></td><td>Creates ALB, target group, and HTTP listener with health check configuration</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/03-create-asg.sh</code></td><td>Creates ASG with multi-AZ placement, ELB health checks, and target tracking policy</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/03-create-asg.ps1</code></td><td>Creates ASG with multi-AZ placement, ELB health checks, and target tracking policy</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/04-create-scheduled-actions.sh</code></td><td>Configures business-hours scale-up and off-hours scale-down schedules</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/04-create-scheduled-actions.ps1</code></td><td>Configures business-hours scale-up and off-hours scale-down schedules</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/05-stress-test.sh</code></td><td>Generates CPU load to trigger scale-out and verify ALB distributes to new instances</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/05-stress-test.ps1</code></td><td>Generates CPU load to trigger scale-out and verify ALB distributes to new instances</td></tr>
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

This project is licensed under the **MIT License** — see the [LICENSE](../LICENSE) file for details.

### Contact & Credits

- **Author:** Vinay Kumar
- **GitHub:** [@vinay1515](https://github.com/vinay1515)
- **Repository:** [Vinay_kumar_AWS_Beginner_level_projects](https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects)

---

<div align="center">
  <b>[⬅️ Previous: Project 09](../project-09-cicd-pipeline) &nbsp;|&nbsp; [Next: Project 11 ➡️](../project-11-infrastructure-as-code)</b>
</div>
