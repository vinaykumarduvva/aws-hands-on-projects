# Architecture Details — RDS MySQL + EC2 Two-Tier Application

## Two-Tier Architecture Pattern

This project implements a classic **two-tier architecture** — the most common deployment pattern for production web applications:

- **Tier 1 (Presentation/Application Layer):** EC2 instance in a public subnet, accessible from the internet via HTTP (port 80) and SSH (port 22)
- **Tier 2 (Data Layer):** RDS MySQL instance in private subnets, accessible only from Tier 1 via security group chaining on port 3306

```
┌──────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└─────────────────────────┬────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────────┐
│                   Internet Gateway                           │
└─────────────────────────┬────────────────────────────────────┘
                          │
┌─────────────────────────┼────────────────────────────────────┐
│                   VPC (10.0.0.0/16)                          │
│                         │                                    │
│  ┌──────────────────────┼──────────────────────────────────┐ │
│  │  PUBLIC SUBNETS      │                                  │ │
│  │                      ▼                                  │ │
│  │  ┌─────────────────────────────────┐   ┌─────────────┐ │ │
│  │  │  public-subnet-a (10.0.1.0/24) │   │ public-sub-b│ │ │
│  │  │  us-east-1a                    │   │ (10.0.2.0/24│ │ │
│  │  │                                │   │ us-east-1b) │ │ │
│  │  │  ┌──────────────────────────┐  │   └─────────────┘ │ │
│  │  │  │  EC2 App Server         │  │                    │ │
│  │  │  │  t2.micro               │  │                    │ │
│  │  │  │  Amazon Linux 2023      │  │                    │ │
│  │  │  │  ec2-app-sg             │  │                    │ │
│  │  │  │  ┌────────────────────┐ │  │                    │ │
│  │  │  │  │ Apache httpd       │ │  │                    │ │
│  │  │  │  │ MySQL CLI client   │ │  │                    │ │
│  │  │  │  │ AWS CLI            │ │  │                    │ │
│  │  │  │  └────────────────────┘ │  │                    │ │
│  │  │  └────────────┬───────────┘  │                    │ │
│  │  └───────────────┼──────────────┘                    │ │
│  └──────────────────┼──────────────────────────────────-┘ │
│                     │ TCP 3306 (MySQL)                     │
│  ┌──────────────────┼──────────────────────────────────┐  │
│  │  PRIVATE SUBNETS │                                  │  │
│  │                  ▼                                  │  │
│  │  ┌───────────────────────────┐ ┌──────────────────┐ │  │
│  │  │ private-subnet-a          │ │ private-subnet-b │ │  │
│  │  │ (10.0.3.0/24)            │ │ (10.0.4.0/24)    │ │  │
│  │  │ us-east-1a               │ │ us-east-1b       │ │  │
│  │  │                          │ │                  │ │  │
│  │  │  ┌────────────────────┐  │ │                  │ │  │
│  │  │  │  RDS MySQL 8.0     │  │ │                  │ │  │
│  │  │  │  db.t3.micro       │  │ │                  │ │  │
│  │  │  │  rds-sg            │  │ │                  │ │  │
│  │  │  │  20 GiB gp2        │  │ │                  │ │  │
│  │  │  │  No public access   │  │ │                  │ │  │
│  │  │  └────────────────────┘  │ │                  │ │  │
│  │  └──────────────────────────┘ └──────────────────┘ │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  SUPPORTING SERVICES                                │  │
│  │  ┌──────────────┐ ┌──────────────┐ ┌─────────────┐ │  │
│  │  │ Secrets Mgr  │ │ CloudWatch   │ │ IAM Role    │ │  │
│  │  │ rds/myapp/   │ │ CPU, Conns   │ │ ec2-app-role│ │  │
│  │  │ credentials  │ │ Storage      │ │ SSM + SM    │ │  │
│  │  └──────────────┘ └──────────────┘ └─────────────┘ │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

## Network Data Flow

### Inbound Web Traffic (User → EC2)

```
User Browser
    → Internet
    → Internet Gateway
    → Public Route Table (0.0.0.0/0 → IGW)
    → public-subnet-a
    → ec2-app-sg allows HTTP (80)
    → EC2 Apache httpd serves response
