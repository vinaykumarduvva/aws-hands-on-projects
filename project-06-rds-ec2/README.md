# Project 6 — RDS MySQL + EC2 Two-Tier Application

[![AWS](https://img.shields.io/badge/AWS-RDS%20%7C%20EC2-orange?style=flat&logo=amazon-aws)](https://aws.amazon.com/rds/)
[![Level](https://img.shields.io/badge/Level-Beginner%20→%20Intermediate-yellow?style=flat)](../README.md)
[![Free Tier](https://img.shields.io/badge/Cost-~%240.05-brightgreen?style=flat)](https://aws.amazon.com/free/)
[![Region](https://img.shields.io/badge/Region-us--east--1-blue?style=flat)](https://aws.amazon.com/about-aws/global-infrastructure/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?style=flat&logo=mysql)](https://www.mysql.com/)

---

## Overview

Deployed a production-style two-tier AWS architecture — an EC2
application server in a public subnet connecting to a managed
RDS MySQL database in private subnets, with credentials stored
securely in AWS Secrets Manager. The database is completely
isolated from the internet and accessible only through
security group chaining from the app server.

> **Real-world context:** This two-tier pattern (web/app tier +
> database tier) is the foundation of almost every web application
> running on AWS. Solutions Architects design this daily.
> Separating compute and data tiers is a core AWS best practice.

---

## Architecture Diagram

```
Internet
    │
    ▼
┌─── Internet Gateway ───────────────────────────────────────┐
│                                                            │
│   VPC: my-custom-vpc (10.0.0.0/16) — us-east-1            │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            Public Subnet A — 10.0.1.0/24             │  │
│  │                                                      │  │
│  │   ┌────────────────────────────────────────────┐     │  │
│  │   │         EC2 App Server (t2.micro)           │     │  │
│  │   │         Amazon Linux 2023                   │     │  │
│  │   │         MySQL client + Apache               │     │  │
│  │   │         Public IP: accessible from web      │     │  │
│  │   │         Security Group: ec2-app-sg          │     │  │
│  │   └──────────────────┬─────────────────────────┘     │  │
│  └─────────────────────-│────────────────────────────── ┘  │
│                         │ Port 3306 (MySQL)                 │
│                         │ ec2-app-sg → rds-sg               │
│  ┌──────────────────────│─────────────────────────────┐     │
│  │   Private Subnets    │                             │     │
│  │                      ▼                             │     │
│  │  ┌───────────────────────────────────────────┐     │     │
│  │  │      RDS MySQL 8.0 (db.t3.micro)          │     │     │
│  │  │      Identifier: myapp-database            │     │     │
│  │  │      DB: appdb                             │     │     │
│  │  │      Automated backups: 1 day              │     │     │
│  │  │      Encryption: enabled                  │     │     │
│  │  │      Public access: NO                    │     │     │
│  │  │      Security Group: rds-sg               │     │     │
│  │  └───────────────────────────────────────────┘     │     │
│  │                                                     │     │
│  │  private-subnet-a (10.0.3.0/24) — us-east-1a       │     │
│  │  private-subnet-b (10.0.4.0/24) — us-east-1b       │     │
│  └─────────────────────────────────────────────────── ┘     │
│                                                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  AWS Secrets Manager                                │   │
│  │  Secret: rds/myapp/credentials                      │   │
│  │  Stores: username, password, engine, port, dbname   │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

> See `architecture/two-tier-architecture.svg` for the visual diagram.

---

## AWS Services Used

| Service | Purpose | Free Tier |
|---|---|---|
| Amazon RDS MySQL 8.0 | Managed relational database in private subnet | 750 hrs db.t3.micro/month |
| Amazon EC2 | Application server with MySQL client | 750 hrs t2.micro/month |
| VPC + Subnets | Network isolation — public + private | Always free |
| Security Groups | ec2-app-sg + rds-sg chaining | Always free |
| AWS Secrets Manager | Secure credential storage | ~$0.40/secret/month |
| IAM Role | EC2 instance profile for SSM + Secrets Manager | Always free |
| CloudWatch | RDS metrics — CPU, connections, storage | 10 metrics free |

---

## Security Design

```
Internet
   │
   │ Port 22 (SSH)
   ▼
ec2-app-sg                 ← Your IP /32 only
   │
   │ Port 3306 (MySQL)     ← Security group chaining
   ▼
rds-sg                     ← Only accepts from ec2-app-sg
   │
   ▼
RDS MySQL                  ← Zero public internet access
```

**Key security decisions:**
- RDS has `PubliclyAccessible = false`
- RDS lives in private subnets with no route to IGW
- `rds-sg` references `ec2-app-sg` by ID — not a CIDR range
- DB credentials stored in Secrets Manager — never hardcoded
- EC2 IAM role scoped to specific secret path only

---

## Prerequisites

- AWS account with IAM admin user (Project 1 ✅)
- AWS CLI v2 on Windows (Project 1 ✅)
- Custom VPC knowledge (Project 5 ✅)
- `aws-ec2-keypair.ppk` at `C:\Users\YourName\aws-keys\`
- PuTTY installed

Verify:
```powershell
aws sts get-caller-identity
aws configure get region
aws ec2 describe-key-pairs --key-names aws-ec2-keypair `
  --query "KeyPairs[0].KeyName" --output text
```

---

## Repository Structure

```
project-06-rds-ec2/
├── README.md
├── LICENSE
├── .gitignore
├── docs/
│   ├── project-overview.md
│   ├── architecture.md
│   ├── implementation-guide.md
│   ├── security-design.md
│   ├── troubleshooting.md
│   └── cleanup-guide.md
├── scripts/
│   ├── 01-vpc-setup.ps1
│   ├── 02-security-groups.ps1
│   ├── 03-rds-subnet-group.ps1
│   ├── 04-secrets-manager.ps1
│   ├── 05-create-rds.ps1
│   ├── 06-launch-ec2.ps1
│   ├── 07-rds-connect.sql
│   ├── 08-cloudwatch-monitoring.ps1
│   ├── 09-rds-operations.ps1
│   └── 10-cleanup.ps1
├── architecture/
│   ├── architecture-diagram.svg
│   ├── network-flow.svg
│   ├── security-group-flow.svg
│   └── two-tier-architecture.svg
└── images/
    └── (console screenshots)
```

---

## Key Variables Reference

```powershell
# Save these after creation — needed for all subsequent steps
$VPC_ID           = "vpc-XXXXXXXXXXXXXXXXX"
$PUB_SUBNET_A     = "subnet-XXXXXXXXXX"
$PRI_SUBNET_A     = "subnet-XXXXXXXXXX"
$PRI_SUBNET_B     = "subnet-XXXXXXXXXX"
$EC2_SG           = "sg-XXXXXXXXXXXXXXXXX"   # ec2-app-sg
$RDS_SG           = "sg-XXXXXXXXXXXXXXXXX"   # rds-sg
$APP_INSTANCE_ID  = "i-XXXXXXXXXXXXXXXXX"
$RDS_ENDPOINT     = "myapp-database.xxxxxxxx.us-east-1.rds.amazonaws.com"
$SECRET_ARN       = "arn:aws:secretsmanager:us-east-1:ACCOUNT:secret:rds/myapp/credentials"
```

---

## Complete Setup Guide

### Part 1 — VPC Setup

```powershell
# Create VPC
$VPC_ID = aws ec2 create-vpc `
  --cidr-block 10.0.0.0/16 `
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=my-custom-vpc}]" `
  --query "Vpc.VpcId" --output text

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

# Create subnets
$PUB_SUBNET_A = aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 `
  --availability-zone us-east-1a `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-a}]" `
  --query "Subnet.SubnetId" --output text

$PRI_SUBNET_A = aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 `
  --availability-zone us-east-1a `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-a}]" `
  --query "Subnet.SubnetId" --output text

$PRI_SUBNET_B = aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.4.0/24 `
  --availability-zone us-east-1b `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-b}]" `
  --query "Subnet.SubnetId" --output text

aws ec2 modify-subnet-attribute `
  --subnet-id $PUB_SUBNET_A --map-public-ip-on-launch

# IGW and route table
$IGW_ID = aws ec2 create-internet-gateway `
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-vpc-igw}]" `
  --query "InternetGateway.InternetGatewayId" --output text

