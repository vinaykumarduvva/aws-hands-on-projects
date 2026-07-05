# Deployment Guide — RDS MySQL + EC2 Two-Tier Application

> [!TIP]
> Use the provided automation scripts in `scripts/powershell/` or `scripts/bash/` to deploy this instantly. This guide provides both **console** and **CLI** instructions for every step.

## Prerequisites

- AWS CLI v2 configured with IAM credentials (`aws sts get-caller-identity`)
- Region set to `us-east-1` (`aws configure get region`)
- Key pair `aws-ec2-keypair` exists (`aws ec2 describe-key-pairs --key-names aws-ec2-keypair`)
- PuTTY or SSH client with the `.ppk` or `.pem` key file

---

## Part 1 — Rebuild the VPC

We rebuild the full VPC from Project 05 with identical structure.

### Console Steps

1. **VPC** → Create VPC → `10.0.0.0/16` → Name: `my-custom-vpc` → Enable DNS hostnames
2. **Subnets** → Create 4 subnets (see table below)
3. **Internet Gateway** → Create → Name: `my-vpc-igw` → Attach to VPC
4. **Route Tables** → Create public RT → Add route `0.0.0.0/0 → IGW` → Associate public subnets
5. **Route Tables** → Create private RT → Associate private subnets

| Subnet | CIDR | AZ | Auto-assign Public IP |
|:-------|:-----|:---|:---------------------|
| `public-subnet-a` | `10.0.1.0/24` | us-east-1a | ✅ Yes |
| `public-subnet-b` | `10.0.2.0/24` | us-east-1b | ✅ Yes |
| `private-subnet-a` | `10.0.3.0/24` | us-east-1a | ❌ No |
| `private-subnet-b` | `10.0.4.0/24` | us-east-1b | ❌ No |

### CLI Steps (PowerShell)

```powershell
# ── VPC ──────────────────────────────────────────
$VPC_ID = aws ec2 create-vpc `
  --cidr-block 10.0.0.0/16 `
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=my-custom-vpc}]" `
  --query "Vpc.VpcId" --output text

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
Write-Host "VPC: $VPC_ID"

# ── SUBNETS ───────────────────────────────────────
$PUB_SUBNET_A = aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 `
  --availability-zone us-east-1a `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-a}]" `
  --query "Subnet.SubnetId" --output text

$PUB_SUBNET_B = aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 `
  --availability-zone us-east-1b `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-b}]" `
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

aws ec2 modify-subnet-attribute --subnet-id $PUB_SUBNET_A --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $PUB_SUBNET_B --map-public-ip-on-launch

Write-Host "Subnets: $PUB_SUBNET_A | $PUB_SUBNET_B | $PRI_SUBNET_A | $PRI_SUBNET_B"

# ── INTERNET GATEWAY ──────────────────────────────
$IGW_ID = aws ec2 create-internet-gateway `
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-vpc-igw}]" `
  --query "InternetGateway.InternetGatewayId" --output text

aws ec2 attach-internet-gateway `
  --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
Write-Host "IGW: $IGW_ID"

# ── PUBLIC ROUTE TABLE ────────────────────────────
$PUB_RT_ID = aws ec2 create-route-table `
  --vpc-id $VPC_ID `
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=public-route-table}]" `
  --query "RouteTable.RouteTableId" --output text

aws ec2 create-route `
  --route-table-id $PUB_RT_ID `
  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

aws ec2 associate-route-table `
  --route-table-id $PUB_RT_ID --subnet-id $PUB_SUBNET_A
aws ec2 associate-route-table `
  --route-table-id $PUB_RT_ID --subnet-id $PUB_SUBNET_B

Write-Host "Public Route Table: $PUB_RT_ID"

# ── PRIVATE ROUTE TABLE ───────────────────────────
$PRI_RT_ID = aws ec2 create-route-table `
  --vpc-id $VPC_ID `
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=private-route-table}]" `
  --query "RouteTable.RouteTableId" --output text

aws ec2 associate-route-table `
  --route-table-id $PRI_RT_ID --subnet-id $PRI_SUBNET_A
aws ec2 associate-route-table `
  --route-table-id $PRI_RT_ID --subnet-id $PRI_SUBNET_B

Write-Host "Private Route Table: $PRI_RT_ID"
Write-Host ""
Write-Host "VPC setup complete. All IDs saved."
```

### CLI Steps (Bash)

```bash
# ── VPC ──────────────────────────────────────────
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=my-custom-vpc}]' \
  --query "Vpc.VpcId" --output text)

aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support
echo "VPC: $VPC_ID"

# ── SUBNETS ───────────────────────────────────────
PUB_SUBNET_A=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-a}]' \
  --query "Subnet.SubnetId" --output text)

PUB_SUBNET_B=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-b}]' \
  --query "Subnet.SubnetId" --output text)

PRI_SUBNET_A=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" --cidr-block 10.0.3.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-a}]' \
  --query "Subnet.SubnetId" --output text)

PRI_SUBNET_B=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" --cidr-block 10.0.4.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-b}]' \
  --query "Subnet.SubnetId" --output text)

aws ec2 modify-subnet-attribute --subnet-id "$PUB_SUBNET_A" --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id "$PUB_SUBNET_B" --map-public-ip-on-launch

echo "Subnets: $PUB_SUBNET_A | $PUB_SUBNET_B | $PRI_SUBNET_A | $PRI_SUBNET_B"

# ── INTERNET GATEWAY ──────────────────────────────
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-vpc-igw}]' \
  --query "InternetGateway.InternetGatewayId" --output text)

aws ec2 attach-internet-gateway \
  --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
echo "IGW: $IGW_ID"

# ── PUBLIC ROUTE TABLE ────────────────────────────
PUB_RT_ID=$(aws ec2 create-route-table \
  --vpc-id "$VPC_ID" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=public-route-table}]' \
  --query "RouteTable.RouteTableId" --output text)

aws ec2 create-route \
  --route-table-id "$PUB_RT_ID" \
  --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID"

aws ec2 associate-route-table \
  --route-table-id "$PUB_RT_ID" --subnet-id "$PUB_SUBNET_A"
aws ec2 associate-route-table \
  --route-table-id "$PUB_RT_ID" --subnet-id "$PUB_SUBNET_B"

echo "Public Route Table: $PUB_RT_ID"

# ── PRIVATE ROUTE TABLE ───────────────────────────
PRI_RT_ID=$(aws ec2 create-route-table \
  --vpc-id "$VPC_ID" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=private-route-table}]' \
  --query "RouteTable.RouteTableId" --output text)

aws ec2 associate-route-table \
  --route-table-id "$PRI_RT_ID" --subnet-id "$PRI_SUBNET_A"
aws ec2 associate-route-table \
  --route-table-id "$PRI_RT_ID" --subnet-id "$PRI_SUBNET_B"

echo "Private Route Table: $PRI_RT_ID"
echo "VPC setup complete."
```

✅ **Checkpoint 1** — VPC rebuilt with all subnets, IGW, and route tables.

---

## Part 2 — Create Security Groups

### Console Steps

**Step 1 — Create ec2-app-sg:**
1. EC2 → Security Groups → Create security group
2. Name: `ec2-app-sg` | Description: `Allow SSH and HTTP for app server` | VPC: `my-custom-vpc`
3. Inbound rules: SSH (22) from My IP | HTTP (80) from Anywhere IPv4

**Step 2 — Create rds-sg:**
1. Create security group
2. Name: `rds-sg` | Description: `Allow MySQL from EC2 app server only` | VPC: `my-custom-vpc`
3. Inbound rules: MySQL/Aurora (3306) → Custom → select `ec2-app-sg`

### CLI Steps (PowerShell)

```powershell
$MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" `
  -UseBasicParsing).Content.Trim()

# Create EC2 app server security group
$EC2_SG = aws ec2 create-security-group `
  --group-name ec2-app-sg `
  --description "Allow SSH and HTTP for app server" `
  --vpc-id $VPC_ID `
  --query "GroupId" --output text

aws ec2 authorize-security-group-ingress `
  --group-id $EC2_SG `
  --protocol tcp --port 22 --cidr "$MY_IP/32"

aws ec2 authorize-security-group-ingress `
  --group-id $EC2_SG `
  --protocol tcp --port 80 --cidr "0.0.0.0/0"

Write-Host "EC2 App SG: $EC2_SG"

# Create RDS security group
$RDS_SG = aws ec2 create-security-group `
  --group-name rds-sg `
  --description "Allow MySQL from EC2 app server only" `
  --vpc-id $VPC_ID `
  --query "GroupId" --output text

