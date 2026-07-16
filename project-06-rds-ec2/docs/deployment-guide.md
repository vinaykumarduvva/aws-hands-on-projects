# Comprehensive Deployment Guide

This guide details the complete process for deploying this project's resources.

## 🏗️ PART 1 — REBUILDS THE CUSTOM VPC ARCHITECTURE

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **VPC** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 6 — Script 01: VPC Setup
# Creates the full VPC infrastructure for the RDS + EC2 two-tier project
# =============================================================================

echo -e "\e[36m=== Project 6 — VPC Setup ===\e[0m"
echo ""

# Pre-flight check
echo -e "\e[33mRunning pre-flight checks...\e[0m"
aws sts get-caller-identity | Out-Null
if ($LASTEXITCODE -ne 0) {
echo -e "\e[31mERROR: AWS CLI not configured. Run 'aws configure' first.\e[0m"
    exit 1
}

REGION=$(aws configure get region)
if ($REGION -ne "us-east-1") {
echo -e "\e[33mWARNING: Region is $REGION — expected us-east-1\e[0m"
echo "Set with: aws configure set region us-east-1"
}

echo -e "\e[32mPre-flight OK — deploying in region: $REGION\e[0m"
echo ""

# ── VPC ───────────────────────────────────────────────────────────────────────
echo -e "\e[33m[1/9] Creating VPC...\e[0m"

VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=my-custom-vpc}]" \
    --query "Vpc.VpcId" --output text)

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

echo -e "\e[32mVPC created: $VPC_ID\e[0m"

# ── SUBNETS ───────────────────────────────────────────────────────────────────
echo -e "\e[33m[2/9] Creating subnets...\e[0m"

PUB_SUBNET_A=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-a}]" \
    --query "Subnet.SubnetId" --output text)

PUB_SUBNET_B=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.2.0/24 \
    --availability-zone us-east-1b \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-b}]" \
    --query "Subnet.SubnetId" --output text)

PRI_SUBNET_A=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.3.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-a}]" \
    --query "Subnet.SubnetId" --output text)

PRI_SUBNET_B=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.4.0/24 \
    --availability-zone us-east-1b \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-b}]" \
    --query "Subnet.SubnetId" --output text)

# Enable auto-assign public IP for public subnets
aws ec2 modify-subnet-attribute --subnet-id $PUB_SUBNET_A --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $PUB_SUBNET_B --map-public-ip-on-launch

echo -e "\e[32mSubnets created:\e[0m"
echo "  public-subnet-a  (10.0.1.0/24 us-east-1a): $PUB_SUBNET_A"
echo "  public-subnet-b  (10.0.2.0/24 us-east-1b): $PUB_SUBNET_B"
echo "  private-subnet-a (10.0.3.0/24 us-east-1a): $PRI_SUBNET_A"
echo "  private-subnet-b (10.0.4.0/24 us-east-1b): $PRI_SUBNET_B"

# ── INTERNET GATEWAY ──────────────────────────────────────────────────────────
echo -e "\e[33m[3/9] Creating Internet Gateway...\e[0m"

IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-vpc-igw}]" \
    --query "InternetGateway.InternetGatewayId" --output text)

aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --vpc-id $VPC_ID

echo -e "\e[32mInternet Gateway created and attached: $IGW_ID\e[0m"

# ── PUBLIC ROUTE TABLE ────────────────────────────────────────────────────────
echo -e "\e[33m[4/9] Creating public route table...\e[0m"

PUB_RT_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=public-route-table}]" \
    --query "RouteTable.RouteTableId" --output text)

aws ec2 create-route \
    --route-table-id $PUB_RT_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID | Out-Null

aws ec2 associate-route-table \
    --route-table-id $PUB_RT_ID \
    --subnet-id $PUB_SUBNET_A | Out-Null

aws ec2 associate-route-table \
    --route-table-id $PUB_RT_ID \
    --subnet-id $PUB_SUBNET_B | Out-Null