aws ec2 attach-internet-gateway `
  --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

$PUB_RT_ID = aws ec2 create-route-table `
  --vpc-id $VPC_ID `
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=public-route-table}]" `
  --query "RouteTable.RouteTableId" --output text

aws ec2 create-route `
  --route-table-id $PUB_RT_ID `
  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

aws ec2 associate-route-table `
  --route-table-id $PUB_RT_ID --subnet-id $PUB_SUBNET_A
```

### Part 2 — Security Groups

```powershell
$MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" `
  -UseBasicParsing).Content.Trim()

# EC2 app server SG
$EC2_SG = aws ec2 create-security-group `
  --group-name ec2-app-sg `
  --description "Allow SSH and HTTP for app server" `
  --vpc-id $VPC_ID --query "GroupId" --output text

aws ec2 authorize-security-group-ingress `
  --group-id $EC2_SG --protocol tcp --port 22 --cidr "$MY_IP/32"
aws ec2 authorize-security-group-ingress `
  --group-id $EC2_SG --protocol tcp --port 80 --cidr "0.0.0.0/0"

# RDS SG — chained to EC2 SG
$RDS_SG = aws ec2 create-security-group `
  --group-name rds-sg `
  --description "Allow MySQL from EC2 app server only" `
  --vpc-id $VPC_ID --query "GroupId" --output text

