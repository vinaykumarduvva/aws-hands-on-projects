<div align="center">
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="36" height="36" style="vertical-align: middle"/> Project 06: RDS MySQL + EC2 Two-Tier Web Application</h1>

  <p><i>Deploy a managed MySQL database in private subnets and connect it to an EC2 application server in a public subnet — building a real two-tier architecture that separates the web/app layer from the data layer. This is the most common pattern in production web applications, covering DB subnet groups, security group chaining, automated backups, Secrets Manager credential storage, and CloudWatch monitoring.</i></p>

  <p>
    <img src="https://img.shields.io/badge/Level-Beginner%20→%20Intermediate-blue" alt="Level"/>
    <img src="https://img.shields.io/badge/Time-4--5%20Hours-orange" alt="Time"/>
    <img src="https://img.shields.io/badge/Cost-$0.00--$0.05%20(Free%20Tier)-brightgreen" alt="Cost"/>
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

<img src="./architecture/architecture-diagram.svg" alt="RDS MySQL + EC2 Two-Tier Web Application — System Architecture" width="800"/>

<p><i>▲ High-level architecture diagram showing EC2 in a public subnet connecting to RDS MySQL in private subnets via security group chaining</i></p>

</div>

```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
┌─────────────────────────────────────────────────┐
│              VPC — 10.0.0.0/16                  │
│                                                 │
│  ┌──────────────────────────────────────────┐   │
│  │         Public Subnet A (10.0.1.0/24)    │   │
│  │                                          │   │
│  │   ┌──────────────────────────────────┐   │   │
│  │   │  EC2 App Server (t2.micro)       │   │   │
│  │   │  Amazon Linux 2023               │   │   │
│  │   │  MySQL client installed          │   │   │
│  │   │  Public IP: accessible from web  │   │   │
│  │   └────────────────┬─────────────────┘   │   │
│  └────────────────────│─────────────────────┘   │
│                       │ Port 3306 (MySQL)        │
│  ┌────────────────────│─────────────────────┐   │
│  │  Private Subnets   │                     │   │
│  │  ┌─────────────────▼──────────────┐      │   │
│  │  │  RDS MySQL (db.t3.micro)       │      │   │
│  │  │  Multi-AZ subnet group         │      │   │
│  │  │  Automated backups enabled     │      │   │
│  │  │  No public access              │      │   │
│  │  └────────────────────────────────┘      │   │
│  │  private-subnet-a    private-subnet-b    │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

## 📐 Infrastructure Specifications

| Resource | Configuration |
|:---------|:-------------|
| **VPC** | `10.0.0.0/16` CIDR block; DNS hostnames and DNS resolution enabled |
| **Public Subnet A** | `10.0.1.0/24` in us-east-1a; auto-assign public IP enabled; routes to IGW |
| **Public Subnet B** | `10.0.2.0/24` in us-east-1b; auto-assign public IP enabled; routes to IGW |
| **Private Subnet A** | `10.0.3.0/24` in us-east-1a; no public IP; local routes only |
| **Private Subnet B** | `10.0.4.0/24` in us-east-1b; no public IP; local routes only |
| **Internet Gateway** | Attached to VPC; public route table has `0.0.0.0/0 → IGW` |
| **RDS Instance** | `db.t3.micro` (Free Tier); MySQL 8.0; 20 GiB gp2 storage; single-AZ |
| **DB Subnet Group** | Private subnets across 2 AZs (`us-east-1a` + `us-east-1b`); no public accessibility |
| **EC2 App Server** | `t2.micro`; Amazon Linux 2023; MySQL client + Apache httpd installed via user data |
| **Security Group (EC2)** | Inbound: SSH (22) from your IP, HTTP (80) from anywhere; outbound: all traffic |
| **Security Group (RDS)** | Inbound: MySQL (3306) from `ec2-app-sg` only; no internet access |
| **Secrets Manager** | RDS admin credentials stored at `rds/myapp/credentials`; JSON format |
| **IAM Role** | `ec2-app-role` with SSM + Secrets Manager + RDS describe permissions |
| **Automated Backups** | 1-day retention; daily automated snapshots |
| **Region** | us-east-1 (multi-AZ: 1a + 1b) |

## 🧩 Key Components

### RDS MySQL 8.0
Managed relational database with automated patching, backups, point-in-time recovery, and storage encryption — deployed in private subnets with no public endpoint

### EC2 App Server
Amazon Linux 2023 application server in the public subnet running Apache httpd with MySQL CLI client installed — connects to RDS via private DNS endpoint

### DB Subnet Group
Logical grouping of `private-subnet-a` and `private-subnet-b` across two AZs — RDS requires this for high-availability placement even for single-AZ instances

### Security Group Chaining
`rds-sg` allows MySQL (3306) **only** from `ec2-app-sg` — not from CIDR blocks. The database is completely unreachable from the internet or any other EC2 instance

### Secrets Manager Integration
Secure credential storage at `rds/myapp/credentials` — EC2 retrieves DB credentials at runtime via IAM role, never hardcoded in code or config files

### IAM Instance Profile
`ec2-app-role` attached via `ec2-app-profile` with least-privilege policies for SSM Session Manager, Secrets Manager read access (scoped to `rds/myapp/*`), and RDS describe permissions

### CloudWatch Monitoring
Built-in RDS metrics for CPU utilization, database connections, free storage space, read/write IOPS — accessible via console Monitoring tab or CLI

## ⚡ Core Features

- **Network Isolation** – RDS in private subnets with no route to IGW; only reachable from EC2's security group (no public endpoint)
- **Security Group Chaining** – RDS accepts connections only from instances carrying `ec2-app-sg`; no CIDR-based rules
- **Credential Security** – Secrets Manager stores DB password securely; EC2 retrieves it at runtime via IAM role
- **Automated Backups** – Daily RDS snapshots with 1-day retention; supports point-in-time recovery
- **Storage Encryption** – RDS storage encrypted at rest with default AWS KMS key
- **Multi-AZ Ready** – Architecture supports one-click promotion to multi-AZ synchronous replication
- **CloudWatch Metrics** – Built-in monitoring for CPU, connections, storage, IOPS without additional setup
- **Least-Privilege IAM** – EC2 instance role scoped to specific Secrets Manager paths and read-only RDS operations

## 🔄 RDS vs Self-Managed MySQL on EC2

| Feature | RDS MySQL | MySQL on EC2 |
|:--------|:----------|:-------------|
| OS patching | AWS handles | You handle |
| DB engine updates | AWS handles | You handle |
| Automated backups | Built-in (1–35 days) | You build it |
| Multi-AZ failover | One checkbox | Complex setup |
| Monitoring | CloudWatch built-in | Manual setup |
| Storage scaling | Auto-scaling option | Manual |
| Cost | Higher base | Lower base |
| Control | Less | Full |
| Recommended for | Production | Dev/test or special needs |

## ✅ Free Tier Status

| Resource | Free Tier | Notes |
|:---------|:----------|:------|
| **RDS db.t3.micro** | 750 hrs/month free (12 months) | Must use `db.t3.micro` |
| **RDS storage** | 20 GB free (12 months) | gp2 only |
| **RDS backups** | 20 GB free | Automated backups |
| **EC2 t2.micro** | 750 hrs/month free | App server |
| **Secrets Manager** | $0.40/secret/month | ⚠️ Small cost — ~$0.01 for this project |

> [!WARNING]
> **Always stop or delete RDS when done.** A running RDS instance costs money even when idle if you exhaust Free Tier hours. RDS cannot be "stopped" permanently — only for 7 days at a time. We delete it after the project. **Cost estimate: $0.00 – $0.05** (Secrets Manager + data transfer).

## 🎯 Learning Objectives

- Understand the difference between self-managed vs RDS managed databases
- Create an RDS subnet group spanning multiple AZs
- Launch an RDS MySQL instance in private subnets
- Connect EC2 to RDS using security group chaining
- Query a MySQL database from an EC2 instance via CLI
- Understand RDS automated backups, storage, and parameter groups
- Store and retrieve database credentials using AWS Secrets Manager
- Monitor RDS performance using CloudWatch metrics
- Manage RDS via console and AWS CLI

## 🛠️ Setup & Installation

### Prerequisites

- AWS CLI v2 configured with IAM credentials (from Project 01)
- Key pair `aws-ec2-keypair` created (from Project 03)
- PuTTY or SSH client for connecting to EC2
- Basic SQL knowledge (CREATE TABLE, INSERT, SELECT)

### Pre-Flight Checks

```powershell
# Confirm CLI working
aws sts get-caller-identity

# Confirm region
aws configure get region
# Expected: us-east-1

# Check key pair exists
aws ec2 describe-key-pairs --key-names aws-ec2-keypair `
  --query "KeyPairs[0].KeyName" --output text
# Expected: aws-ec2-keypair
```

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects.git
cd project-06-rds-ec2

# 2. Configure environment variables
cp .env.example .env
# Edit .env with your specific values (see Environment Variables below)
```

### Environment Variables

Create a `.env` file in the project root:

```bash
export AWS_REGION="us-east-1"
export VPC_CIDR="10.0.0.0/16"
export DB_INSTANCE_ID="myapp-database"
export DB_MASTER_USER="admin"
export DB_NAME="appdb"
export KEY_PAIR_NAME="aws-ec2-keypair"
```

### Run Commands

Choose your platform and execute the scripts in order:

<table>
<tr><th>Order</th><th>Step</th><th>Bash Script (🐧)</th><th>PowerShell Script (🖥️)</th><th>Description</th></tr>
<tr><td>1</td><td>VPC Setup</td><td><code>scripts/bash/01-vpc-setup.sh</code></td><td><code>scripts/powershell/01-vpc-setup.ps1</code></td><td>Create VPC, subnets, IGW, and route tables</td></tr>
<tr><td>2</td><td>Security Groups</td><td><code>scripts/bash/02-security-groups.sh</code></td><td><code>scripts/powershell/02-security-groups.ps1</code></td><td>Create ec2-app-sg and rds-sg with chained rules</td></tr>
<tr><td>3</td><td>RDS Subnet Group</td><td><code>scripts/bash/03-rds-subnet-group.sh</code></td><td><code>scripts/powershell/03-rds-subnet-group.ps1</code></td><td>Create DB subnet group spanning private subnets</td></tr>
<tr><td>4</td><td>Secrets Manager</td><td><code>scripts/bash/04-secrets-manager.sh</code></td><td><code>scripts/powershell/04-secrets-manager.ps1</code></td><td>Store DB credentials securely in Secrets Manager</td></tr>
<tr><td>5</td><td>Launch RDS</td><td><code>scripts/bash/05-create-rds.sh</code></td><td><code>scripts/powershell/05-create-rds.ps1</code></td><td>Create RDS MySQL instance (5-10 min wait)</td></tr>
<tr><td>6</td><td>Launch EC2</td><td><code>scripts/bash/06-launch-ec2.sh</code></td><td><code>scripts/powershell/06-launch-ec2.ps1</code></td><td>Launch app server with MySQL client + Apache</td></tr>
<tr><td>7</td><td>Connect & Query</td><td colspan="2"><code>scripts/powershell/07-rds-connect.sql</code></td><td>SQL commands to run from EC2 MySQL session</td></tr>
<tr><td>8</td><td>CloudWatch</td><td><code>scripts/bash/08-cloudwatch-monitoring.sh</code></td><td><code>scripts/powershell/08-cloudwatch-monitoring.ps1</code></td><td>Query RDS metrics (CPU, connections, storage)</td></tr>
<tr><td>9</td><td>RDS Operations</td><td><code>scripts/bash/09-rds-operations.sh</code></td><td><code>scripts/powershell/09-rds-operations.ps1</code></td><td>Snapshots, stop/start, modify instance</td></tr>
<tr><td>10</td><td>Cleanup</td><td><code>scripts/bash/10-cleanup.sh</code></td><td><code>scripts/powershell/10-cleanup.ps1</code></td><td>Delete all resources in dependency order</td></tr>
</table>

### 🧹 Cleanup

> [!CAUTION]
> **Run cleanup in the exact order shown.** AWS resources have dependencies — deleting in the wrong order produces `DependencyViolation` errors. See the [Cleanup Guide](docs/cleanup-guide.md) for the complete sequence with variable recovery steps.

```powershell
# Quick cleanup (runs all 10 steps in order)
# See scripts/powershell/10-cleanup.ps1 for the full script
# or docs/cleanup-guide.md for step-by-step with explanations
```

## 📚 Documentation Suite

| Document | Description |
|:---------|:------------|
| 📄 [Project Overview](docs/project-overview.md) | Comprehensive project context, goals, learning outcomes, and AWS services used |
| 🏗️ [Architecture Details](docs/architecture.md) | Deep-dive into two-tier design, data flow, subnet layout, and component interactions |
| 🚀 [Deployment Guide](docs/deployment-guide.md) | Step-by-step deployment procedures with console and CLI instructions for all 10 parts |
| 🔐 [Security Protocols](docs/security-protocols.md) | Security group chaining, network isolation, Secrets Manager, IAM least-privilege analysis |
| 🧪 [Testing Procedures](docs/testing-procedures.md) | Validation scripts, connectivity tests, MySQL queries, and CloudWatch metric verification |
| 🛠️ [Troubleshooting](docs/troubleshooting.md) | Common issues, error codes, debugging steps, and resolution guides |
| 🧹 [Cleanup Guide](docs/cleanup-guide.md) | Ordered resource deletion with dependency explanations and variable recovery |
| 🔑 [IAM Policy Notes](docs/iam-policy-notes.md) | Detailed IAM role analysis, trust policies, inline policies, and least-privilege breakdown |
| 🔒 [Security Design](docs/security-design.md) | Four-layer defense-in-depth model with threat analysis |
| 📋 [Implementation Guide](docs/implementation-guide.md) | Complete walkthrough of all 10 parts with checkpoints and time estimates |

## 🤝 Contribution & Maintenance

### Testing

- `mysql -h <rds-endpoint> -u admin -p appdb -e 'SHOW TABLES;'` – Verify database connectivity from EC2
- `curl http://<EC2-public-IP>` – Confirm Apache is serving the status page
- `aws rds describe-db-instances --db-instance-identifier myapp-database` – Validate RDS configuration
- `aws secretsmanager get-secret-value --secret-id rds/myapp/credentials` – Confirm secret exists
- Stop EC2, attempt direct RDS connection from internet – Should fail (no public access)
- `SELECT @@hostname;` from MySQL prompt – Confirms connection is to RDS, not local

### Deployment

For full production deployment procedures, see the [Deployment Guide](docs/deployment-guide.md).

### Contributing

1. **Fork** the repository and create a feature branch (`git checkout -b feature/amazing-feature`)
2. **Commit** your changes (`git commit -m "Add amazing feature"`)
3. **Push** to the branch (`git push origin feature/amazing-feature`)
4. **Open** a Pull Request with a detailed description
5. Ensure all scripts exist in **both** `scripts/powershell/` and `scripts/bash/`

### License

This project is licensed under the **MIT License** — see the [LICENSE](../project-06-rds-ec2/LICENSE) file for details.

### Contact & Credits

- **Author:** Vinay Kumar
- **GitHub:** [@vinay1515](https://github.com/vinay1515)
- **Repository:** [Vinay_kumar_AWS_Beginner_level_projects](https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects)

---

<div align="center">
  <b><a href="../project-05-Custom-VPC">⬅️ Previous: Project 05</a> &nbsp;|&nbsp; <a href="../project-07-cloudwatch-monitoring">Next: Project 07 ➡️</a></b>
</div>