echo -e "\e[32mPublic route table created: $PUB_RT_ID\e[0m"

# ── PRIVATE ROUTE TABLE ───────────────────────────────────────────────────────
echo -e "\e[33m[5/9] Creating private route table...\e[0m"

PRI_RT_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=private-route-table}]" \
    --query "RouteTable.RouteTableId" --output text)

aws ec2 associate-route-table \
    --route-table-id $PRI_RT_ID \
    --subnet-id $PRI_SUBNET_A | Out-Null

aws ec2 associate-route-table \
    --route-table-id $PRI_RT_ID \
    --subnet-id $PRI_SUBNET_B | Out-Null

echo -e "\e[32mPrivate route table created: $PRI_RT_ID\e[0m"

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== VPC Setup Complete ===\e[0m"
echo ""
echo "Resource IDs (save these for subsequent scripts):"
echo "  VPC_ID        = $VPC_ID"
echo "  PUB_SUBNET_A  = $PUB_SUBNET_A"
echo "  PUB_SUBNET_B  = $PUB_SUBNET_B"
echo "  PRI_SUBNET_A  = $PRI_SUBNET_A"
echo "  PRI_SUBNET_B  = $PRI_SUBNET_B"
echo "  IGW_ID        = $IGW_ID"
echo "  PUB_RT_ID     = $PUB_RT_ID"
echo "  PRI_RT_ID     = $PRI_RT_ID"
echo ""
echo -e "\e[36mNext step: Run 02-security-groups.ps1\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 6 — Script 01: VPC Setup
# Creates the full VPC infrastructure for the RDS + EC2 two-tier project
# =============================================================================

Write-Host "=== Project 6 — VPC Setup ===" -ForegroundColor Cyan
Write-Host ""

# Pre-flight check
Write-Host "Running pre-flight checks..." -ForegroundColor Yellow
aws sts get-caller-identity | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: AWS CLI not configured. Run 'aws configure' first." -ForegroundColor Red
    exit 1
}

$REGION = aws configure get region
if ($REGION -ne "us-east-1") {
    Write-Host "WARNING: Region is $REGION — expected us-east-1" -ForegroundColor Yellow
    Write-Host "Set with: aws configure set region us-east-1"
}

Write-Host "Pre-flight OK — deploying in region: $REGION" -ForegroundColor Green
Write-Host ""

# ── VPC ───────────────────────────────────────────────────────────────────────
Write-Host "[1/9] Creating VPC..." -ForegroundColor Yellow

$VPC_ID = aws ec2 create-vpc `
    --cidr-block 10.0.0.0/16 `
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=my-custom-vpc}]" `
    --query "Vpc.VpcId" --output text

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

Write-Host "VPC created: $VPC_ID" -ForegroundColor Green

# ── SUBNETS ───────────────────────────────────────────────────────────────────
Write-Host "[2/9] Creating subnets..." -ForegroundColor Yellow

$PUB_SUBNET_A = aws ec2 create-subnet `
    --vpc-id $VPC_ID `
    --cidr-block 10.0.1.0/24 `
    --availability-zone us-east-1a `
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-a}]" `
    --query "Subnet.SubnetId" --output text

$PUB_SUBNET_B = aws ec2 create-subnet `
    --vpc-id $VPC_ID `
    --cidr-block 10.0.2.0/24 `
    --availability-zone us-east-1b `
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-b}]" `
    --query "Subnet.SubnetId" --output text

$PRI_SUBNET_A = aws ec2 create-subnet `
    --vpc-id $VPC_ID `
    --cidr-block 10.0.3.0/24 `
    --availability-zone us-east-1a `
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-a}]" `
    --query "Subnet.SubnetId" --output text

$PRI_SUBNET_B = aws ec2 create-subnet `
    --vpc-id $VPC_ID `
    --cidr-block 10.0.4.0/24 `
    --availability-zone us-east-1b `
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-b}]" `
    --query "Subnet.SubnetId" --output text