aws ec2 authorize-security-group-ingress `
  --group-id $RDS_SG --protocol tcp --port 3306 `
  --source-group $EC2_SG
```

### Part 3 — RDS Subnet Group

```powershell
aws rds create-db-subnet-group `
  --db-subnet-group-name rds-subnet-group `
  --db-subnet-group-description "Private subnets for RDS across two AZs" `
  --subnet-ids $PRI_SUBNET_A $PRI_SUBNET_B
```

### Part 4 — Secrets Manager

```powershell
$SECRET_ARN = aws secretsmanager create-secret `
  --name "rds/myapp/credentials" `
  --description "RDS MySQL admin credentials for Project 6" `
  --secret-string '{
    "username":"admin",
    "password":"MyDB#Secure2024!",
    "engine":"mysql",
    "port":3306,
    "dbname":"appdb"
  }' `
  --query "ARN" --output text
```

### Part 5 — RDS MySQL Instance

```powershell
aws rds create-db-instance `
  --db-instance-identifier myapp-database `
  --db-instance-class db.t3.micro `
  --engine mysql --engine-version 8.0 `
  --master-username admin `
  --master-user-password "MyDB#Secure2024!" `
  --db-name appdb `
  --vpc-security-group-ids $RDS_SG `
  --db-subnet-group-name rds-subnet-group `
  --allocated-storage 20 --storage-type gp2 `
  --no-multi-az --no-publicly-accessible `
  --backup-retention-period 1 `
  --no-deletion-protection

aws rds wait db-instance-available `
  --db-instance-identifier myapp-database

$RDS_ENDPOINT = aws rds describe-db-instances `
  --db-instance-identifier myapp-database `
  --query "DBInstances[0].Endpoint.Address" --output text
```

### Part 6 — EC2 App Server