```

### Application → Database (EC2 → RDS)

```
EC2 App Server
    → MySQL CLI: mysql -h endpoint -P 3306 -u admin -p
    → VPC internal routing (10.0.0.0/16 → local)
    → rds-sg allows TCP 3306 from ec2-app-sg
    → RDS MySQL processes query
    → Response returns via same path
```

### Secrets Manager Credential Retrieval

```
EC2 App Server
    → IAM Instance Profile (ec2-app-role)
    → STS issues temporary credentials
    → secretsmanager:GetSecretValue API call
    → Returns JSON with username/password
    → App uses credentials to connect to RDS
```

## Route Table Configuration

### Public Route Table

| Destination | Target | Purpose |
|:------------|:-------|:--------|
| `10.0.0.0/16` | local | VPC internal traffic |
| `0.0.0.0/0` | igw-xxxxxxxxx | Internet access |

**Associated subnets:** `public-subnet-a`, `public-subnet-b`

### Private Route Table

| Destination | Target | Purpose |
|:------------|:-------|:--------|
| `10.0.0.0/16` | local | VPC internal traffic |

**Associated subnets:** `private-subnet-a`, `private-subnet-b`

> **Key difference:** The private route table has **no** `0.0.0.0/0` entry. This means RDS cannot initiate connections to the internet, and the internet cannot reach RDS — even if someone obtained the endpoint URL and credentials.

## CIDR Block Plan

| Resource | CIDR | IPs Available | AZ |
|:---------|:-----|:--------------|:---|
| **VPC** | `10.0.0.0/16` | 65,536 total | — |
| **Public Subnet A** | `10.0.1.0/24` | 251 usable | us-east-1a |
| **Public Subnet B** | `10.0.2.0/24` | 251 usable | us-east-1b |
| **Private Subnet A** | `10.0.3.0/24` | 251 usable | us-east-1a |
| **Private Subnet B** | `10.0.4.0/24` | 251 usable | us-east-1b |

> 💡 AWS reserves 5 IPs per subnet (.0, .1, .2, .3, .255), so each /24 gives 251 usable addresses.

## Security Group Architecture

### ec2-app-sg

| Direction | Port | Protocol | Source | Purpose |
|:----------|:-----|:---------|:-------|:--------|
| Inbound | 22 | TCP | `YOUR_IP/32` | SSH from your IP only |
| Inbound | 80 | TCP | `0.0.0.0/0` | HTTP from anywhere |
| Outbound | All | All | `0.0.0.0/0` | Default allow all |

### rds-sg

| Direction | Port | Protocol | Source | Purpose |
|:----------|:-----|:---------|:-------|:--------|
| Inbound | 3306 | TCP | `ec2-app-sg` (SG ID) | MySQL from app server only |
| Outbound | All | All | `0.0.0.0/0` | Default allow all |

### Why Security Group References Beat CIDR Rules

- EC2 public/private IPs can change on restart — SG references don't need updating
- New app servers get DB access automatically by attaching the right SG
- Access revocation is immediate — remove the SG, connection drops
- No risk of accidentally opening DB to wrong IP ranges

## RDS Configuration Details

| Setting | Value | Rationale |
|:--------|:------|:----------|
| Engine | MySQL 8.0 | Latest stable major version |
| Instance class | db.t3.micro | Free Tier eligible |
| Storage | 20 GiB gp2 | Free Tier maximum |
| Storage autoscaling | Disabled | Avoid unexpected costs |
| Multi-AZ | No (single-AZ) | Free Tier limitation |
| Public access | No | Security — private subnets only |
| Backup retention | 1 day | Minimum useful retention |
| Encryption | Enabled (default KMS) | Data at rest protection |
| Deletion protection | Disabled | Easy cleanup for learning project |
| Enhanced monitoring | Disabled | Cost savings |
| Performance Insights | Disabled | Cost savings |
| Initial database | `appdb` | Pre-created application database |

## Comparison: Architecture Decisions

| Decision | Choice | Alternative | Why |
|:---------|:-------|:------------|:----|
| Database | RDS MySQL | MySQL on EC2 | Managed backups, patching, monitoring |
| Subnet placement | Private | Public | No internet exposure for database |
| SG rule type | SG reference | CIDR block | Dynamic, doesn't break on IP change |
| Credentials | Secrets Manager | Hardcoded | Audit trail, rotation, no code exposure |
| Monitoring | CloudWatch | Manual | Built-in with RDS, zero setup |
| Backup | Automated + manual | Manual only | Point-in-time recovery capability |