# Project Overview — RDS MySQL + EC2 Two-Tier Application

## What This Project Builds

This project deploys a two-tier web application architecture on AWS — the same pattern used by the majority of production web applications. The two tiers are:

- **Tier 1 — Application layer**: EC2 instance in a public subnet, reachable from the internet
- **Tier 2 — Data layer**: RDS MySQL instance in private subnets, reachable only from Tier 1

Separating these layers improves security, scalability, and operational clarity. The database never needs a public IP address, and any breach of the application tier does not automatically expose the database.

---

## Why RDS Instead of MySQL on EC2

Self-managed MySQL on EC2 works fine for development or highly customized workloads. For everything else, RDS removes the operational burden that doesn't add business value.

| Feature | RDS MySQL | MySQL on EC2 |
|---|---|---|
| OS patching | AWS handles | You handle |
| DB engine updates | AWS handles | You handle |
| Automated backups | Built-in (1–35 day retention) | You build it |
| Multi-AZ failover | One checkbox | Complex manual setup |
| CloudWatch monitoring | Built-in | Manual setup |
| Storage auto-scaling | Optional | Manual |
| Cost | Higher base | Lower base |
| Control | Less | Full |
| Recommended for | Production | Dev/test or special needs |

RDS costs more per hour, but it replaces dozens of hours of operational work. For most production use cases, the trade-off is straightforward.

---

## Key Concepts Demonstrated

### Security Group Chaining
The RDS security group accepts MySQL connections (port 3306) only from resources that carry the EC2 app security group. No IP address rules are involved — the rule references a security group ID directly. This means:
- Adding a new app server automatically gives it database access (attach the right SG)
- Removing SG from an instance immediately revokes its database access
- The database is completely unreachable from the internet or any unrelated EC2 instance

### RDS Subnet Group
An RDS subnet group defines which subnets RDS can use for its network interfaces. It must span at least two Availability Zones — AWS requires this even for single-AZ deployments. This project uses the two private subnets (`private-subnet-a` in us-east-1a, `private-subnet-b` in us-east-1b).

### Secrets Manager Integration
Database credentials are stored in AWS Secrets Manager rather than hardcoded in application code or environment files. The EC2 instance retrieves credentials at runtime using an IAM role with scoped `secretsmanager:GetSecretValue` permission. This is the correct production pattern.

### No Public Access on RDS
The RDS instance has `PubliclyAccessible = false`. It has no public IP address. The only network path to reach it is through the VPC, from an EC2 instance carrying the correct security group.

---

## Infrastructure Breakdown

### VPC Layout

```
VPC: 10.0.0.0/16 (my-custom-vpc)

Public Subnets:
  public-subnet-a  →  10.0.1.0/24  →  us-east-1a  →  EC2 app server
  public-subnet-b  →  10.0.2.0/24  →  us-east-1b  →  (spare / LB)

Private Subnets:
  private-subnet-a →  10.0.3.0/24  →  us-east-1a  →  RDS primary
  private-subnet-b →  10.0.4.0/24  →  us-east-1b  →  RDS subnet group
```

### Security Groups

```
ec2-app-sg:
  Inbound:  SSH (22) from your IP
            HTTP (80) from 0.0.0.0/0
  Outbound: All traffic

rds-sg:
  Inbound:  MySQL/Aurora (3306) from ec2-app-sg only
  Outbound: All traffic
```

### RDS Configuration

```
Engine:         MySQL 8.0
Instance class: db.t3.micro (Free Tier eligible)
Storage:        20 GiB gp2
Multi-AZ:       No (Free Tier)
Public access:  No
Backups:        Enabled (1-day retention)
Initial DB:     appdb
```

---

## What You Prove By Completing This

When `SELECT * FROM users;` returns data from inside the MySQL prompt on EC2, the following has been verified to work:

1. VPC routing is correct — EC2 can reach private subnets
2. Security group chaining is correct — port 3306 flows from EC2 to RDS
3. RDS subnet group is configured — RDS knows which subnets to use
4. DNS resolution is working — EC2 resolved the RDS endpoint hostname
5. MySQL authentication worked — credentials from Secrets Manager are valid
6. The appdb database and users table exist — schema management works
7. Data persists — writes survive and reads return correct rows

That is the full data path, verified end to end.