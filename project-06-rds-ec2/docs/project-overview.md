# Project 06 Overview — RDS MySQL + EC2 Two-Tier Application

## 🎯 Business Problem

Modern web applications require a clear separation between the application layer and the data layer. Running a database directly on an EC2 instance creates operational burden — you must handle OS patching, database engine updates, backup strategies, failover mechanisms, and storage management manually. Organizations need a managed database solution that eliminates undifferentiated heavy lifting while maintaining security, reliability, and cost-efficiency.

## 🚀 Solution

Deploy an Amazon RDS MySQL instance in private subnets (no internet access) connected to an EC2 application server in a public subnet via security group chaining. This two-tier architecture is the most common pattern in production web applications and provides:

- **Managed database operations** — AWS handles patching, backups, and failover
- **Network isolation** — Database unreachable from the internet
- **Secure credential management** — AWS Secrets Manager stores DB passwords
- **Monitoring out of the box** — CloudWatch metrics for CPU, connections, and storage

## 📋 AWS Services Used

| Service | Role |
|:--------|:-----|
| **RDS** | Managed MySQL database in private subnets |
| **EC2** | Application server in public subnet — connects to RDS |
| **VPC** | Custom VPC with public and private subnets across 2 AZs |
| **Security Groups** | Layered access control — EC2 → RDS only (security group chaining) |
| **Secrets Manager** | Securely store and retrieve DB credentials |
| **CloudWatch** | RDS performance metrics (CPU, connections, storage, IOPS) |
| **IAM** | EC2 instance profile for SSM + Secrets Manager access |

## 🎓 Learning Objectives

By completing this project, you will be able to:

1. **Understand managed vs self-managed databases** — Know when to use RDS vs MySQL on EC2
2. **Create an RDS subnet group** — Configure a subnet group spanning multiple AZs
3. **Launch an RDS MySQL instance** — Deploy a Free Tier MySQL instance in private subnets
4. **Implement security group chaining** — Allow EC2 → RDS connectivity without CIDR rules
5. **Query MySQL from EC2 via CLI** — Connect using the MySQL client and run SQL commands
6. **Manage credentials securely** — Store and retrieve passwords using Secrets Manager
7. **Configure automated backups** — Understand backup retention, snapshots, and point-in-time recovery
8. **Monitor RDS with CloudWatch** — Query CPU utilization, connection count, and free storage
9. **Perform RDS operations** — Create snapshots, stop/start instances, and modify configuration

## 📊 Project Metrics

| Metric | Value |
|:-------|:------|
| **Estimated time** | 4–5 hours (including wait times) |
| **Difficulty** | Beginner → Intermediate |
| **AWS resources created** | ~15 (VPC, subnets, IGW, route tables, SGs, RDS, EC2, IAM role, secret) |
| **Scripts provided** | 10 (Bash + PowerShell for each step) |
| **Best-case cost** | $0.00 |
| **Worst-case cost** | ~$0.05 (Secrets Manager + data transfer) |

## 🔗 Prerequisites

| Prerequisite | Source |
|:-------------|:-------|
| AWS CLI v2 configured | Project 01 |
| IAM user with admin access | Project 01 |
| SSH key pair (`aws-ec2-keypair`) | Project 03 |
| Understanding of VPC concepts | Project 05 |
| Basic SQL knowledge | External |

## 📁 Project Structure

```
project-06-rds-ec2/
├── README.md                         # Main project documentation
├── .env.example                      # Environment variable template
├── .gitignore                        # Git exclusion rules
├── LICENSE                           # MIT license
├── architecture/
│   ├── architecture-diagram.svg      # Main architecture diagram
│   ├── two-tier-architecture.svg     # Two-tier layout diagram
│   ├── network-flow.svg              # Network traffic flow diagram
│   └── security-group-flow.svg       # Security group chaining diagram
├── docs/
│   ├── project-overview.md           # This file
│   ├── architecture.md               # Architecture deep-dive
│   ├── deployment-guide.md           # Step-by-step deployment
│   ├── implementation-guide.md       # Complete walkthrough with checkpoints
│   ├── security-protocols.md         # Security analysis
│   ├── security-design.md            # Four-layer defense model
│   ├── iam-policy-notes.md           # IAM role and policy details
│   ├── testing-procedures.md         # Validation and testing
│   ├── troubleshooting.md            # Common issues and fixes
│   └── cleanup-guide.md              # Ordered resource deletion
├── images/
│   ├── 01-vpc-overview.png           # VPC dashboard screenshot
│   ├── 02-subnets-created.png        # Subnet listing
│   ├── ...                           # (20 screenshots total)
│   └── 20-cleanup-complete.png       # Final cleanup verification
└── scripts/
    ├── bash/
    │   ├── 01-vpc-setup.sh           # Create VPC infrastructure
    │   ├── 02-security-groups.sh     # Create security groups
    │   ├── 03-rds-subnet-group.sh    # Create DB subnet group
    │   ├── 04-secrets-manager.sh     # Store credentials
    │   ├── 05-create-rds.sh          # Launch RDS MySQL
    │   ├── 06-launch-ec2.sh          # Launch EC2 app server
    │   ├── 08-cloudwatch-monitoring.sh # Query CloudWatch metrics
    │   ├── 09-rds-operations.sh      # Snapshot, stop/start, modify
    │   └── 10-cleanup.sh             # Full resource cleanup
    └── powershell/
        ├── 01-vpc-setup.ps1
        ├── 02-security-groups.ps1
        ├── 03-rds-subnet-group.ps1
        ├── 04-secrets-manager.ps1
        ├── 05-create-rds.ps1
        ├── 06-launch-ec2.ps1
        ├── 07-rds-connect.sql        # SQL commands for MySQL session
        ├── 08-cloudwatch-monitoring.ps1
        ├── 09-rds-operations.ps1
        └── 10-cleanup.ps1
```