aws ec2 authorize-security-group-ingress `
  --group-id $RDS_SG `
  --protocol tcp --port 3306 `
  --source-group $EC2_SG

Write-Host "RDS SG: $RDS_SG"

# Verify both
aws ec2 describe-security-groups `
  --group-ids $EC2_SG $RDS_SG `
  --query "SecurityGroups[*].{Name:GroupName,Rules:IpPermissions[*].{Port:FromPort,Source:IpRanges[0].CidrIp}}" `
  --output table
```

✅ **Checkpoint 2** — Security groups created with chained rules.

---

## Part 3 — Create RDS Subnet Group

### Console Steps

1. RDS → Subnet groups → Create DB subnet group
2. Name: `rds-subnet-group` | Description: `Private subnets for RDS across two AZs` | VPC: `my-custom-vpc`
3. AZs: `us-east-1a`, `us-east-1b`
4. Subnets: `private-subnet-a` (10.0.3.0/24), `private-subnet-b` (10.0.4.0/24)

### CLI Steps (PowerShell)

```powershell
aws rds create-db-subnet-group `
  --db-subnet-group-name rds-subnet-group `
  --db-subnet-group-description "Private subnets for RDS across two AZs" `
  --subnet-ids $PRI_SUBNET_A $PRI_SUBNET_B `
  --tags Key=Name,Value=rds-subnet-group

# Verify
aws rds describe-db-subnet-groups `
  --db-subnet-group-name rds-subnet-group `
  --query "DBSubnetGroups[0].{Name:DBSubnetGroupName,VPC:VpcId,Status:SubnetGroupStatus,Subnets:Subnets[*].SubnetIdentifier}" `
  --output table
```

✅ **Checkpoint 3** — RDS subnet group created. Status: `Complete`.

---

## Part 4 — Store DB Credentials in Secrets Manager

> [!IMPORTANT]
> Never hardcode database passwords. Password rules — do NOT use: `@`, `/`, `"`, `\` (these break MySQL connection strings).

### Console Steps

1. Secrets Manager → Store a new secret
2. Secret type: Credentials for Amazon RDS database
3. Username: `admin` | Password: `MyDB#Secure2024!`
4. Secret name: `rds/myapp/credentials`
5. Copy the Secret ARN

### CLI Steps (PowerShell)

```powershell
$SECRET_ARN = aws secretsmanager create-secret `
  --name "rds/myapp/credentials" `
  --description "RDS MySQL admin credentials for Project 6" `
  --secret-string '{
    "username": "admin",
    "password": "MyDB#Secure2024!",
    "engine": "mysql",
    "port": 3306,
    "dbname": "appdb"
  }' `
  --query "ARN" --output text

Write-Host "Secret ARN: $SECRET_ARN"

# Verify
aws secretsmanager describe-secret `
  --secret-id "rds/myapp/credentials" `
  --query "{Name:Name,ARN:ARN,LastChanged:LastChangedDate}" `
  --output table
```

✅ **Checkpoint 4** — Credentials stored securely.

---

## Part 5 — Launch RDS MySQL Instance

### Console Steps

1. RDS → Create database → Standard create
2. Engine: MySQL 8.0.x | Template: Free tier
3. DB identifier: `myapp-database` | Master: `admin` / `MyDB#Secure2024!`
4. Instance: `db.t3.micro` | Storage: 20 GiB gp2 (disable autoscaling)
5. VPC: `my-custom-vpc` | Subnet group: `rds-subnet-group` | Public access: No | SG: `rds-sg`
6. Initial database: `appdb` | Backups: 1 day | Encryption: Enable

⏳ **Wait 5–10 minutes** — Status changes: `creating → backing-up → available`

### CLI Steps (PowerShell)

```powershell
aws rds create-db-instance `
  --db-instance-identifier myapp-database `
  --db-instance-class db.t3.micro `
  --engine mysql `
  --engine-version 8.0 `
  --master-username admin `
  --master-user-password "MyDB#Secure2024!" `
  --db-name appdb `
  --vpc-security-group-ids $RDS_SG `
  --db-subnet-group-name rds-subnet-group `
  --allocated-storage 20 `
  --storage-type gp2 `
  --no-multi-az `
  --no-publicly-accessible `
  --backup-retention-period 1 `
  --no-deletion-protection `
  --tags Key=Name,Value=myapp-database

Write-Host "RDS creation initiated. Waiting for availability..."
Write-Host "This takes 5-10 minutes..."

aws rds wait db-instance-available `
  --db-instance-identifier myapp-database
