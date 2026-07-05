<div align="center">
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="36" height="36" style="vertical-align: middle"/> Project 06: RDS MySQL + EC2 Two-Tier Web Application</h1>

  <p><i>Build a classic two-tier architecture with an Amazon EC2 web server in a public subnet connecting to an Amazon RDS MySQL database in a private subnet. This project covers DB subnet groups, parameter groups, automated backups, multi-AZ deployment options, and connection pooling best practices.</i></p>

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

<img src="./architecture/architecture-diagram.svg" alt="RDS MySQL + EC2 Two-Tier Web Application — System Architecture" width="800"/>

<p><i>▲ High-level architecture diagram showing the interaction between RDS, EC2, VPC, Secrets Manager services</i></p>

</div>

## 📐 Infrastructure Specifications

| Resource | Configuration |
|:---------|:--------------|
| **RDS Instance** | db.t3.micro (Free Tier); MySQL 8.0; 20 GiB gp3 storage; single-AZ (multi-AZ optional) |
| **DB Subnet Group** | Private subnets across 2 AZs (from Project 05 VPC); no public accessibility |
| **Security Group (DB)** | Inbound: MySQL (3306) from EC2 security group only; no internet access |
| **Security Group (EC2)** | Inbound: HTTP (80), SSH (22 from your IP); outbound: all traffic |
| **Parameter Group** | Custom MySQL 8.0 parameter group: `character_set_server=utf8mb4`, `max_connections=100` |
| **Automated Backups** | 7-day retention window; daily snapshot during 03:00–04:00 UTC maintenance window |
| **Secrets Manager** | RDS master credentials stored and auto-rotated every 30 days |
| **Region** | ap-south-1 (using VPC from Project 05) |

## 🧩 Key Components

### RDS MySQL 8.0
Managed relational database with automated patching, backups, and point-in-time recovery

### EC2 Web Server
Apache/PHP application server in public subnet; connects to RDS via private DNS endpoint

### DB Subnet Group
Logical grouping of private subnets across AZs for RDS high-availability placement

### Custom Parameter Group
Tuned MySQL settings: UTF-8 character set, connection limits, query cache configuration

### Secrets Manager Integration
Secure credential storage with automatic 30-day rotation and Lambda-based rotation function

### Automated Backups
Daily EBS snapshots with 7-day retention; supports point-in-time recovery to any second

## ⚡ Core Features

- **Network Isolation** – RDS in private subnet; only reachable from EC2's security group (no public endpoint)
- **Credential Rotation** – Secrets Manager auto-rotates MySQL master password every 30 days
- **Point-in-Time Recovery** – Restore database to any second within the 7-day backup retention window
- **Parameterized Tuning** – Custom parameter group optimizes character encoding, connections, and timeouts
- **Connection Pooling** – PHP application uses persistent connections to avoid TCP handshake overhead
- **Multi-AZ Ready** – Architecture supports one-click promotion to multi-AZ synchronous replication
- **Monitoring Dashboard** – CloudWatch metrics for CPU, connections, read/write IOPS, and replication lag

## 🛠️ Setup & Installation

### Prerequisites

- Completed Project 05 (Custom VPC with public and private subnets)
- AWS CLI v2 configured with IAM credentials (from Project 01)
- MySQL client (`mysql` CLI) for testing database connectivity
- Basic SQL knowledge (CREATE TABLE, INSERT, SELECT)

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
export AWS_REGION="ap-south-1"
export VPC_ID="vpc-xxxxxxxxx"
export DB_INSTANCE_ID="my-rds-mysql"
export DB_MASTER_USER="admin"
export DB_NAME="myappdb"
```

### Run Commands

Choose your platform and execute the scripts in order:

<table>
<tr><th>Step</th><th>Script</th><th>Description</th></tr>
<tr><td>🐧</td><td><code>scripts/bash/01-vpc-setup.sh</code></td><td>Execute Vpc setup</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/01-vpc-setup.ps1</code></td><td>Execute Vpc setup</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/02-security-groups.sh</code></td><td>Execute Security groups</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/02-security-groups.ps1</code></td><td>Execute Security groups</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/03-rds-subnet-group.sh</code></td><td>Execute Rds subnet group</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/03-rds-subnet-group.ps1</code></td><td>Execute Rds subnet group</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/04-secrets-manager.sh</code></td><td>Execute Secrets manager</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/04-secrets-manager.ps1</code></td><td>Execute Secrets manager</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/05-create-rds.sh</code></td><td>Execute Create rds</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/05-create-rds.ps1</code></td><td>Execute Create rds</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/06-launch-ec2.sh</code></td><td>Execute Launch ec2</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/06-launch-ec2.ps1</code></td><td>Execute Launch ec2</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/08-cloudwatch-monitoring.sh</code></td><td>Execute Cloudwatch monitoring</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/08-cloudwatch-monitoring.ps1</code></td><td>Execute Cloudwatch monitoring</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/09-rds-operations.sh</code></td><td>Execute Rds operations</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/09-rds-operations.ps1</code></td><td>Execute Rds operations</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/10-cleanup.sh</code></td><td>Execute Cleanup</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/10-cleanup.ps1</code></td><td>Execute Cleanup</td></tr>
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

- `mysql -h <rds-endpoint> -u admin -p myappdb -e 'SHOW TABLES;'` – Verify database connectivity
- `curl http://<EC2-public-IP>/db-test.php` – Confirm web app reads from RDS successfully
- `aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID` – Validate configuration
- `aws secretsmanager get-secret-value --secret-id rds-credentials` – Confirm secret exists
- Stop EC2, attempt direct RDS connection from internet – Should fail (no public access)

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
  <b>[⬅️ Previous: Project 05](../project-05-Custom-VPC) &nbsp;|&nbsp; [Next: Project 07 ➡️](../project-07-cloudwatch-monitoring)</b>
</div>
