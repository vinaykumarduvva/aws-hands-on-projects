# Security Protocols — RDS MySQL + EC2 Two-Tier Application

This project implements **defense in depth** across four distinct security layers. Each layer independently prevents unauthorized access to the database.

---

## Layer 1 — Network Isolation (VPC + Subnets)

RDS lives in private subnets with **no route to the internet gateway**. The private route table has no `0.0.0.0/0` entry. Even if someone obtained the RDS endpoint and credentials, they cannot reach the database from outside the VPC.

```
Public Route Table:
  10.0.0.0/16  → local
  0.0.0.0/0    → igw-xxxxxxxxx  ← internet access

Private Route Table:
  10.0.0.0/16  → local
  (no 0.0.0.0/0 entry)          ← NO internet access
```

**What this prevents:**
- Direct internet connections to RDS endpoint
- Port scanning of the database from external networks
- SQL injection attacks originating from outside the VPC

---

## Layer 2 — Security Group Chaining

The RDS security group (`rds-sg`) does **not** allow any CIDR-based inbound rules. It allows MySQL (TCP 3306) **only** from the source security group `ec2-app-sg`.

```
rds-sg Inbound Rules:
  Type           Port   Source
  MySQL/Aurora   3306   sg-xxxxxxx (ec2-app-sg)
```

**What this means:**
- ❌ A laptop on your home network cannot reach RDS (no SG, no access)
- ❌ Another EC2 instance in the same VPC cannot reach RDS (wrong SG, no access)
- ✅ Only instances carrying `ec2-app-sg` can connect on port 3306

**Why SG references beat CIDR rules:**
- EC2 public IPs change on restart — SG rules do not need updating
- New app servers get DB access automatically by attaching the right SG
- Access revocation is immediate — remove the SG, connection drops
- No risk of accidentally opening DB to wrong IP ranges

---

## Layer 3 — Credential Management (Secrets Manager)

Database credentials are **never hardcoded**, never in environment files, never in source code.

```
Secret path: rds/myapp/credentials
Secret value (JSON):
  {
    "username": "admin",
    "password": "MyDB#Secure2024!",
    "engine":   "mysql",
    "port":     3306,
    "dbname":   "appdb"
  }
```

EC2 retrieves credentials at runtime:
```bash
aws secretsmanager get-secret-value \
  --secret-id "rds/myapp/credentials" \
  --region us-east-1 \
  --query "SecretString" \
  --output text
```

**Benefits:**
- Credentials never appear in git history, application logs, or process arguments
- Access is auditable via CloudTrail (who retrieved the secret, when)
- Rotation can be enabled without redeploying the application
- If an instance is compromised, the secret can be rotated to revoke access

---

## Layer 4 — IAM Least Privilege (Instance Role)

The EC2 instance carries an IAM role (`ec2-app-role`) with the **minimum permissions needed**.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:*:secret:rds/myapp/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:UpdateInstanceInformation",
        "ssmmessages:*",
        "ec2messages:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "rds:DescribeDBInstances",
        "rds:DescribeDBClusters"
      ],
      "Resource": "*"
    }
  ]
}
```

**Scope analysis:**
- Secrets Manager permission scoped to `rds/myapp/*` — cannot retrieve secrets from other paths
- SSM access for Session Manager (alternative to SSH)
- RDS describe permissions for programmatic endpoint discovery
- No `secretsmanager:CreateSecret`, `DeleteSecret`, or `UpdateSecret`
- No `rds:DeleteDBInstance` or `ModifyDBInstance`
- No `ec2:*` or `iam:*` permissions

---

## RDS-Specific Security Settings

| Setting | Value | Reason |
|:--------|:------|:-------|
| Public access | No | No public IP assigned to RDS |
| Deletion protection | Disabled (project only) | Enable in production |
| Storage encryption | Enabled (default KMS) | Data at rest is encrypted |
| Automated backups | Enabled | Recovery capability |
| Backup retention | 1 day | Minimum useful retention |
| Enhanced monitoring | Disabled | Reduces cost for this project |

---

## Threat Model Summary

| Threat | Mitigation |
|:-------|:-----------|
| Internet attacker reaches RDS | Private subnet + no public IP — unreachable |
| Compromised EC2 leaks DB password | Secrets Manager — no password stored on disk |
| Another EC2 queries RDS | SG chaining — only `ec2-app-sg` allowed |
| Accidental data deletion | Automated daily backups + manual snapshots |
| Insider reads secret | CloudTrail logs every `GetSecretValue` call |
| Data exposure at rest | RDS storage encrypted with AWS KMS |

---

## What Is NOT Secured (Acceptable for This Project)

| Gap | Production Fix |
|:----|:---------------|
| **SSH key-based access** | Replace with SSM Session Manager — eliminate port 22 |
| **Single master DB user** | Create app-specific users with scoped permissions (`SELECT`, `INSERT` only) |
| **No SSL/TLS on MySQL** | Add `--ssl-mode=REQUIRED` and download RDS CA certificate |
| **Single AZ** | Enable Multi-AZ for automatic failover |
| **No VPC Flow Logs** | Enable Flow Logs to CloudWatch or S3 for network audit |