Write-Host "RDS is available!"

# Get the endpoint
$RDS_ENDPOINT = aws rds describe-db-instances `
  --db-instance-identifier myapp-database `
  --query "DBInstances[0].Endpoint.Address" `
  --output text

Write-Host "RDS Endpoint: $RDS_ENDPOINT"
```

✅ **Checkpoint 5** — RDS MySQL running. Endpoint saved.

---

## Part 6 — Launch EC2 App Server

### Console Steps

1. EC2 → Launch instances
2. Name: `app-server` | AMI: Amazon Linux 2023 | Type: `t2.micro`
3. Key pair: `aws-ec2-keypair` | VPC: `my-custom-vpc` | Subnet: `public-subnet-a` | Auto-assign Public IP: Enable | SG: `ec2-app-sg`
4. Advanced details → User data:

```bash
#!/bin/bash
yum update -y
yum install -y mysql
yum install -y httpd
systemctl start httpd
systemctl enable httpd

echo "<html>
<head><title>App Server</title></head>
<body style='font-family:Arial;text-align:center;padding:60px;background:#f0f2f5'>
<h1 style='color:#232f3e'>App Server Running</h1>
<p style='color:#555'>EC2 + RDS Two-Tier Architecture — Project 6</p>
<p style='color:#28a745'>MySQL client installed and ready</p>
</body>
</html>" > /var/www/html/index.html
```

### CLI Steps (PowerShell)

```powershell
$AMI_ID = aws ec2 describe-images `
  --owners amazon `
  --filters "Name=name,Values=al2023-ami-*-x86_64" `
    "Name=state,Values=available" `
  --query "sort_by(Images,&CreationDate)[-1].ImageId" `
  --output text

$USER_DATA = @"
#!/bin/bash
yum update -y
yum install -y mysql httpd
systemctl start httpd
systemctl enable httpd
echo '<html><body style="font-family:Arial;text-align:center;padding:60px">
<h1>App Server Running - Project 6</h1>
<p>MySQL client installed and ready to connect to RDS</p>
</body></html>' > /var/www/html/index.html
"@

$USER_DATA | Out-File -FilePath "userdata-app.sh" -Encoding ascii

$APP_INSTANCE_ID = aws ec2 run-instances `
  --image-id $AMI_ID `
  --instance-type t2.micro `
  --key-name aws-ec2-keypair `
  --subnet-id $PUB_SUBNET_A `
  --security-group-ids $EC2_SG `
  --associate-public-ip-address `
  --user-data file://userdata-app.sh `
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=app-server}]" `
  --query "Instances[0].InstanceId" `
  --output text

Write-Host "App Server Instance ID: $APP_INSTANCE_ID"

aws ec2 wait instance-status-ok --instance-ids $APP_INSTANCE_ID
Write-Host "App server ready"

$APP_PUBLIC_IP = aws ec2 describe-instances `
  --instance-ids $APP_INSTANCE_ID `
  --query "Reservations[0].Instances[0].PublicIpAddress" `
  --output text

Write-Host "App Server Public IP: $APP_PUBLIC_IP"
```

✅ **Checkpoint 6** — EC2 running with public IP. Apache serving status page.

---

## Part 7 — Connect EC2 to RDS

### SSH into EC2

**PuTTY:**
- Host: `ec2-user@YOUR_APP_SERVER_PUBLIC_IP`
- Port: 22
- Key: `aws-ec2-keypair.ppk`

### Connect to MySQL

```bash
mysql --version
# Expected: mysql  Ver 8.0.x

mysql -h YOUR_RDS_ENDPOINT \
      -P 3306 \
      -u admin \
      -p
# Password: MyDB#Secure2024!
```

### Run MySQL Commands

```sql
-- Check current database
SELECT DATABASE();

-- List all databases
SHOW DATABASES;

-- Use application database
USE appdb;

-- Create sample table
CREATE TABLE users (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    role        VARCHAR(50)  DEFAULT 'user',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (name, email, role) VALUES
  ('Vinay Kumar',    'vinay@example.com',   'admin'),
  ('AWS Engineer',   'aws@example.com',     'developer'),
  ('Cloud Learner',  'cloud@example.com',   'user');

-- Query the data
SELECT * FROM users;

-- Count users
SELECT COUNT(*) AS total_users FROM users;

-- Filter by role
SELECT name, email FROM users WHERE role = 'admin';

-- Verify we are on RDS
SELECT VERSION();
SELECT @@hostname;

-- Show all tables
SHOW TABLES;

-- Exit
EXIT;
```

### Attach IAM Role for Secrets Manager (Bonus)

```powershell
# From PowerShell — create and attach IAM role

# Create role
aws iam create-role `
  --role-name ec2-app-role `
  --assume-role-policy-document '{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Principal":{"Service":"ec2.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }]
  }'

