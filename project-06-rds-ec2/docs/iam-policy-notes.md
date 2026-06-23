# IAM Policy Notes — Project 6

## IAM Role Created: ec2-app-role

### Trust Policy (who can assume this role)
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "ec2.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }]
}
```
Only EC2 instances can assume this role.
This is the standard trust policy for all EC2 instance roles.

---

## Attached Policy 1 — AWS Managed

**Policy name:** AmazonSSMManagedInstanceCore
**Type:** AWS Managed Policy
**ARN:** arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

**What it allows:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:UpdateInstanceInformation",
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel",
        "ec2messages:AcknowledgeMessage",
        "ec2messages:DeleteMessage",
        "ec2messages:FailMessage",
        "ec2messages:GetEndpoint",
        "ec2messages:GetMessages",
        "ec2messages:SendReply"
      ],
      "Resource": "*"
    }
  ]
}
```

**Why needed:** Allows Session Manager to open browser-based
terminal without requiring open SSH port 22.

---

## Attached Policy 2 — Customer Managed (Inline)

**Policy name:** secrets-manager-access
**Type:** Inline policy on ec2-app-role

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSecretsManagerRead",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:*:secret:rds/myapp/*"
    },
    {
      "Sid": "AllowRDSDescribe",
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

### Least privilege analysis

| Permission | Why needed | Scope |
|---|---|---|
| secretsmanager:GetSecretValue | Fetch DB password at runtime | Only rds/myapp/* path |
| secretsmanager:DescribeSecret | Read secret metadata | Only rds/myapp/* path |
| rds:DescribeDBInstances | Get RDS endpoint programmatically | All RDS (read-only, safe) |

**What is NOT allowed:**
- `secretsmanager:CreateSecret` → cannot create new secrets
- `secretsmanager:DeleteSecret` → cannot delete secrets
- `secretsmanager:UpdateSecret` → cannot change secret values
- `rds:DeleteDBInstance` → cannot delete database
- `rds:ModifyDBInstance` → cannot change DB config
- `ec2:*` → no EC2 permissions (not needed)
- `iam:*` → no IAM permissions (not needed)

**Resource scoping:**
`arn:aws:secretsmanager:us-east-1:*:secret:rds/myapp/*`
- Region: us-east-1 only
- Account: any (wildcard — acceptable since role is account-scoped)
- Secret path: rds/myapp/ prefix only
- Cannot access secrets under other paths (e.g. rds/other/ blocked)

---

## Instance Profile: ec2-app-profile

An instance profile is the container that attaches an IAM
role to an EC2 instance. You cannot attach a role directly
to EC2 — it must go through an instance profile.

```
EC2 Instance
    └── Instance Profile: ec2-app-profile
         └── IAM Role: ec2-app-role
              ├── AmazonSSMManagedInstanceCore (AWS managed)
              └── secrets-manager-access (inline)
```

**CLI commands used:**
```powershell
# Create role
aws iam create-role --role-name ec2-app-role ...

# Attach AWS managed policy
aws iam attach-role-policy `
  --role-name ec2-app-role `
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Add inline policy
aws iam put-role-policy `
  --role-name ec2-app-role `
  --policy-name secrets-manager-access `
  --policy-document file://policy.json

# Create instance profile
aws iam create-instance-profile `
  --instance-profile-name ec2-app-profile

# Add role to profile
aws iam add-role-to-instance-profile `
  --instance-profile-name ec2-app-profile `
  --role-name ec2-app-role

# Attach to EC2
aws ec2 associate-iam-instance-profile `
  --instance-id $APP_INSTANCE_ID `
  --iam-instance-profile Name=ec2-app-profile
```

---

## Security Group Policies — This Project

### ec2-app-sg
| Direction | Port | Protocol | Source | Purpose |
|---|---|---|---|---|
| Inbound | 22 | TCP | MY_IP/32 | SSH from my PC |
| Inbound | 80 | TCP | 0.0.0.0/0 | HTTP web server |
| Outbound | All | All | 0.0.0.0/0 | Default allow all |

### rds-sg
| Direction | Port | Protocol | Source | Purpose |
|---|---|---|---|---|
| Inbound | 3306 | TCP | ec2-app-sg (SG ID) | MySQL from app server |
| Outbound | All | All | 0.0.0.0/0 | Default allow all |

**Key design decision:** `rds-sg` uses a security group reference
as source, not a CIDR block. This means:
- Only instances with `ec2-app-sg` attached can connect to MySQL
- Even if the EC2 instance changes its private IP, the rule still works
- No other instance in the VPC can reach MySQL on port 3306

---

## IAM Best Practices Applied in This Project

| Practice | How applied |
|---|---|
| Least privilege | Secrets Manager policy scoped to rds/myapp/* path only |
| No long-term credentials | EC2 uses role (temporary STS tokens) — no access keys |
| Service-specific trust | Trust policy allows only ec2.amazonaws.com |
| Separate concerns | SSM policy and Secrets Manager policy are separate |
| Resource-level scoping | ARN includes region + specific path prefix |
| No wildcard actions | Specific actions listed — no `secretsmanager:*` |

---

## Credential Flow — How App Gets DB Password

```
Application on EC2
    │
    │ 1. Call Secrets Manager
    ▼
EC2 Instance Role (ec2-app-role)
    │
    │ 2. STS issues temporary credentials
    ▼
secretsmanager:GetSecretValue
    │
    │ 3. Returns secret JSON
    ▼
Application parses JSON
    │
    │ 4. Connect to RDS with credentials
    ▼
RDS MySQL (never saw the password directly)

Benefits:
- Password never in code or config files
- Automatic rotation possible
- Access audit trail in CloudTrail
- Revoke access by removing IAM policy (no code change)
```

---

## IAM Policies Added From Previous Projects

### Project 1 — AdministratorAccess
Attached to: admin-yourname IAM user
Allows: all AWS actions

### Project 2 — S3 Bucket Policy (Public Read)
Attached to: S3 bucket (aws-portfolio-yourname-2024)
Allows: s3:GetObject from Principal *

### Project 3 — AmazonSSMManagedInstanceCore
Attached to: ec2-ssm-role
Allows: Session Manager terminal access

### Project 4 — S3 Replication Role
Attached to: s3-replication-role
Allows: read source bucket + write destination bucket

### Project 6 — ec2-app-role (this project)
Attached to: ec2-app-profile → app-server EC2
Allows: SSM Session Manager + Secrets Manager read for rds/myapp/*