```powershell
$APP_INSTANCE_ID = aws ec2 run-instances `
  --image-id (aws ec2 describe-images --owners amazon `
    --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" `
    --query "sort_by(Images,&CreationDate)[-1].ImageId" --output text) `
  --instance-type t2.micro `
  --key-name aws-ec2-keypair `
  --subnet-id $PUB_SUBNET_A `
  --security-group-ids $EC2_SG `
  --associate-public-ip-address `
  --user-data file://scripts/userdata-app.sh `
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=app-server}]" `
  --query "Instances[0].InstanceId" --output text

aws ec2 wait instance-status-ok --instance-ids $APP_INSTANCE_ID
```

---

## MySQL Test Queries

Run these inside MySQL after connecting:

```sql
-- Verify connection
SELECT @@hostname, @@version, DATABASE();

-- Use application database
USE appdb;

-- Create users table
CREATE TABLE users (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    email      VARCHAR(150) NOT NULL UNIQUE,
    role       VARCHAR(50)  DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (name, email, role) VALUES
  ('Vinay Kumar',   'vinay@example.com',  'admin'),
  ('AWS Engineer',  'aws@example.com',    'developer'),
  ('Cloud Learner', 'cloud@example.com',  'user');

-- Query all users
SELECT * FROM users;

-- Filter by role
SELECT name, email FROM users WHERE role = 'admin';

-- Count users
SELECT COUNT(*) AS total_users FROM users;

-- Show all tables
SHOW TABLES;

-- Confirm no public access (RDS hostname contains region)
SELECT @@hostname;
```

---

## Connectivity Verification Results

### Test 1 — EC2 to RDS Connection ✅
```
mysql -h myapp-database.xxxxxxxx.us-east-1.rds.amazonaws.com \
      -P 3306 -u admin -p
# Connected — MySQL 8.0.x prompt returned
```

### Test 2 — Database exists ✅
```sql
SHOW DATABASES;
-- appdb listed alongside system databases
```

### Test 3 — Table creation and queries ✅
```sql
SELECT * FROM users;
-- 3 rows returned: admin, developer, user roles
```

### Test 4 — RDS not publicly accessible ✅
```powershell
aws rds describe-db-instances `
  --db-instance-identifier myapp-database `
  --query "DBInstances[0].PubliclyAccessible" --output text
# Returns: False
```

---

## CloudWatch Metrics Monitored

| Metric | Namespace | What it measures |
|---|---|---|
| CPUUtilization | AWS/RDS | Database CPU usage % |
| DatabaseConnections | AWS/RDS | Active connections count |
| FreeStorageSpace | AWS/RDS | Available storage in bytes |
| ReadIOPS | AWS/RDS | Read operations per second |
| WriteIOPS | AWS/RDS | Write operations per second |
| FreeableMemory | AWS/RDS | Available RAM in bytes |

```powershell
# Check all key metrics
aws cloudwatch get-metric-statistics `
  --namespace AWS/RDS `
  --metric-name CPUUtilization `
  --dimensions Name=DBInstanceIdentifier,Value=myapp-database `
  --start-time (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ssZ") `
  --end-time (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ") `
  --period 300 --statistics Average --output table
```

---

## Cleanup — Full Teardown

```powershell
# 1. Terminate EC2
aws ec2 terminate-instances --instance-ids $APP_INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $APP_INSTANCE_ID

# 2. Delete RDS
aws rds delete-db-instance `
  --db-instance-identifier myapp-database `
  --skip-final-snapshot --delete-automated-backups
aws rds wait db-instance-deleted --db-instance-identifier myapp-database

# 3. Delete RDS subnet group
aws rds delete-db-subnet-group --db-subnet-group-name rds-subnet-group

# 4. Delete secret
aws secretsmanager delete-secret `
  --secret-id "rds/myapp/credentials" --force-delete-without-recovery

# 5. Delete security groups
aws ec2 delete-security-group --group-id $RDS_SG
aws ec2 delete-security-group --group-id $EC2_SG

# 6. Delete IAM role
aws iam remove-role-from-instance-profile `
  --instance-profile-name ec2-app-profile --role-name ec2-app-role
aws iam detach-role-policy `
  --role-name ec2-app-role `
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam delete-role-policy `
  --role-name ec2-app-role --policy-name secrets-manager-access
aws iam delete-instance-profile --instance-profile-name ec2-app-profile
aws iam delete-role --role-name ec2-app-role

# 7. VPC teardown
aws ec2 delete-subnet --subnet-id $PUB_SUBNET_A
aws ec2 delete-subnet --subnet-id $PRI_SUBNET_A
aws ec2 delete-subnet --subnet-id $PRI_SUBNET_B
aws ec2 delete-route-table --route-table-id $PUB_RT_ID
aws ec2 detach-internet-gateway `
  --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
aws ec2 delete-vpc --vpc-id $VPC_ID
```

---

## Cost Breakdown

| Resource | Rate | Duration | Cost |
|---|---|---|---|
| RDS db.t3.micro | Free tier 750 hrs | ~1 hour | $0.00 |
| RDS storage 20 GB | Free tier 20 GB | ~1 hour | $0.00 |
| EC2 t2.micro | Free tier 750 hrs | ~1 hour | $0.00 |
| Secrets Manager | $0.40/secret/month | 1 day | ~$0.01 |
| Data transfer | Minimal | — | $0.00 |
| **Total** | | | **~$0.01** |

---

## Key Concepts Learned

| Concept | Explanation |
|---|---|
| **Two-tier architecture** | Separates compute (EC2) from data (RDS). Each tier scales independently. |
| **RDS managed database** | AWS handles patching, backups, failover. You handle schema and queries. |
| **DB subnet group** | Tells RDS which subnets to use. Must span ≥ 2 AZs. |
| **Private subnet for RDS** | No public IP, no IGW route. Only reachable via VPC. |
| **Security group chaining** | rds-sg accepts 3306 from ec2-app-sg ID — not from an IP range. |
| **Secrets Manager** | Centralized credential store. Rotating secrets never requires code changes. |
| **RDS endpoint** | DNS hostname that always resolves to the current primary instance. |
| **Automated backups** | RDS takes daily snapshots automatically. Restore to any second in retention window. |
| **PubliclyAccessible=false** | RDS ignores public subnet placement — never gets a public IP. |

---

## What I Would Do Differently in Production

- Enable **Multi-AZ deployment** for automatic failover to
  a standby replica in another AZ during failures
- Enable **RDS Proxy** to pool database connections and
  handle Lambda/serverless connection bursts efficiently
- Use **IAM database authentication** instead of password
  auth — EC2 gets a token from IAM, no password needed
- Enable **automated secret rotation** in Secrets Manager
  so the DB password rotates every 30 days automatically
- Set **deletion protection = true** so no accidental
  database deletion is possible via console or CLI
- Use **Parameter Groups** to tune MySQL settings:
  `max_connections`, `innodb_buffer_pool_size`, slow query log
- Enable **Performance Insights** and **Enhanced Monitoring**
  for query-level visibility in production
- Use **Terraform** to manage the entire stack as code

---


## Next Project

**Project 7 — CloudWatch Alarms + SNS Notifications**

Build a complete monitoring and alerting system for your AWS
infrastructure — CPU alarms, billing alerts, custom dashboards,
and automated email notifications.

Services: CloudWatch · SNS · EC2 · RDS · Alarms · Dashboards

---

## Further Reading

- [Amazon RDS User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/)
- [RDS MySQL — AWS Docs](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html)
- [AWS Secrets Manager — Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
- [RDS Security — AWS Docs](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.html)
- [RDS Free Tier](https://aws.amazon.com/rds/free/)

---

*Part of the [AWS Cloud Engineering Bootcamp](../README.md)*
*14 projects · Beginner → Advanced · AWS Free Tier*