# Attach AWS managed SSM policy
aws iam attach-role-policy `
  --role-name ec2-app-role `
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Add custom Secrets Manager policy
$ENHANCED_POLICY = '{
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
}'

aws iam put-role-policy `
  --role-name ec2-app-role `
  --policy-name secrets-manager-access `
  --policy-document $ENHANCED_POLICY

# Create instance profile
aws iam create-instance-profile `
  --instance-profile-name ec2-app-profile

aws iam add-role-to-instance-profile `
  --instance-profile-name ec2-app-profile `
  --role-name ec2-app-role

# Attach to EC2
aws ec2 associate-iam-instance-profile `
  --instance-id $APP_INSTANCE_ID `
  --iam-instance-profile Name=ec2-app-profile

Write-Host "IAM role attached. Wait 2 minutes then test from EC2."
```

Then from EC2:

```bash
aws secretsmanager get-secret-value \
  --secret-id "rds/myapp/credentials" \
  --region us-east-1 \
  --query "SecretString" \
  --output text
```

✅ **Checkpoint 7** — MySQL queries return data. `SELECT @@hostname` confirms RDS connection.

---

## Part 8 — Monitor RDS via CloudWatch

```powershell
# Check RDS CPU utilization
aws cloudwatch get-metric-statistics `
  --namespace AWS/RDS `
  --metric-name CPUUtilization `
  --dimensions Name=DBInstanceIdentifier,Value=myapp-database `
  --start-time (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ssZ") `
  --end-time (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ") `
  --period 300 `
  --statistics Average `
  --query "Datapoints[*].{Time:Timestamp,CPU:Average}" `
  --output table

# Check database connections
aws cloudwatch get-metric-statistics `
  --namespace AWS/RDS `
  --metric-name DatabaseConnections `
  --dimensions Name=DBInstanceIdentifier,Value=myapp-database `
  --start-time (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ssZ") `
  --end-time (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ") `
  --period 300 `
  --statistics Average `
  --query "Datapoints[*].{Time:Timestamp,Connections:Average}" `
  --output table

# Check free storage space
aws cloudwatch get-metric-statistics `
  --namespace AWS/RDS `
  --metric-name FreeStorageSpace `
  --dimensions Name=DBInstanceIdentifier,Value=myapp-database `
  --start-time (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ssZ") `
  --end-time (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ") `
  --period 300 `
  --statistics Average `
  --query "Datapoints[*].{Time:Timestamp,FreeBytes:Average}" `
  --output table
```

Console: RDS → Databases → `myapp-database` → Monitoring tab

---

## Part 9 — Key RDS CLI Operations

```powershell
# Describe your RDS instance
aws rds describe-db-instances `
  --db-instance-identifier myapp-database `
  --query "DBInstances[0].{ID:DBInstanceIdentifier,Class:DBInstanceClass,Engine:Engine,Status:DBInstanceStatus,Endpoint:Endpoint.Address,Storage:AllocatedStorage}" `
  --output table

# Create a manual snapshot
aws rds create-db-snapshot `
  --db-instance-identifier myapp-database `
  --db-snapshot-identifier myapp-manual-snapshot-$(Get-Date -Format 'yyyyMMdd')

# List all snapshots
aws rds describe-db-snapshots `
  --db-instance-identifier myapp-database `
  --query "DBSnapshots[*].{ID:DBSnapshotIdentifier,Status:Status,Created:SnapshotCreateTime}" `
  --output table

# Stop RDS instance temporarily (saves cost — max 7 days)
aws rds stop-db-instance --db-instance-identifier myapp-database

# Start RDS instance again
aws rds start-db-instance --db-instance-identifier myapp-database

# Modify RDS (e.g., change backup retention)
aws rds modify-db-instance `
  --db-instance-identifier myapp-database `
  --backup-retention-period 3 `
  --apply-immediately
```

---

## Part 10 — Full Cleanup

See the [Cleanup Guide](cleanup-guide.md) for the complete ordered deletion sequence with explanations and variable recovery steps.