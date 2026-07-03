# Architecture — RDS MySQL + EC2 Two-Tier Application

## Full Architecture Diagram

```
                          ┌──────────────────┐
                          │    Your Browser   │
                          │  (or SSH client)  │
                          └────────┬─────────┘
                                   │ HTTP :80 / SSH :22
                                   ▼
                          ┌──────────────────┐
                          │ Internet Gateway  │
                          │   (my-vpc-igw)   │
                          └────────┬─────────┘
                                   │
          ┌────────────────────────▼──────────────────────────┐
          │                VPC — 10.0.0.0/16                  │
          │                (my-custom-vpc)                     │
          │                                                    │
          │    ┌────────────────────────────────────────────┐  │
          │    │     Public Route Table → 0.0.0.0/0 → IGW  │  │
          │    └────────────────────────────────────────────┘  │
          │                                                    │
          │  ┌─────────────────────────┐                       │
          │  │  public-subnet-a        │                       │
          │  │  10.0.1.0/24 us-east-1a │                       │
          │  │                         │                       │
          │  │  ┌───────────────────┐  │                       │
          │  │  │  EC2 App Server   │  │                       │
          │  │  │  app-server       │  │                       │
          │  │  │  t2.micro         │  │                       │
          │  │  │  Amazon Linux 2023│  │                       │
          │  │  │  Public IP: ✓     │  │                       │
          │  │  │  ec2-app-sg       │  │                       │
          │  │  │  MySQL client ✓   │  │                       │
          │  │  │  Apache httpd ✓   │  │                       │
          │  │  └────────┬──────────┘  │                       │
          │  └───────────│─────────────┘                       │
          │              │ MySQL port 3306                      │
          │              │ (SG chain: ec2-app-sg → rds-sg)     │
          │  ┌───────────▼─────────────────────────────────┐   │
          │  │  Private Subnets (RDS Subnet Group)         │   │
          │  │                                             │   │
          │  │  ┌──────────────────┐  ┌─────────────────┐ │   │
          │  │  │ private-subnet-a │  │ private-subnet-b│ │   │
          │  │  │ 10.0.3.0/24      │  │ 10.0.4.0/24     │ │   │
          │  │  │ us-east-1a       │  │ us-east-1b      │ │   │
          │  │  │                  │  │                 │ │   │
          │  │  │ ┌──────────────┐ │  │  (standby AZ)  │ │   │
          │  │  │ │ RDS MySQL    │ │  │                 │ │   │
          │  │  │ │ myapp-db     │ │  │                 │ │   │
          │  │  │ │ db.t3.micro  │ │  │                 │ │   │
          │  │  │ │ MySQL 8.0    │ │  │                 │ │   │
          │  │  │ │ 20 GiB gp2   │ │  │                 │ │   │
          │  │  │ │ No public IP │ │  │                 │ │   │
          │  │  │ │ rds-sg       │ │  │                 │ │   │
          │  │  │ └──────────────┘ │  │                 │ │   │
          │  │  └──────────────────┘  └─────────────────┘ │   │
          │  └─────────────────────────────────────────────┘   │
          │                                                    │
          └────────────────────────────────────────────────────┘

Supporting Services (outside VPC):

  AWS Secrets Manager ←── EC2 fetches credentials via IAM role
  AWS CloudWatch      ←── RDS pushes metrics automatically
  AWS IAM             ←── ec2-app-role grants Secrets Manager access
```

---

## Network Flow — Inbound Web Request

```
User browser → Internet → IGW → public-subnet-a → EC2 :80 → Apache → index.html
```

No database involvement for static content. In a real app, the app tier would query RDS and return dynamic data.

---

## Network Flow — EC2 to RDS Query

```
EC2 (ec2-app-sg)
    │
    │ TCP port 3306
    │ Destination: myapp-database.xxxxxxxx.us-east-1.rds.amazonaws.com
    │
    ▼
VPC DNS resolves endpoint → private IP in 10.0.3.0/24
    │
    ▼
Security group check: does source carry ec2-app-sg? → YES → allowed
    │
    ▼
RDS MySQL (private-subnet-a, 10.0.3.x)
    │
    ▼
MySQL authentication → admin / password from Secrets Manager
    │
    ▼
appdb → users table → SELECT * FROM users → 3 rows returned
```

---

## IAM Flow — Secrets Manager Access

```
EC2 instance
    │
    │ has attached: ec2-app-profile (instance profile)
    │           which contains: ec2-app-role
    │
    ▼
IAM Role (ec2-app-role)
    │
    ├── AmazonSSMManagedInstanceCore (AWS managed)
    │
    └── secrets-manager-access (inline policy)
            └── secretsmanager:GetSecretValue
                    on: arn:aws:secretsmanager:us-east-1:*:secret:rds/myapp/*
    │
    ▼
Secrets Manager → rds/myapp/credentials
    │
    ▼
Returns: { username, password, engine, port, dbname }
```

---

## Resource Inventory

| Resource | Name | ID Pattern |
|---|---|---|
| VPC | my-custom-vpc | vpc-xxxxxxxxx |
| Public Subnet A | public-subnet-a | subnet-xxxxxxxxx |
| Public Subnet B | public-subnet-b | subnet-xxxxxxxxx |
| Private Subnet A | private-subnet-a | subnet-xxxxxxxxx |
| Private Subnet B | private-subnet-b | subnet-xxxxxxxxx |
| Internet Gateway | my-vpc-igw | igw-xxxxxxxxx |
| Public Route Table | public-route-table | rtb-xxxxxxxxx |
| Private Route Table | private-route-table | rtb-xxxxxxxxx |
| EC2 Security Group | ec2-app-sg | sg-xxxxxxxxx |
| RDS Security Group | rds-sg | sg-xxxxxxxxx |
| RDS Subnet Group | rds-subnet-group | (name-based) |
| Secret | rds/myapp/credentials | ARN |
| RDS Instance | myapp-database | (identifier) |
| EC2 Instance | app-server | i-xxxxxxxxx |
| IAM Role | ec2-app-role | (name-based) |
| Instance Profile | ec2-app-profile | (name-based) |

---

## Design Decisions

**Why two private subnets?**
RDS requires the subnet group to span at least two AZs. Even running a single-AZ instance, AWS needs subnet options in multiple zones for maintenance operations. `private-subnet-b` is reserved — no RDS instance runs there in this project, but it satisfies the requirement.

**Why no NAT Gateway?**
The private subnets have no outbound internet access in this project. RDS doesn't need outbound internet — it only receives inbound MySQL connections from EC2. EC2 gets its software packages (MySQL client, Apache) from yum repos at launch time via the public subnet's IGW route.

**Why Secrets Manager over environment variables?**
Environment variables are visible to any process running on the instance and can leak through application logs. Secrets Manager access is audited in CloudTrail, rotatable without redeploying the application, and scoped to specific secrets via IAM policy.

**Why db.t3.micro and not db.t2.micro?**
AWS retired db.t2 for new RDS instances. db.t3.micro is the current Free Tier eligible class for MySQL. It provides 2 vCPUs, 1 GiB RAM — sufficient for development and low-traffic workloads.