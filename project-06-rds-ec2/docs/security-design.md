## Security Layers

This project implements defense in depth across four distinct layers.

---

## Layer 1 — Network Isolation (VPC + Subnets)

RDS lives in private subnets with no route to the internet gateway. The routing table for `private-subnet-a` and `private-subnet-b` has no `0.0.0.0/0` entry. Even if someone obtained the RDS endpoint and credentials, they cannot reach the database from outside the VPC.

```
Public Route Table:
  10.0.0.0/16  → local
  0.0.0.0/0    → igw-xxxxxxxxx  ← internet access

Private Route Table:
  10.0.0.0/16  → local
  (no 0.0.0.0/0 entry)          ← NO internet access
```

---

## Layer 2 — Security Group Chaining

The RDS security group (`rds-sg`) does not allow any CIDR-based inbound rules. It allows MySQL (TCP 3306) only from the source security group `ec2-app-sg`.

```
rds-sg Inbound Rules:
  Type           Port   Source
  MySQL/Aurora   3306   sg-xxxxxxx (ec2-app-sg)
```

This means:
- A laptop on your home network cannot reach RDS (no SG, no access)
- Another EC2 instance in the same VPC cannot reach RDS (wrong SG, no access)
- Only instances carrying `ec2-app-sg` can connect on port 3306

This is preferable to IP-based rules because:
- EC2 public IPs change on restart — SG rules do not need updating
- New app servers get DB access automatically by attaching the right SG
- Access revocation is immediate — remove the SG, connection drops

---

## Layer 3 — Credential Management (Secrets Manager)

Database credentials are never hardcoded, never in environment files, never in source code.

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

EC2 retrieves this at runtime:
```bash
aws secretsmanager get-secret-value \
  --secret-id "rds/myapp/credentials" \
  --region us-east-1 \
  --query "SecretString" \
  --output text
```

Benefits:
- Credentials never appear in git history, application logs, or process arguments
- Access is auditable via CloudTrail (who retrieved the secret, when)
- Rotation can be enabled without redeploying the application
- If an instance is compromised, the secret can be rotated to revoke access

---

## Layer 4 — IAM Least Privilege (Instance Role)

The EC2 instance carries an IAM role (`ec2-app-role`) with the minimum permissions needed.

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

The Secrets Manager permission is scoped to `rds/myapp/*` — it cannot retrieve secrets from other paths. SSM access is for Systems Manager Session Manager (alternative to SSH). RDS describe permissions allow the app to discover endpoints programmatically.

---

## RDS-Specific Security Settings

| Setting             | Value                   | Reason                        |
| ---------------------| -------------------------| -------------------------------|
| Public access       | No                      | No public IP assigned to RDS  |
| Deletion protection | Disabled (project only) | Enable in production          |
| Storage encryption  | Enabled (default KMS)   | Data at rest is encrypted     |
| Automated backups   | Enabled                 | Recovery capability           |
| Backup retention    | 1 day                   | Minimum useful retention      |
| Enhanced monitoring | Disabled                | Reduces cost for this project |

---

## What Is NOT Secured (Acceptable for This Project)

**SSH key-based access to EC2**: The `aws-ec2-keypair` key pair allows SSH access. In production, this would be replaced with AWS Systems Manager Session Manager, removing the need for SSH keys entirely and eliminating the need for port 22 in the security group.

**Single master user**: This project uses a single `admin` user for all database operations. In production, you would create application-specific users with scoped permissions (`SELECT`, `INSERT`, `UPDATE` only — no `DROP`, `CREATE`, `GRANT`).

**No SSL/TLS on MySQL connection**: The `mysql -h endpoint` command in Part 7 does not enforce SSL. In production, you would add `--ssl-mode=REQUIRED` and download the RDS CA certificate. RDS supports SSL by default; the client must be configured to use it.

**Single AZ**: The Free Tier template disables Multi-AZ. A production deployment would enable Multi-AZ for automatic failover in case the primary AZ goes down.

---

## Threat Model Summary

| Threat                            | Mitigation                                   |
| -----------------------------------| ----------------------------------------------|
| Internet attacker reaches RDS     | Private subnet + no public IP — unreachable  |
| Compromised EC2 leaks DB password | Secrets Manager — no password stored on disk |
| Another EC2 queries RDS           | SG chaining — only ec2-app-sg allowed        |
| Accidental data deletion          | Automated daily backups + manual snapshots   |
| Insider reads secret              | CloudTrail logs every GetSecretValue call    |
| Data exposure at rest             | RDS storage encrypted with AWS KMS           |