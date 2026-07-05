This guide walks through the complete build in order. Run the scripts from the `scripts/` folder or follow the console steps in each section.

---

## Pre-Flight Checks

```powershell
# Confirm CLI is working
aws sts get-caller-identity

# Confirm region is us-east-1
aws configure get region

# Confirm key pair exists
aws ec2 describe-key-pairs --key-names aws-ec2-keypair `
  --query "KeyPairs[0].KeyName" --output text
```

All three should return expected values before proceeding.

---

## Part 1 — VPC Setup

Script: `scripts/01-vpc-setup.ps1`

Creates the full VPC from scratch:
- VPC `10.0.0.0/16` with DNS hostnames and DNS support enabled
- `public-subnet-a` (`10.0.1.0/24`, us-east-1a) — auto-assign public IP
- `public-subnet-b` (`10.0.2.0/24`, us-east-1b) — auto-assign public IP
- `private-subnet-a` (`10.0.3.0/24`, us-east-1a) — no public IP
- `private-subnet-b` (`10.0.4.0/24`, us-east-1b) — no public IP
- Internet gateway attached to VPC
- Public route table with `0.0.0.0/0 → IGW`, associated to both public subnets
- Private route table (local only), associated to both private subnets

**Checkpoint**: All IDs printed to console. Save them — subsequent scripts depend on `$VPC_ID`, `$PRI_SUBNET_A`, `$PRI_SUBNET_B`, etc.

---

## Part 2 — Security Groups

Script: `scripts/02-security-groups.ps1`

Creates two security groups:

**ec2-app-sg**
- SSH (22) from your current public IP only
- HTTP (80) from anywhere

**rds-sg**
- MySQL/Aurora (3306) from `ec2-app-sg` only — no CIDR rules

**Checkpoint**: Verify both SGs exist with correct inbound rules.

---

## Part 3 — RDS Subnet Group

Script: `scripts/03-rds-subnet-group.ps1`

Creates `rds-subnet-group` spanning `private-subnet-a` and `private-subnet-b`. RDS requires a subnet group covering at least two AZs even for single-AZ deployments.

Console path: RDS → Subnet groups → Create DB subnet group

**Checkpoint**: Status shows `Complete`, both private subnet IDs listed.

---

## Part 4 — Secrets Manager

Script: `scripts/04-secrets-manager.ps1`

Stores DB credentials in AWS Secrets Manager at path `rds/myapp/credentials`.

Secret value (JSON):
```json
{
  "username": "admin",
  "password": "MyDB#Secure2024!",
  "engine":   "mysql",
  "port":     3306,
  "dbname":   "appdb"
}
```

Password rules — do NOT use: `@`, `/`, `"`, `\` (break MySQL connection strings).

Save the Secret ARN — needed for IAM policy scoping later.

**Checkpoint**: Secret visible in Secrets Manager console with correct name.

---

## Part 5 — Launch RDS MySQL

Script: `scripts/05-create-rds.ps1`

Key settings:
```
Engine:         MySQL 8.0
Instance class: db.t3.micro
Template:       Free tier
Storage:        20 GiB gp2 (autoscaling disabled)
VPC:            my-custom-vpc
Subnet group:   rds-subnet-group
Public access:  No
Security group: rds-sg
Initial DB:     appdb
Backups:        1 day retention
Encryption:     Enabled
```

RDS takes **5–10 minutes** to provision. The CLI script uses `aws rds wait db-instance-available` to block until ready.

**Checkpoint**: Status = `available`. Endpoint copied and saved.

---

## Part 6 — Launch EC2 App Server

Script: `scripts/06-launch-ec2.ps1`

EC2 settings:
```
AMI:      Amazon Linux 2023 (latest)
Type:     t2.micro
Subnet:   public-subnet-a
SG:       ec2-app-sg
Key pair: aws-ec2-keypair
User data: installs mysql client + Apache httpd, creates status page
```

The user data script runs on first boot and installs the MySQL CLI client, which is needed to connect to RDS from the terminal.

**Checkpoint**: Instance running, public IP assigned, Apache serving the status page at `http://PUBLIC_IP`.

---

## Part 7 — Connect EC2 to RDS

### SSH into EC2

```
PuTTY:
  Host: ec2-user@YOUR_APP_SERVER_PUBLIC_IP
  Port: 22
  Key:  aws-ec2-keypair.ppk
```

### Connect to MySQL

```bash
mysql -h YOUR_RDS_ENDPOINT \
      -P 3306 \
      -u admin \
      -p
# Password: MyDB#Secure2024!
```

### Run schema and queries

SQL file: `scripts/07-rds-connect.sql`

```sql
USE appdb;

CREATE TABLE users (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    email      VARCHAR(150) NOT NULL UNIQUE,
    role       VARCHAR(50)  DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email, role) VALUES
  ('Vinay Kumar',   'vinay@example.com',  'admin'),
  ('AWS Engineer',  'aws@example.com',    'developer'),
  ('Cloud Learner', 'cloud@example.com',  'user');

SELECT * FROM users;
SELECT @@hostname;
SELECT VERSION();
```

`SELECT @@hostname` confirms you are connected to RDS (not a local MySQL instance).

### Attach IAM Role for Secrets Manager (bonus)

Run `scripts/06-launch-ec2.ps1` Step 12 section from PowerShell to create and attach `ec2-app-role` with `ec2-app-profile`. Then from EC2:

```bash
aws secretsmanager get-secret-value \
  --secret-id "rds/myapp/credentials" \
  --region us-east-1 \
  --query "SecretString" \
  --output text
```

**Checkpoint**: `SELECT * FROM users` returns 3 rows. `SELECT @@hostname` returns the RDS instance identifier.

---

## Part 8 — CloudWatch Monitoring

Script: `scripts/08-cloudwatch-monitoring.ps1`

Queries the last hour of metrics:
- `CPUUtilization` — should be near 0 for idle instance
- `DatabaseConnections` — reflects active connections
- `FreeStorageSpace` — baseline is ~20 GiB

Console path: RDS → Databases → myapp-database → Monitoring tab

---

## Part 9 — RDS Operations

Script: `scripts/09-rds-operations.ps1`

Covers:
- Describe instance (status, endpoint, class, storage)
- Create manual snapshot
- List all snapshots
- Stop instance (saves cost — 7-day max)
- Start instance
- Modify backup retention

---

## Part 10 — Full Cleanup

Script: `scripts/10-cleanup.ps1`

Deletion order matters. Run in sequence:
1. Terminate EC2
2. Delete RDS (no final snapshot)
3. Delete RDS subnet group
4. Delete Secrets Manager secret
5. Delete security groups
6. Delete IAM role and instance profile
7. Delete subnets
8. Delete route tables
9. Detach and delete IGW
10. Delete VPC

**Checkpoint**: `aws rds describe-db-instances` returns `DBInstanceNotFound` error.

---

## Time Estimates

| Part                       | Estimated Time |
| ----------------------------| ----------------|
| Pre-flight                 | 2 min          |
| VPC setup                  | 5 min          |
| Security groups            | 3 min          |
| RDS subnet group           | 2 min          |
| Secrets Manager            | 2 min          |
| RDS launch (includes wait) | 15 min         |
| EC2 launch                 | 5 min          |
| Connect + query            | 10 min         |
| CloudWatch                 | 5 min          |
| RDS operations             | 5 min          |
| Cleanup (includes wait)    | 15 min         |
| **Total**                  | **~70 min**    |