# Enable auto-assign public IP for public subnets
aws ec2 modify-subnet-attribute --subnet-id $PUB_SUBNET_A --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $PUB_SUBNET_B --map-public-ip-on-launch

Write-Host "Subnets created:" -ForegroundColor Green
Write-Host "  public-subnet-a  (10.0.1.0/24 us-east-1a): $PUB_SUBNET_A"
Write-Host "  public-subnet-b  (10.0.2.0/24 us-east-1b): $PUB_SUBNET_B"
Write-Host "  private-subnet-a (10.0.3.0/24 us-east-1a): $PRI_SUBNET_A"
Write-Host "  private-subnet-b (10.0.4.0/24 us-east-1b): $PRI_SUBNET_B"

# ── INTERNET GATEWAY ──────────────────────────────────────────────────────────
Write-Host "[3/9] Creating Internet Gateway..." -ForegroundColor Yellow

$IGW_ID = aws ec2 create-internet-gateway `
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-vpc-igw}]" `
    --query "InternetGateway.InternetGatewayId" --output text

aws ec2 attach-internet-gateway `
    --internet-gateway-id $IGW_ID `
    --vpc-id $VPC_ID

Write-Host "Internet Gateway created and attached: $IGW_ID" -ForegroundColor Green

# ── PUBLIC ROUTE TABLE ────────────────────────────────────────────────────────
Write-Host "[4/9] Creating public route table..." -ForegroundColor Yellow

$PUB_RT_ID = aws ec2 create-route-table `
    --vpc-id $VPC_ID `
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=public-route-table}]" `
    --query "RouteTable.RouteTableId" --output text

aws ec2 create-route `
    --route-table-id $PUB_RT_ID `
    --destination-cidr-block 0.0.0.0/0 `
    --gateway-id $IGW_ID | Out-Null

aws ec2 associate-route-table `
    --route-table-id $PUB_RT_ID `
    --subnet-id $PUB_SUBNET_A | Out-Null

aws ec2 associate-route-table `
    --route-table-id $PUB_RT_ID `
    --subnet-id $PUB_SUBNET_B | Out-Null

Write-Host "Public route table created: $PUB_RT_ID" -ForegroundColor Green

# ── PRIVATE ROUTE TABLE ───────────────────────────────────────────────────────
Write-Host "[5/9] Creating private route table..." -ForegroundColor Yellow

$PRI_RT_ID = aws ec2 create-route-table `
    --vpc-id $VPC_ID `
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=private-route-table}]" `
    --query "RouteTable.RouteTableId" --output text

aws ec2 associate-route-table `
    --route-table-id $PRI_RT_ID `
    --subnet-id $PRI_SUBNET_A | Out-Null

aws ec2 associate-route-table `
    --route-table-id $PRI_RT_ID `
    --subnet-id $PRI_SUBNET_B | Out-Null

Write-Host "Private route table created: $PRI_RT_ID" -ForegroundColor Green

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== VPC Setup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resource IDs (save these for subsequent scripts):"
Write-Host "  VPC_ID        = $VPC_ID"
Write-Host "  PUB_SUBNET_A  = $PUB_SUBNET_A"
Write-Host "  PUB_SUBNET_B  = $PUB_SUBNET_B"
Write-Host "  PRI_SUBNET_A  = $PRI_SUBNET_A"
Write-Host "  PRI_SUBNET_B  = $PRI_SUBNET_B"
Write-Host "  IGW_ID        = $IGW_ID"
Write-Host "  PUB_RT_ID     = $PUB_RT_ID"
Write-Host "  PRI_RT_ID     = $PRI_RT_ID"
Write-Host ""
Write-Host "Next step: Run 02-security-groups.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 2 — CONFIGURES SECURITY GROUP CHAINING

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **EC2** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 6 — Script 02: Security Groups
# Creates ec2-app-sg and rds-sg with security group chaining
# =============================================================================

echo -e "\e[36m=== Project 6 — Security Groups ===\e[0m"
echo ""

# Verify VPC_ID is set
if (-not $VPC_ID) {
echo -e "\e[31mERROR: \$VPC_ID is not set. Run 01-vpc-setup.ps1 first.\e[0m"
    exit 1
}

# Detect current public IP
echo -e "\e[33m[1/3] Detecting your public IP...\e[0m"
MY_IP=(Invoke-WebRequest -Uri "https://checkip.amazonaws.com" -UseBasicParsing).Content.Trim()
echo -e "\e[32mYour IP: $MY_IP\e[0m"

# ── EC2 APP SECURITY GROUP ────────────────────────────────────────────────────
echo -e "\e[33m[2/3] Creating ec2-app-sg...\e[0m"

EC2_SG=$(aws ec2 create-security-group \
    --group-name ec2-app-sg \
    --description "Allow SSH and HTTP for app server" \
    --vpc-id $VPC_ID \
    --query "GroupId" --output text)

# SSH from your IP only
aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG \
    --protocol tcp \
    --port 22 \
    --cidr "$MY_IP/32"

# HTTP from anywhere
aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG \
    --protocol tcp \
    --port 80 \
    --cidr "0.0.0.0/0"

echo -e "\e[32mec2-app-sg created: $EC2_SG\e[0m"
echo "  Inbound: SSH (22) from $MY_IP/32"
echo "  Inbound: HTTP (80) from 0.0.0.0/0"

# ── RDS SECURITY GROUP ────────────────────────────────────────────────────────
echo -e "\e[33m[3/3] Creating rds-sg...\e[0m"

RDS_SG=$(aws ec2 create-security-group \
    --group-name rds-sg \
    --description "Allow MySQL from EC2 app server only" \
    --vpc-id $VPC_ID \
    --query "GroupId" --output text)

# MySQL ONLY from the EC2 app security group — no CIDR rule
aws ec2 authorize-security-group-ingress \
    --group-id $RDS_SG \
    --protocol tcp \
    --port 3306 \
    --source-group $EC2_SG

echo -e "\e[32mrds-sg created: $RDS_SG\e[0m"
echo "  Inbound: MySQL (3306) from ec2-app-sg ($EC2_SG) only"

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mVerifying security groups...\e[0m"

aws ec2 describe-security-groups \
    --group-ids $EC2_SG $RDS_SG \
    --query "SecurityGroups[*].{Name:GroupName,ID:GroupId,Rules:IpPermissions[*].{Port:FromPort,Source:join('',IpRanges[*].CidrIp)}}" \
    --output table

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== Security Groups Complete ===\e[0m"
echo ""
echo "  EC2_SG = $EC2_SG  (ec2-app-sg)"
echo "  RDS_SG = $RDS_SG  (rds-sg)"
echo ""
echo "Security group chaining summary:"
echo "  Internet → EC2 (port 22/80) → RDS (port 3306) → nowhere else"
echo ""
echo -e "\e[36mNext step: Run 03-rds-subnet-group.ps1\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 6 — Script 02: Security Groups
# Creates ec2-app-sg and rds-sg with security group chaining
# =============================================================================

Write-Host "=== Project 6 — Security Groups ===" -ForegroundColor Cyan
Write-Host ""

# Verify VPC_ID is set
if (-not $VPC_ID) {
    Write-Host "ERROR: \$VPC_ID is not set. Run 01-vpc-setup.ps1 first." -ForegroundColor Red
    exit 1
}

# Detect current public IP
Write-Host "[1/3] Detecting your public IP..." -ForegroundColor Yellow
$MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" -UseBasicParsing).Content.Trim()
Write-Host "Your IP: $MY_IP" -ForegroundColor Green

# ── EC2 APP SECURITY GROUP ────────────────────────────────────────────────────
Write-Host "[2/3] Creating ec2-app-sg..." -ForegroundColor Yellow

$EC2_SG = aws ec2 create-security-group `
    --group-name ec2-app-sg `
    --description "Allow SSH and HTTP for app server" `
    --vpc-id $VPC_ID `
    --query "GroupId" --output text

# SSH from your IP only
aws ec2 authorize-security-group-ingress `
    --group-id $EC2_SG `
    --protocol tcp `
    --port 22 `
    --cidr "$MY_IP/32"

# HTTP from anywhere
aws ec2 authorize-security-group-ingress `
    --group-id $EC2_SG `
    --protocol tcp `
    --port 80 `
    --cidr "0.0.0.0/0"

Write-Host "ec2-app-sg created: $EC2_SG" -ForegroundColor Green
Write-Host "  Inbound: SSH (22) from $MY_IP/32"
Write-Host "  Inbound: HTTP (80) from 0.0.0.0/0"

# ── RDS SECURITY GROUP ────────────────────────────────────────────────────────
Write-Host "[3/3] Creating rds-sg..." -ForegroundColor Yellow

$RDS_SG = aws ec2 create-security-group `
    --group-name rds-sg `
    --description "Allow MySQL from EC2 app server only" `
    --vpc-id $VPC_ID `
    --query "GroupId" --output text

# MySQL ONLY from the EC2 app security group — no CIDR rule
aws ec2 authorize-security-group-ingress `
    --group-id $RDS_SG `
    --protocol tcp `
    --port 3306 `
    --source-group $EC2_SG

Write-Host "rds-sg created: $RDS_SG" -ForegroundColor Green
Write-Host "  Inbound: MySQL (3306) from ec2-app-sg ($EC2_SG) only"

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying security groups..." -ForegroundColor Yellow

aws ec2 describe-security-groups `
    --group-ids $EC2_SG $RDS_SG `
    --query "SecurityGroups[*].{Name:GroupName,ID:GroupId,Rules:IpPermissions[*].{Port:FromPort,Source:join('',IpRanges[*].CidrIp)}}" `
    --output table

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Security Groups Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  EC2_SG = $EC2_SG  (ec2-app-sg)"
Write-Host "  RDS_SG = $RDS_SG  (rds-sg)"
Write-Host ""
Write-Host "Security group chaining summary:"
Write-Host "  Internet → EC2 (port 22/80) → RDS (port 3306) → nowhere else"
Write-Host ""
Write-Host "Next step: Run 03-rds-subnet-group.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 3 — CREATES DB SUBNET GROUP ACROSS 2 AZS

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **VPC** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 6 — Script 03: RDS Subnet Group
# Creates the DB subnet group spanning both private subnets across two AZs
# =============================================================================

echo -e "\e[36m=== Project 6 — RDS Subnet Group ===\e[0m"
echo ""

if (-not $PRI_SUBNET_A -or -not $PRI_SUBNET_B) {
echo -e "\e[31mERROR: Private subnet IDs not set. Run 01-vpc-setup.ps1 first.\e[0m"
    exit 1
}

echo -e "\e[33mUsing private subnets:\e[0m"
echo "  private-subnet-a: $PRI_SUBNET_A (us-east-1a)"
echo "  private-subnet-b: $PRI_SUBNET_B (us-east-1b)"
echo ""

echo -e "\e[33mCreating rds-subnet-group...\e[0m"

aws rds create-db-subnet-group \
    --db-subnet-group-name rds-subnet-group \
    --db-subnet-group-description "Private subnets for RDS across two AZs" \
    --subnet-ids $PRI_SUBNET_A $PRI_SUBNET_B \
    --tags Key=Name,Value=rds-subnet-group | Out-Null

# Verify
echo -e "\e[33mVerifying subnet group...\e[0m"
aws rds describe-db-subnet-groups \
    --db-subnet-group-name rds-subnet-group \
    --query "DBSubnetGroups[0].{Name:DBSubnetGroupName,VPC:VpcId,Status:SubnetGroupStatus,Subnets:Subnets[*].SubnetIdentifier}" \
    --output table

echo ""
echo -e "\e[36m=== RDS Subnet Group Complete ===\e[0m"
echo "  Name:    rds-subnet-group"
echo "  Subnets: $PRI_SUBNET_A, $PRI_SUBNET_B"
echo "  AZs:     us-east-1a, us-east-1b"
echo ""
echo "Note: RDS requires subnet groups spanning 2+ AZs even for single-AZ instances."
echo ""
echo -e "\e[36mNext step: Run 04-secrets-manager.ps1\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 6 — Script 03: RDS Subnet Group
# Creates the DB subnet group spanning both private subnets across two AZs
# =============================================================================

Write-Host "=== Project 6 — RDS Subnet Group ===" -ForegroundColor Cyan
Write-Host ""

if (-not $PRI_SUBNET_A -or -not $PRI_SUBNET_B) {
    Write-Host "ERROR: Private subnet IDs not set. Run 01-vpc-setup.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "Using private subnets:" -ForegroundColor Yellow
Write-Host "  private-subnet-a: $PRI_SUBNET_A (us-east-1a)"
Write-Host "  private-subnet-b: $PRI_SUBNET_B (us-east-1b)"
Write-Host ""

Write-Host "Creating rds-subnet-group..." -ForegroundColor Yellow

aws rds create-db-subnet-group `
    --db-subnet-group-name rds-subnet-group `
    --db-subnet-group-description "Private subnets for RDS across two AZs" `
    --subnet-ids $PRI_SUBNET_A $PRI_SUBNET_B `
    --tags Key=Name,Value=rds-subnet-group | Out-Null

# Verify
Write-Host "Verifying subnet group..." -ForegroundColor Yellow
aws rds describe-db-subnet-groups `
    --db-subnet-group-name rds-subnet-group `
    --query "DBSubnetGroups[0].{Name:DBSubnetGroupName,VPC:VpcId,Status:SubnetGroupStatus,Subnets:Subnets[*].SubnetIdentifier}" `
    --output table

Write-Host ""
Write-Host "=== RDS Subnet Group Complete ===" -ForegroundColor Cyan
Write-Host "  Name:    rds-subnet-group"
Write-Host "  Subnets: $PRI_SUBNET_A, $PRI_SUBNET_B"
Write-Host "  AZs:     us-east-1a, us-east-1b"
Write-Host ""
Write-Host "Note: RDS requires subnet groups spanning 2+ AZs even for single-AZ instances."
Write-Host ""
Write-Host "Next step: Run 04-secrets-manager.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 4 — STORES DB CREDENTIALS SECURELY

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **AWS Console** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 6 - Script 04: Secrets Manager
# Stores RDS credentials securely - never hardcode passwords in scripts or code
# =============================================================================

echo -e "\e[36m=== Project 6 - Secrets Manager ===\e[0m"
echo ""

echo -e "\e[33mStoring RDS credentials in AWS Secrets Manager...\e[0m"
echo "Secret path: rds/myapp/credentials"
echo ""

# Store credentials as a JSON object
# NOTE: Update the password here if you used something different during RDS creation
SECRET_ARN=$(aws secretsmanager create-secret \
    --name "rds/myapp/credentials" \
    --description "RDS MySQL admin credentials for Project 6" \
    --secret-string '{)
    "username": "admin",
    "password": "<YOUR_RDS_PASSWORD>",
    "engine": "mysql",
    "port": 3306,
    "dbname": "appdb"
  }' \
    --query "ARN" --output text

if ($LASTEXITCODE -ne 0) {
echo -e "\e[33mSecret may already exist. Checking...\e[0m"

    SECRET_ARN=$(aws secretsmanager describe-secret \
        --secret-id "rds/myapp/credentials" \
        --query "ARN" --output text)

echo -e "\e[33mExisting secret found: $SECRET_ARN\e[0m"
}
else {
echo -e "\e[32mSecret created: $SECRET_ARN\e[0m"
}

# Verify
echo ""
echo -e "\e[33mVerifying secret...\e[0m"
aws secretsmanager describe-secret \
    --secret-id "rds/myapp/credentials" \
    --query '{Name:Name,ARN:ARN,Created:CreatedDate}' \
    --output table

echo ""
echo -e "\e[36m=== Secrets Manager Complete ===\e[0m"
echo ""
echo "  SECRET_ARN = $SECRET_ARN"
echo ""
echo "Password rules applied:"
echo "  8+ chars, uppercase + lowercase + numbers + special chars"
echo "  No special characters that break MySQL connection strings"
echo ""
echo "EC2 will retrieve this secret via IAM role in Part 7."
echo ""
echo -e "\e[36mNext step: Run 05-create-rds.ps1\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 6 - Script 04: Secrets Manager
# Stores RDS credentials securely - never hardcode passwords in scripts or code
# =============================================================================

Write-Host "=== Project 6 - Secrets Manager ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Storing RDS credentials in AWS Secrets Manager..." -ForegroundColor Yellow
Write-Host "Secret path: rds/myapp/credentials"
Write-Host ""

# Store credentials as a JSON object
# NOTE: Update the password here if you used something different during RDS creation
$SECRET_ARN = aws secretsmanager create-secret `
    --name "rds/myapp/credentials" `
    --description "RDS MySQL admin credentials for Project 6" `
    --secret-string '{
    "username": "admin",
    "password": "<YOUR_RDS_PASSWORD>",
    "engine": "mysql",
    "port": 3306,
    "dbname": "appdb"
  }' `
    --query "ARN" --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "Secret may already exist. Checking..." -ForegroundColor Yellow

    $SECRET_ARN = aws secretsmanager describe-secret `
        --secret-id "rds/myapp/credentials" `
        --query "ARN" --output text

    Write-Host "Existing secret found: $SECRET_ARN" -ForegroundColor Yellow
}
else {
    Write-Host "Secret created: $SECRET_ARN" -ForegroundColor Green
}

# Verify
Write-Host ""
Write-Host "Verifying secret..." -ForegroundColor Yellow
aws secretsmanager describe-secret `
    --secret-id "rds/myapp/credentials" `
    --query '{Name:Name,ARN:ARN,Created:CreatedDate}' `
    --output table

Write-Host ""
Write-Host "=== Secrets Manager Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  SECRET_ARN = $SECRET_ARN"
Write-Host ""
Write-Host "Password rules applied:"
Write-Host "  8+ chars, uppercase + lowercase + numbers + special chars"
Write-Host "  No special characters that break MySQL connection strings"
Write-Host ""
Write-Host "EC2 will retrieve this secret via IAM role in Part 7."
Write-Host ""
Write-Host "Next step: Run 05-create-rds.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 5 — PROVISIONS THE RDS MYSQL DATABASE

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **RDS** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
# Script not found: scripts/bash/05-rds-instance.sh
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Script not found: scripts/powershell/05-rds-instance.ps1
```

---

## 🏗️ PART 6 — CREATES EC2 IAM ROLE FOR SECRETS MANAGER

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **EC2** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
# Script not found: scripts/bash/06-iam-role.sh
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Script not found: scripts/powershell/06-iam-role.ps1
```

---

## 🏗️ PART 7 — LAUNCHES EC2 INSTANCE WITH USER DATA

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **EC2** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
# Script not found: scripts/bash/07-ec2-app.sh
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Script not found: scripts/powershell/07-ec2-app.ps1
```

---

## 🧹 TEARDOWN
To prevent recurring AWS charges, proceed to the `docs/cleanup-guide.md` to run the tear-down scripts.
