# Comprehensive Deployment Guide

This guide details the complete process for deploying this project's resources.

## 🏗️ PART 1 — VERIFY REGION, IDENTITY, AND KEY PAIR

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
# Project 10 — Script 01: Pre-Flight Check
# Verifies region, identity, and key pair before building infrastructure
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 10 — Pre-Flight Check ===\e[0m"
echo ""

# ── VERIFY REGION ─────────────────────────────────────────────────────────────
REGION=$(aws configure get region)
if [ "$REGION" != "ap-south-1" ]; then
    echo -e "\e[33m  Region is '$REGION' — setting to ap-south-1...\e[0m"
    aws configure set region ap-south-1
    REGION="ap-south-1"
fi
echo -e "\e[32m  Region: $REGION\e[0m"

# ── VERIFY IDENTITY ───────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[1/3] Verifying AWS identity...\e[0m"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
USER_ARN=$(aws sts get-caller-identity --query "Arn" --output text)
echo -e "\e[32m  Account ID: $ACCOUNT_ID\e[0m"
echo -e "\e[32m  User ARN:   $USER_ARN\e[0m"

# ── VERIFY KEY PAIR ───────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[2/3] Verifying key pair...\e[0m"
KEY_NAME=$(aws ec2 describe-key-pairs \
    --key-names aws-ec2-keypair \
    --query "KeyPairs[0].KeyName" --output text 2>/dev/null)

if [ "$KEY_NAME" == "aws-ec2-keypair" ]; then
    echo -e "\e[32m  Key pair: $KEY_NAME\e[0m"
else
    echo -e "\e[31m  Key pair 'aws-ec2-keypair' not found!\e[0m"
    echo -e "\e[33m  Create one: EC2 > Key Pairs > Create key pair\e[0m"
    exit 1
fi

# ── VERIFY DEFAULT VPC ────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[3/3] Verifying default VPC...\e[0m"
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --query "Vpcs[0].VpcId" --output text)

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    echo -e "\e[32m  Default VPC: $VPC_ID\e[0m"
else
    echo -e "\e[31m  No default VPC found in ap-south-1!\e[0m"
    exit 1
fi

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== Pre-Flight Complete ===\e[0m"
echo "  Region:     $REGION"
echo "  Account:    $ACCOUNT_ID"
echo "  Key Pair:   $KEY_NAME"
echo "  Default VPC: $VPC_ID"
echo ""
echo -e "\e[36mNext step: Run 02-setup-vpc-subnets.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 10 — Script 01: Pre-Flight Check
# Verifies region, identity, and key pair before building infrastructure
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Pre-Flight Check ===" -ForegroundColor Cyan
Write-Host ""

# ── VERIFY REGION ─────────────────────────────────────────────────────────────
$REGION = aws configure get region
if ($REGION -ne "ap-south-1") {
    Write-Host "  Region is '$REGION' — setting to ap-south-1..." -ForegroundColor Yellow
    aws configure set region ap-south-1
    $REGION = "ap-south-1"
}
Write-Host "  Region: $REGION" -ForegroundColor Green

# ── VERIFY IDENTITY ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[1/3] Verifying AWS identity..." -ForegroundColor Yellow
$IDENTITY = aws sts get-caller-identity | ConvertFrom-Json
$ACCOUNT_ID = $IDENTITY.Account
Write-Host "  Account ID: $ACCOUNT_ID" -ForegroundColor Green
Write-Host "  User ARN:   $($IDENTITY.Arn)" -ForegroundColor Green

# ── VERIFY KEY PAIR ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/3] Verifying key pair..." -ForegroundColor Yellow
$KEY_NAME = aws ec2 describe-key-pairs `
    --key-names aws-ec2-keypair `
    --query "KeyPairs[0].KeyName" --output text 2>$null

if ($KEY_NAME -eq "aws-ec2-keypair") {
    Write-Host "  Key pair: $KEY_NAME" -ForegroundColor Green
}
else {
    Write-Host "  Key pair 'aws-ec2-keypair' not found!" -ForegroundColor Red
    Write-Host "  Create one: EC2 > Key Pairs > Create key pair" -ForegroundColor Yellow
    exit 1
}

# ── VERIFY DEFAULT VPC ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Verifying default VPC..." -ForegroundColor Yellow
$VPC_ID = aws ec2 describe-vpcs `
    --filters "Name=isDefault,Values=true" `
    --query "Vpcs[0].VpcId" --output text

if ($VPC_ID -and $VPC_ID -ne "None") {
    Write-Host "  Default VPC: $VPC_ID" -ForegroundColor Green
}
else {
    Write-Host "  No default VPC found in ap-south-1!" -ForegroundColor Red
    exit 1
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Pre-Flight Complete ===" -ForegroundColor Cyan
Write-Host "  Region:     $REGION"
Write-Host "  Account:    $ACCOUNT_ID"
Write-Host "  Key Pair:   $KEY_NAME"
Write-Host "  Default VPC: $VPC_ID"
Write-Host ""
Write-Host "Next step: Run 02-setup-vpc-subnets.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 2 — DISCOVER DEFAULT VPC AND SELECT SUBNETS

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
# Project 10 — Script 02: Setup VPC and Subnets
# Discovers default VPC and selects two subnets in different AZs for ALB
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 10 — Setup VPC and Subnets ===\e[0m"
echo ""

# ── GET DEFAULT VPC ───────────────────────────────────────────────────────────
echo -e "\e[33m[1/3] Getting default VPC...\e[0m"
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --query "Vpcs[0].VpcId" --output text)

echo -e "\e[32m  VPC ID: $VPC_ID\e[0m"

# ── GET DEFAULT SUBNETS ───────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[2/3] Getting default subnets (one per AZ)...\e[0m"
SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    "Name=defaultForAz,Values=true" \
    --query "Subnets[*].SubnetId" \
    --output text)

SUBNET_LIST=($SUBNETS)
SUBNET_A=${SUBNET_LIST[0]}
SUBNET_B=${SUBNET_LIST[1]}

echo -e "\e[32m  Subnet A: $SUBNET_A\e[0m"
echo -e "\e[32m  Subnet B: $SUBNET_B\e[0m"

# ── VERIFY DIFFERENT AZs ─────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[3/3] Verifying subnets are in different AZs...\e[0m"
aws ec2 describe-subnets \
    --subnet-ids $SUBNET_A $SUBNET_B \
    --query "Subnets[*].{SubnetId:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock}" \
    --output table

# ── EXPORT VARIABLES ──────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== VPC Setup Complete ===\e[0m"
echo "  VPC_ID:   $VPC_ID"
echo "  SUBNET_A: $SUBNET_A"
echo "  SUBNET_B: $SUBNET_B"
echo ""
echo -e "\e[33m  ALB requires minimum 2 AZs for high availability.\e[0m"
echo ""
echo -e "\e[36mNext step: Run 03-create-security-groups.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 10 — Script 02: Setup VPC and Subnets
# Discovers default VPC and selects two subnets in different AZs for ALB
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Setup VPC and Subnets ===" -ForegroundColor Cyan
Write-Host ""

# ── GET DEFAULT VPC ───────────────────────────────────────────────────────────
Write-Host "[1/3] Getting default VPC..." -ForegroundColor Yellow
$VPC_ID = aws ec2 describe-vpcs `
    --filters "Name=isDefault,Values=true" `
    --query "Vpcs[0].VpcId" --output text

Write-Host "  VPC ID: $VPC_ID" -ForegroundColor Green

# ── GET DEFAULT SUBNETS ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/3] Getting default subnets (one per AZ)..." -ForegroundColor Yellow
$SUBNETS = aws ec2 describe-subnets `
    --filters "Name=vpc-id,Values=$VPC_ID" `
    "Name=defaultForAz,Values=true" `
    --query "Subnets[*].SubnetId" `
    --output text

$SUBNET_LIST = $SUBNETS -split '\s+'
$SUBNET_A = $SUBNET_LIST[0]
$SUBNET_B = $SUBNET_LIST[1]

Write-Host "  Subnet A: $SUBNET_A" -ForegroundColor Green
Write-Host "  Subnet B: $SUBNET_B" -ForegroundColor Green

# ── VERIFY DIFFERENT AZs ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Verifying subnets are in different AZs..." -ForegroundColor Yellow
aws ec2 describe-subnets `
    --subnet-ids $SUBNET_A $SUBNET_B `
    --query "Subnets[*].{SubnetId:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock}" `
    --output table

# ── EXPORT VARIABLES ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== VPC Setup Complete ===" -ForegroundColor Cyan
Write-Host "  VPC_ID:   $VPC_ID"
Write-Host "  SUBNET_A: $SUBNET_A"
Write-Host "  SUBNET_B: $SUBNET_B"
Write-Host ""
Write-Host "  ALB requires minimum 2 AZs for high availability." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run 03-create-security-groups.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 3 — CREATE ALB AND EC2 SECURITY GROUPS

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
# Project 10 — Script 03: Create Security Groups
# Creates ALB SG (HTTP from internet) and EC2 SG (HTTP from ALB only)
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 10 — Create Security Groups ===\e[0m"
echo ""

# ── PRE-REQUISITES ────────────────────────────────────────────────────────────
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --query "Vpcs[0].VpcId" --output text)

MY_IP=(Invoke-WebRequest -Uri "https://checkip.amazonaws.com" \
        -UseBasicParsing).Content.Trim()

echo -e "\e[32m  VPC: $VPC_ID\e[0m"
echo -e "\e[32m  My IP: $MY_IP\e[0m"
echo ""

# ── ALB SECURITY GROUP ────────────────────────────────────────────────────────
echo -e "\e[33m[1/2] Creating ALB Security Group...\e[0m"

ALB_SG=$(aws ec2 create-security-group \
    --group-name alb-sg \
    --description "ALB: allow HTTP from internet" \
    --vpc-id $VPC_ID \
    --query "GroupId" --output text)

# ALB accepts HTTP from anywhere
aws ec2 authorize-security-group-ingress \
    --group-id $ALB_SG \
    --protocol tcp --port 80 --cidr "0.0.0.0/0" | Out-Null

# ALB accepts HTTPS from anywhere (for future SSL)
aws ec2 authorize-security-group-ingress \
    --group-id $ALB_SG \
    --protocol tcp --port 443 --cidr "0.0.0.0/0" | Out-Null

echo -e "\e[32m  ALB SG: $ALB_SG\e[0m"
echo -e "\e[32m  Rules: HTTP(80) from 0.0.0.0/0, HTTPS(443) from 0.0.0.0/0\e[0m"

# ── EC2 SECURITY GROUP ────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[2/2] Creating EC2 Security Group...\e[0m"

EC2_SG=$(aws ec2 create-security-group \
    --group-name asg-ec2-sg \
    --description "EC2: allow HTTP from ALB only, SSH from My IP" \
    --vpc-id $VPC_ID \
    --query "GroupId" --output text)

# EC2 accepts HTTP only from ALB security group
aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG \
    --protocol tcp --port 80 \
    --source-group $ALB_SG | Out-Null

# EC2 accepts SSH from your IP for debugging
aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG \
    --protocol tcp --port 22 \
    --cidr "$MY_IP/32" | Out-Null

echo -e "\e[32m  EC2 SG: $EC2_SG\e[0m"
echo -e "\e[32m  Rules: HTTP(80) from ALB SG, SSH(22) from $MY_IP/32\e[0m"

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mVerifying security groups...\e[0m"
aws ec2 describe-security-groups \
    --group-ids $ALB_SG $EC2_SG \
    --query "SecurityGroups[*].{Name:GroupName,ID:GroupId,Description:Description}" \
    --output table

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== Security Groups Complete ===\e[0m"
echo "  ALB_SG: $ALB_SG  (HTTP/HTTPS from internet)"
echo "  EC2_SG: $EC2_SG  (HTTP from ALB, SSH from your IP)"
echo ""
echo -e "\e[33m  Key: EC2 only accepts HTTP from ALB — not from the internet directly.\e[0m"
echo ""
echo -e "\e[36mNext step: Run 04-create-launch-template.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 10 — Script 03: Create Security Groups
# Creates ALB SG (HTTP from internet) and EC2 SG (HTTP from ALB only)
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Create Security Groups ===" -ForegroundColor Cyan
Write-Host ""

# ── PRE-REQUISITES ────────────────────────────────────────────────────────────
$VPC_ID = aws ec2 describe-vpcs `
    --filters "Name=isDefault,Values=true" `
    --query "Vpcs[0].VpcId" --output text

$MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" `
        -UseBasicParsing).Content.Trim()

Write-Host "  VPC: $VPC_ID" -ForegroundColor Green
Write-Host "  My IP: $MY_IP" -ForegroundColor Green
Write-Host ""

# ── ALB SECURITY GROUP ────────────────────────────────────────────────────────
Write-Host "[1/2] Creating ALB Security Group..." -ForegroundColor Yellow

$ALB_SG = aws ec2 create-security-group `
    --group-name alb-sg `
    --description "ALB: allow HTTP from internet" `
    --vpc-id $VPC_ID `
    --query "GroupId" --output text

# ALB accepts HTTP from anywhere
aws ec2 authorize-security-group-ingress `
    --group-id $ALB_SG `
    --protocol tcp --port 80 --cidr "0.0.0.0/0" | Out-Null

# ALB accepts HTTPS from anywhere (for future SSL)
aws ec2 authorize-security-group-ingress `
    --group-id $ALB_SG `
    --protocol tcp --port 443 --cidr "0.0.0.0/0" | Out-Null

Write-Host "  ALB SG: $ALB_SG" -ForegroundColor Green
Write-Host "  Rules: HTTP(80) from 0.0.0.0/0, HTTPS(443) from 0.0.0.0/0" -ForegroundColor Green

# ── EC2 SECURITY GROUP ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/2] Creating EC2 Security Group..." -ForegroundColor Yellow

$EC2_SG = aws ec2 create-security-group `
    --group-name asg-ec2-sg `
    --description "EC2: allow HTTP from ALB only, SSH from My IP" `
    --vpc-id $VPC_ID `
    --query "GroupId" --output text

# EC2 accepts HTTP only from ALB security group
aws ec2 authorize-security-group-ingress `
    --group-id $EC2_SG `
    --protocol tcp --port 80 `
    --source-group $ALB_SG | Out-Null

# EC2 accepts SSH from your IP for debugging
aws ec2 authorize-security-group-ingress `
    --group-id $EC2_SG `
    --protocol tcp --port 22 `
    --cidr "$MY_IP/32" | Out-Null

Write-Host "  EC2 SG: $EC2_SG" -ForegroundColor Green
Write-Host "  Rules: HTTP(80) from ALB SG, SSH(22) from $MY_IP/32" -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying security groups..." -ForegroundColor Yellow
aws ec2 describe-security-groups `
    --group-ids $ALB_SG $EC2_SG `
    --query "SecurityGroups[*].{Name:GroupName,ID:GroupId,Description:Description}" `
    --output table

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Security Groups Complete ===" -ForegroundColor Cyan
Write-Host "  ALB_SG: $ALB_SG  (HTTP/HTTPS from internet)"
Write-Host "  EC2_SG: $EC2_SG  (HTTP from ALB, SSH from your IP)"
Write-Host ""
Write-Host "  Key: EC2 only accepts HTTP from ALB — not from the internet directly." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run 04-create-launch-template.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 4 — CREATE LAUNCH TEMPLATE WITH APACHE USER DATA

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
# Project 10 — Script 04: Create Launch Template
# Defines EC2 blueprint with Apache, stress tool, and custom HTML page
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 10 — Create Launch Template ===\e[0m"
echo ""

# ── PRE-REQUISITES ────────────────────────────────────────────────────────────
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" --output text)

EC2_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=asg-ec2-sg" \
  "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[0].GroupId" --output text)

echo -e "\e[32m  EC2 SG: $EC2_SG\e[0m"

# ── GET LATEST AMAZON LINUX 2023 AMI ──────────────────────────────────────────
echo ""
echo -e "\e[33m[1/3] Finding latest Amazon Linux 2023 AMI...\e[0m"

AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" \
  "Name=state,Values=available" \
  --region ap-south-1 \
  --query "sort_by(Images,&CreationDate)[-1].ImageId" \
  --output text)

echo -e "\e[32m  AMI: $AMI_ID\e[0m"

# ── PREPARE USER DATA ─────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[2/3] Preparing user data script...\e[0m"

USER_DATA=@'
#!/bin/bash
yum update -y
yum install -y httpd stress
systemctl start httpd
systemctl enable httpd
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
cat > /var/www/html/index.html << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <title>ASG Demo</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:Arial,sans-serif;background:linear-gradient(135deg,#232f3e,#1a73e8);
    min-height:100vh;display:flex;align-items:center;justify-content:center}
    .card{background:white;border-radius:16px;padding:40px;max-width:500px;
    width:90%;text-align:center;box-shadow:0 20px 60px rgba(0,0,0,.3)}
    .badge{background:#ff9900;color:white;padding:6px 16px;border-radius:20px;
    font-size:13px;display:inline-block;margin-bottom:20px}
    h1{color:#232f3e;margin-bottom:20px;font-size:24px}
    .info{background:#f0f7ff;border-radius:8px;padding:16px;margin:10px 0;text-align:left}
    .label{font-size:12px;color:#888;text-transform:uppercase}
    .value{font-size:16px;font-weight:bold;color:#232f3e}
    .healthy{background:#d4edda;color:#155724;border-radius:8px;padding:10px;
    margin-top:16px;font-weight:bold}
  </style>
</head>
<body>
  <div class="card">
    <span class="badge">Auto Scaling Group - Project 10</span>
    <h1>Load Balanced Instance</h1>
    <div class="info"><div class="label">Instance ID</div><div class="value">$INSTANCE_ID</div></div>
    <div class="info"><div class="label">Availability Zone</div><div class="value">$AZ</div></div>
    <div class="info"><div class="label">Private IP</div><div class="value">$PRIVATE_IP</div></div>
    <div class="info"><div class="label">Region</div><div class="value">ap-south-1 (Mumbai)</div></div>
    <div class="healthy">Instance Healthy - Serving Traffic</div>
  </div>
</body>
</html>
HTMLEOF
echo "User data script completed" >> /tmp/setup.log
'@

# Encode user data to base64
USER_DATA_B64=[Convert]::ToBase64String(
  [System.Text.Encoding]::UTF8.GetBytes($USER_DATA)
)

echo -e "\e[32m  User data prepared and base64 encoded.\e[0m"

# ── CREATE LAUNCH TEMPLATE ────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[3/3] Creating Launch Template...\e[0m"

LT_ID=$(aws ec2 create-launch-template \
  --launch-template-name web-server-lt \
  --version-description "v1 - Apache web server" \
  --launch-template-data "{)
      \"ImageId\":\"$AMI_ID\",
      \"InstanceType\":\"t2.micro\",
      \"KeyName\":\"aws-ec2-keypair\",
      \"SecurityGroupIds\":[\"$EC2_SG\"],
      \"UserData\":\"$USER_DATA_B64\",
      \"TagSpecifications\":[{
        \"ResourceType\":\"instance\",
        \"Tags\":[
          {\"Key\":\"Name\",\"Value\":\"asg-web-server\"},
          {\"Key\":\"Project\",\"Value\":\"project-10-asg-alb\"}
        ]
      }]
    }" \
  --query "LaunchTemplate.LaunchTemplateId" \
  --output text

echo -e "\e[32m  Launch Template ID: $LT_ID\e[0m"

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mVerifying launch template...\e[0m"
aws ec2 describe-launch-templates \
  --launch-template-ids $LT_ID \
  --query "LaunchTemplates[0].{ID:LaunchTemplateId,Name:LaunchTemplateName,Version:LatestVersionNumber}" \
  --output table

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== Launch Template Complete ===\e[0m"
echo "  Template ID:   $LT_ID"
echo "  Template Name: web-server-lt"
echo "  AMI:           $AMI_ID (Amazon Linux 2023)"
echo "  Instance Type: t2.micro"
echo "  Key Pair:      aws-ec2-keypair"
echo "  Security Group: $EC2_SG"
echo "  User Data:     Apache + stress tool + custom HTML"
echo ""
echo -e "\e[36mNext step: Run 05-create-target-group.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 10 — Script 04: Create Launch Template
# Defines EC2 blueprint with Apache, stress tool, and custom HTML page
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Create Launch Template ===" -ForegroundColor Cyan
Write-Host ""

# ── PRE-REQUISITES ────────────────────────────────────────────────────────────
$VPC_ID = aws ec2 describe-vpcs `
  --filters "Name=isDefault,Values=true" `
  --query "Vpcs[0].VpcId" --output text

$EC2_SG = aws ec2 describe-security-groups `
  --filters "Name=group-name,Values=asg-ec2-sg" `
  "Name=vpc-id,Values=$VPC_ID" `
  --query "SecurityGroups[0].GroupId" --output text

Write-Host "  EC2 SG: $EC2_SG" -ForegroundColor Green

# ── GET LATEST AMAZON LINUX 2023 AMI ──────────────────────────────────────────
Write-Host ""
Write-Host "[1/3] Finding latest Amazon Linux 2023 AMI..." -ForegroundColor Yellow

$AMI_ID = aws ec2 describe-images `
  --owners amazon `
  --filters "Name=name,Values=al2023-ami-*-x86_64" `
  "Name=state,Values=available" `
  --region ap-south-1 `
  --query "sort_by(Images,&CreationDate)[-1].ImageId" `
  --output text

Write-Host "  AMI: $AMI_ID" -ForegroundColor Green

# ── PREPARE USER DATA ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/3] Preparing user data script..." -ForegroundColor Yellow

$USER_DATA = @'
#!/bin/bash
yum update -y
yum install -y httpd stress
systemctl start httpd
systemctl enable httpd
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
cat > /var/www/html/index.html << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <title>ASG Demo</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:Arial,sans-serif;background:linear-gradient(135deg,#232f3e,#1a73e8);
    min-height:100vh;display:flex;align-items:center;justify-content:center}
    .card{background:white;border-radius:16px;padding:40px;max-width:500px;
    width:90%;text-align:center;box-shadow:0 20px 60px rgba(0,0,0,.3)}
    .badge{background:#ff9900;color:white;padding:6px 16px;border-radius:20px;
    font-size:13px;display:inline-block;margin-bottom:20px}
    h1{color:#232f3e;margin-bottom:20px;font-size:24px}
    .info{background:#f0f7ff;border-radius:8px;padding:16px;margin:10px 0;text-align:left}
    .label{font-size:12px;color:#888;text-transform:uppercase}
    .value{font-size:16px;font-weight:bold;color:#232f3e}
    .healthy{background:#d4edda;color:#155724;border-radius:8px;padding:10px;
    margin-top:16px;font-weight:bold}
  </style>
</head>
<body>
  <div class="card">
    <span class="badge">Auto Scaling Group - Project 10</span>
    <h1>Load Balanced Instance</h1>
    <div class="info"><div class="label">Instance ID</div><div class="value">$INSTANCE_ID</div></div>
    <div class="info"><div class="label">Availability Zone</div><div class="value">$AZ</div></div>
    <div class="info"><div class="label">Private IP</div><div class="value">$PRIVATE_IP</div></div>
    <div class="info"><div class="label">Region</div><div class="value">ap-south-1 (Mumbai)</div></div>
    <div class="healthy">Instance Healthy - Serving Traffic</div>
  </div>
</body>
</html>
HTMLEOF
echo "User data script completed" >> /tmp/setup.log
'@

# Encode user data to base64
$USER_DATA_B64 = [Convert]::ToBase64String(
  [System.Text.Encoding]::UTF8.GetBytes($USER_DATA)
)

Write-Host "  User data prepared and base64 encoded." -ForegroundColor Green

# ── CREATE LAUNCH TEMPLATE ────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Creating Launch Template..." -ForegroundColor Yellow

$LT_ID = aws ec2 create-launch-template `
  --launch-template-name web-server-lt `
  --version-description "v1 - Apache web server" `
  --launch-template-data "{
      `"ImageId`":`"$AMI_ID`",
      `"InstanceType`":`"t2.micro`",
      `"KeyName`":`"aws-ec2-keypair`",
      `"SecurityGroupIds`":[`"$EC2_SG`"],
      `"UserData`":`"$USER_DATA_B64`",
      `"TagSpecifications`":[{
        `"ResourceType`":`"instance`",
        `"Tags`":[
          {`"Key`":`"Name`",`"Value`":`"asg-web-server`"},
          {`"Key`":`"Project`",`"Value`":`"project-10-asg-alb`"}
        ]
      }]
    }" `
  --query "LaunchTemplate.LaunchTemplateId" `
  --output text

Write-Host "  Launch Template ID: $LT_ID" -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying launch template..." -ForegroundColor Yellow
aws ec2 describe-launch-templates `
  --launch-template-ids $LT_ID `
  --query "LaunchTemplates[0].{ID:LaunchTemplateId,Name:LaunchTemplateName,Version:LatestVersionNumber}" `
  --output table

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Launch Template Complete ===" -ForegroundColor Cyan
Write-Host "  Template ID:   $LT_ID"
Write-Host "  Template Name: web-server-lt"
Write-Host "  AMI:           $AMI_ID (Amazon Linux 2023)"
Write-Host "  Instance Type: t2.micro"
Write-Host "  Key Pair:      aws-ec2-keypair"
Write-Host "  Security Group: $EC2_SG"
Write-Host "  User Data:     Apache + stress tool + custom HTML"
Write-Host ""
Write-Host "Next step: Run 05-create-target-group.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 5 — CREATE TARGET GROUP FOR INSTANCES

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
# Project 10 — Script 05: Create Target Group
# Creates ALB target group with HTTP health checks on port 80
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 10 — Create Target Group ===\e[0m"
echo ""

# ── PRE-REQUISITES ────────────────────────────────────────────────────────────
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --query "Vpcs[0].VpcId" --output text)

echo -e "\e[32m  VPC: $VPC_ID\e[0m"
echo ""

# ── CREATE TARGET GROUP ───────────────────────────────────────────────────────
echo -e "\e[33m[1/1] Creating Target Group with health checks...\e[0m"

TG_ARN=$(aws elbv2 create-target-group \
    --name web-server-tg \
    --protocol HTTP \
    --port 80 \
    --vpc-id $VPC_ID \
    --health-check-protocol HTTP \
    --health-check-path "/" \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 2 \
    --matcher HttpCode=200 \
    --target-type instance \
    --query "TargetGroups[0].TargetGroupArn" \
    --output text)

echo -e "\e[32m  Target Group ARN: $TG_ARN\e[0m"

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mVerifying target group...\e[0m"
aws elbv2 describe-target-groups \
    --target-group-arns $TG_ARN \
    --query "TargetGroups[0].{Name:TargetGroupName,Protocol:Protocol,Port:Port,HealthPath:HealthCheckPath,HealthInterval:HealthCheckIntervalSeconds}" \
    --output table

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== Target Group Complete ===\e[0m"
echo "  Name:           web-server-tg"
echo "  Protocol:       HTTP"
echo "  Port:           80"
echo "  Health Check:   HTTP GET / (every 30s, timeout 5s)"
echo "  Healthy After:  2 consecutive checks"
echo "  Unhealthy After: 2 consecutive failures"
echo "  Success Code:   200"
echo ""
echo -e "\e[33m  No targets registered yet — ASG will add instances automatically.\e[0m"
echo ""
echo -e "\e[36mNext step: Run 06-create-alb.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 10 — Script 05: Create Target Group
# Creates ALB target group with HTTP health checks on port 80
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Create Target Group ===" -ForegroundColor Cyan
Write-Host ""

# ── PRE-REQUISITES ────────────────────────────────────────────────────────────
$VPC_ID = aws ec2 describe-vpcs `
    --filters "Name=isDefault,Values=true" `
    --query "Vpcs[0].VpcId" --output text

Write-Host "  VPC: $VPC_ID" -ForegroundColor Green
Write-Host ""

# ── CREATE TARGET GROUP ───────────────────────────────────────────────────────
Write-Host "[1/1] Creating Target Group with health checks..." -ForegroundColor Yellow

$TG_ARN = aws elbv2 create-target-group `
    --name web-server-tg `
    --protocol HTTP `
    --port 80 `
    --vpc-id $VPC_ID `
    --health-check-protocol HTTP `
    --health-check-path "/" `
    --health-check-interval-seconds 30 `
    --health-check-timeout-seconds 5 `
    --healthy-threshold-count 2 `
    --unhealthy-threshold-count 2 `
    --matcher HttpCode=200 `
    --target-type instance `
    --query "TargetGroups[0].TargetGroupArn" `
    --output text

Write-Host "  Target Group ARN: $TG_ARN" -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying target group..." -ForegroundColor Yellow
aws elbv2 describe-target-groups `
    --target-group-arns $TG_ARN `
    --query "TargetGroups[0].{Name:TargetGroupName,Protocol:Protocol,Port:Port,HealthPath:HealthCheckPath,HealthInterval:HealthCheckIntervalSeconds}" `
    --output table

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Target Group Complete ===" -ForegroundColor Cyan
Write-Host "  Name:           web-server-tg"
Write-Host "  Protocol:       HTTP"
Write-Host "  Port:           80"
Write-Host "  Health Check:   HTTP GET / (every 30s, timeout 5s)"
Write-Host "  Healthy After:  2 consecutive checks"
Write-Host "  Unhealthy After: 2 consecutive failures"
Write-Host "  Success Code:   200"
Write-Host ""
Write-Host "  No targets registered yet — ASG will add instances automatically." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run 06-create-alb.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 6 — CREATE APPLICATION LOAD BALANCER AND LISTENER

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **EC2 > Load Balancing** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 10 — Script 06: Create Application Load Balancer
# Creates internet-facing ALB with HTTP listener forwarding to target group
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 10 — Create Application Load Balancer ===\e[0m"
echo ""

# ── PRE-REQUISITES ────────────────────────────────────────────────────────────
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --query "Vpcs[0].VpcId" --output text)

SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    "Name=defaultForAz,Values=true" \
    --query "Subnets[*].SubnetId" \
    --output text)

SUBNET_LIST=($SUBNETS)
SUBNET_A=${SUBNET_LIST[0]}
SUBNET_B=${SUBNET_LIST[1]}

ALB_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=alb-sg" \
    "Name=vpc-id,Values=$VPC_ID" \
    --query "SecurityGroups[0].GroupId" --output text)

TG_ARN=$(aws elbv2 describe-target-groups \
    --names web-server-tg \
    --query "TargetGroups[0].TargetGroupArn" --output text)

echo -e "\e[32m  VPC:      $VPC_ID\e[0m"
echo -e "\e[32m  Subnet A: $SUBNET_A\e[0m"
echo -e "\e[32m  Subnet B: $SUBNET_B\e[0m"
echo -e "\e[32m  ALB SG:   $ALB_SG\e[0m"
echo -e "\e[32m  TG ARN:   $TG_ARN\e[0m"
echo ""

# ── CREATE ALB ────────────────────────────────────────────────────────────────
echo -e "\e[33m[1/3] Creating Application Load Balancer...\e[0m"

ALB_ARN=$(aws elbv2 create-load-balancer \
    --name my-alb \
    --subnets $SUBNET_A $SUBNET_B \
    --security-groups $ALB_SG \
    --scheme internet-facing \
    --type application \
    --ip-address-type ipv4 \
    --query "LoadBalancers[0].LoadBalancerArn" \
    --output text)

echo -e "\e[32m  ALB ARN: $ALB_ARN\e[0m"

# ── GET DNS NAME ──────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[2/3] Getting ALB DNS name...\e[0m"

ALB_DNS=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns $ALB_ARN \
    --query "LoadBalancers[0].DNSName" \
    --output text)

echo -e "\e[32m  ALB DNS: $ALB_DNS\e[0m"

# ── CREATE HTTP LISTENER ──────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[3/3] Creating HTTP listener (port 80 → target group)...\e[0m"

LISTENER_ARN=$(aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions "Type=forward,TargetGroupArn=$TG_ARN" \
    --query "Listeners[0].ListenerArn" \
    --output text)

echo -e "\e[32m  Listener ARN: $LISTENER_ARN\e[0m"

# ── WAIT FOR ALB TO BE ACTIVE ─────────────────────────────────────────────────
echo ""
echo -e "\e[33mWaiting for ALB to become active (2-3 minutes)...\e[0m"
aws elbv2 wait load-balancer-available --load-balancer-arns $ALB_ARN
echo -e "\e[32m  ALB is active!\e[0m"

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== ALB Complete ===\e[0m"
echo "  Name:      my-alb"
echo "  Scheme:    internet-facing"
echo "  Type:      application"
echo "  Listener:  HTTP:80 → web-server-tg"
echo ""
echo -e "\e[32m  URL: http://$ALB_DNS\e[0m"
echo ""
echo -e "\e[33m  The ALB is active but has no targets yet.\e[0m"
echo -e "\e[33m  ASG will register instances in the next step.\e[0m"
echo ""
echo -e "\e[36mNext step: Run 07-create-auto-scaling-group.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 10 — Script 06: Create Application Load Balancer
# Creates internet-facing ALB with HTTP listener forwarding to target group
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Create Application Load Balancer ===" -ForegroundColor Cyan
Write-Host ""

# ── PRE-REQUISITES ────────────────────────────────────────────────────────────
$VPC_ID = aws ec2 describe-vpcs `
    --filters "Name=isDefault,Values=true" `
    --query "Vpcs[0].VpcId" --output text

$SUBNETS = aws ec2 describe-subnets `
    --filters "Name=vpc-id,Values=$VPC_ID" `
    "Name=defaultForAz,Values=true" `
    --query "Subnets[*].SubnetId" `
    --output text

$SUBNET_LIST = $SUBNETS -split '\s+'
$SUBNET_A = $SUBNET_LIST[0]
$SUBNET_B = $SUBNET_LIST[1]

$ALB_SG = aws ec2 describe-security-groups `
    --filters "Name=group-name,Values=alb-sg" `
    "Name=vpc-id,Values=$VPC_ID" `
    --query "SecurityGroups[0].GroupId" --output text

$TG_ARN = aws elbv2 describe-target-groups `
    --names web-server-tg `
    --query "TargetGroups[0].TargetGroupArn" --output text

Write-Host "  VPC:      $VPC_ID" -ForegroundColor Green
Write-Host "  Subnet A: $SUBNET_A" -ForegroundColor Green
Write-Host "  Subnet B: $SUBNET_B" -ForegroundColor Green
Write-Host "  ALB SG:   $ALB_SG" -ForegroundColor Green
Write-Host "  TG ARN:   $TG_ARN" -ForegroundColor Green
Write-Host ""

# ── CREATE ALB ────────────────────────────────────────────────────────────────
Write-Host "[1/3] Creating Application Load Balancer..." -ForegroundColor Yellow

$ALB_ARN = aws elbv2 create-load-balancer `
    --name my-alb `
    --subnets $SUBNET_A $SUBNET_B `
    --security-groups $ALB_SG `
    --scheme internet-facing `
    --type application `
    --ip-address-type ipv4 `
    --query "LoadBalancers[0].LoadBalancerArn" `
    --output text

Write-Host "  ALB ARN: $ALB_ARN" -ForegroundColor Green

# ── GET DNS NAME ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/3] Getting ALB DNS name..." -ForegroundColor Yellow

$ALB_DNS = aws elbv2 describe-load-balancers `
    --load-balancer-arns $ALB_ARN `
    --query "LoadBalancers[0].DNSName" `
    --output text

Write-Host "  ALB DNS: $ALB_DNS" -ForegroundColor Green

# ── CREATE HTTP LISTENER ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Creating HTTP listener (port 80 → target group)..." -ForegroundColor Yellow

$LISTENER_ARN = aws elbv2 create-listener `
    --load-balancer-arn $ALB_ARN `
    --protocol HTTP `
    --port 80 `
    --default-actions "Type=forward,TargetGroupArn=$TG_ARN" `
    --query "Listeners[0].ListenerArn" `
    --output text

Write-Host "  Listener ARN: $LISTENER_ARN" -ForegroundColor Green

# ── WAIT FOR ALB TO BE ACTIVE ─────────────────────────────────────────────────
Write-Host ""
Write-Host "Waiting for ALB to become active (2-3 minutes)..." -ForegroundColor Yellow
aws elbv2 wait load-balancer-available --load-balancer-arns $ALB_ARN
Write-Host "  ALB is active!" -ForegroundColor Green

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== ALB Complete ===" -ForegroundColor Cyan
Write-Host "  Name:      my-alb"
Write-Host "  Scheme:    internet-facing"
Write-Host "  Type:      application"
Write-Host "  Listener:  HTTP:80 → web-server-tg"
Write-Host ""
Write-Host "  URL: http://$ALB_DNS" -ForegroundColor Green
Write-Host ""
Write-Host "  The ALB is active but has no targets yet." -ForegroundColor Yellow
Write-Host "  ASG will register instances in the next step." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run 07-create-auto-scaling-group.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 7 — CREATE ASG WITH TARGET TRACKING SCALING

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
# Project 10 — Script 07: Create Auto Scaling Group
# Creates ASG with min:2, max:4, desired:2, ELB health checks, CPU scaling
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 10 — Create Auto Scaling Group ===\e[0m"
echo ""

# ── PRE-REQUISITES ────────────────────────────────────────────────────────────
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" --output text)

SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  "Name=defaultForAz,Values=true" \
  --query "Subnets[*].SubnetId" \
  --output text)

SUBNET_LIST=($SUBNETS)
SUBNET_A=${SUBNET_LIST[0]}
SUBNET_B=${SUBNET_LIST[1]}

LT_ID=$(aws ec2 describe-launch-templates \
  --launch-template-names web-server-lt \
  --query "LaunchTemplates[0].LaunchTemplateId" --output text)

TG_ARN=$(aws elbv2 describe-target-groups \
  --names web-server-tg \
  --query "TargetGroups[0].TargetGroupArn" --output text)

echo -e "\e[32m  VPC:              $VPC_ID\e[0m"
echo -e "\e[32m  Subnets:          $SUBNET_A, $SUBNET_B\e[0m"
echo -e "\e[32m  Launch Template:  $LT_ID\e[0m"
echo -e "\e[32m  Target Group:     $TG_ARN\e[0m"
echo ""

# ── CREATE AUTO SCALING GROUP ─────────────────────────────────────────────────
echo -e "\e[33m[1/2] Creating Auto Scaling Group...\e[0m"

aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name web-server-asg \
  --launch-template "LaunchTemplateId=$LT_ID,Version=\$Latest" \
  --min-size 2 \
  --max-size 4 \
  --desired-capacity 2 \
  --vpc-zone-identifier "$SUBNET_A,$SUBNET_B" \
  --target-group-arns $TG_ARN \
  --health-check-type ELB \
  --health-check-grace-period 120 \
  --tags "Key=Name,Value=asg-web-server,PropagateAtLaunch=true" \
  "Key=Project,Value=project-10-asg-alb,PropagateAtLaunch=true"

echo -e "\e[32m  ASG created: web-server-asg\e[0m"
echo -e "\e[32m  Min: 2 | Desired: 2 | Max: 4\e[0m"
echo -e "\e[32m  Health Check: ELB (ALB), Grace Period: 120s\e[0m"

# ── ADD TARGET TRACKING SCALING POLICY ────────────────────────────────────────
echo ""
echo -e "\e[33m[2/2] Adding CPU target tracking scaling policy...\e[0m"

aws autoscaling put-scaling-policy \
  --auto-scaling-group-name web-server-asg \
  --policy-name cpu-target-tracking \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration "{
      \"PredefinedMetricSpecification\":{
        \"PredefinedMetricType\":\"ASGAverageCPUUtilization\"
      },
      \"TargetValue\":50.0,
      \"EstimatedInstanceWarmup\":120
    }" | Out-Null

echo -e "\e[32m  Scaling policy: cpu-target-tracking\e[0m"
echo -e "\e[32m  Target: 50% average CPU utilization\e[0m"
echo -e "\e[32m  Warmup: 120 seconds\e[0m"

# ── WAIT FOR INSTANCES ────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mWaiting for instances to launch (60 seconds)...\e[0m"
sleep 60

# ── CHECK STATUS ──────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mChecking ASG status...\e[0m"
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names web-server-asg \
  --query "AutoScalingGroups[0].{
      Name:AutoScalingGroupName,
      Min:MinSize,
      Max:MaxSize,
      Desired:DesiredCapacity,
      Instances:Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus,AZ:AvailabilityZone}
    }" \
  --output json

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== Auto Scaling Group Complete ===\e[0m"
echo "  ASG Name:        web-server-asg"
echo "  Min/Desired/Max: 2 / 2 / 4"
echo "  Scaling Policy:  CPU target tracking at 50%"
echo "  Health Check:    ELB (ALB checks via Target Group)"
echo "  Subnets:         2 AZs for high availability"
echo ""
echo -e "\e[33m  Instances are launching — it takes 2-3 minutes to pass health checks.\e[0m"
echo ""
echo -e "\e[36mNext step: Run 08-verify-and-test.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 10 — Script 07: Create Auto Scaling Group
# Creates ASG with min:2, max:4, desired:2, ELB health checks, CPU scaling
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Create Auto Scaling Group ===" -ForegroundColor Cyan
Write-Host ""

# ── PRE-REQUISITES ────────────────────────────────────────────────────────────
$VPC_ID = aws ec2 describe-vpcs `
  --filters "Name=isDefault,Values=true" `
  --query "Vpcs[0].VpcId" --output text

$SUBNETS = aws ec2 describe-subnets `
  --filters "Name=vpc-id,Values=$VPC_ID" `
  "Name=defaultForAz,Values=true" `
  --query "Subnets[*].SubnetId" `
  --output text

$SUBNET_LIST = $SUBNETS -split '\s+'
$SUBNET_A = $SUBNET_LIST[0]
$SUBNET_B = $SUBNET_LIST[1]

$LT_ID = aws ec2 describe-launch-templates `
  --launch-template-names web-server-lt `
  --query "LaunchTemplates[0].LaunchTemplateId" --output text

$TG_ARN = aws elbv2 describe-target-groups `
  --names web-server-tg `
  --query "TargetGroups[0].TargetGroupArn" --output text

Write-Host "  VPC:              $VPC_ID" -ForegroundColor Green
Write-Host "  Subnets:          $SUBNET_A, $SUBNET_B" -ForegroundColor Green
Write-Host "  Launch Template:  $LT_ID" -ForegroundColor Green
Write-Host "  Target Group:     $TG_ARN" -ForegroundColor Green
Write-Host ""

# ── CREATE AUTO SCALING GROUP ─────────────────────────────────────────────────
Write-Host "[1/2] Creating Auto Scaling Group..." -ForegroundColor Yellow

aws autoscaling create-auto-scaling-group `
  --auto-scaling-group-name web-server-asg `
  --launch-template "LaunchTemplateId=$LT_ID,Version=`$Latest" `
  --min-size 2 `
  --max-size 4 `
  --desired-capacity 2 `
  --vpc-zone-identifier "$SUBNET_A,$SUBNET_B" `
  --target-group-arns $TG_ARN `
  --health-check-type ELB `
  --health-check-grace-period 120 `
  --tags "Key=Name,Value=asg-web-server,PropagateAtLaunch=true" `
  "Key=Project,Value=project-10-asg-alb,PropagateAtLaunch=true"

Write-Host "  ASG created: web-server-asg" -ForegroundColor Green
Write-Host "  Min: 2 | Desired: 2 | Max: 4" -ForegroundColor Green
Write-Host "  Health Check: ELB (ALB), Grace Period: 120s" -ForegroundColor Green

# ── ADD TARGET TRACKING SCALING POLICY ────────────────────────────────────────
Write-Host ""
Write-Host "[2/2] Adding CPU target tracking scaling policy..." -ForegroundColor Yellow

aws autoscaling put-scaling-policy `
  --auto-scaling-group-name web-server-asg `
  --policy-name cpu-target-tracking `
  --policy-type TargetTrackingScaling `
  --target-tracking-configuration "{
      `"PredefinedMetricSpecification`":{
        `"PredefinedMetricType`":`"ASGAverageCPUUtilization`"
      },
      `"TargetValue`":50.0,
      `"EstimatedInstanceWarmup`":120
    }" | Out-Null

Write-Host "  Scaling policy: cpu-target-tracking" -ForegroundColor Green
Write-Host "  Target: 50% average CPU utilization" -ForegroundColor Green
Write-Host "  Warmup: 120 seconds" -ForegroundColor Green

# ── WAIT FOR INSTANCES ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Waiting for instances to launch (60 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# ── CHECK STATUS ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Checking ASG status..." -ForegroundColor Yellow
aws autoscaling describe-auto-scaling-groups `
  --auto-scaling-group-names web-server-asg `
  --query "AutoScalingGroups[0].{
      Name:AutoScalingGroupName,
      Min:MinSize,
      Max:MaxSize,
      Desired:DesiredCapacity,
      Instances:Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus,AZ:AvailabilityZone}
    }" `
  --output json

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Auto Scaling Group Complete ===" -ForegroundColor Cyan
Write-Host "  ASG Name:        web-server-asg"
Write-Host "  Min/Desired/Max: 2 / 2 / 4"
Write-Host "  Scaling Policy:  CPU target tracking at 50%"
Write-Host "  Health Check:    ELB (ALB checks via Target Group)"
Write-Host "  Subnets:         2 AZs for high availability"
Write-Host ""
Write-Host "  Instances are launching — it takes 2-3 minutes to pass health checks." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run 08-verify-and-test.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 8 — VERIFY LOAD BALANCING ACROSS INSTANCES

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
# Project 10 — Script 08: Verify and Test
# Checks target health, tests load balancing, opens browser
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 10 — Verify and Test ===\e[0m"
echo ""

# ── PRE-REQUISITES ────────────────────────────────────────────────────────────
TG_ARN=$(aws elbv2 describe-target-groups \
    --names web-server-tg \
    --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null)

ALB_DNS=$(aws elbv2 describe-load-balancers \
    --names my-alb \
    --query "LoadBalancers[0].DNSName" --output text 2>/dev/null)

echo -e "\e[32m  Target Group: $TG_ARN\e[0m"
echo -e "\e[32m  ALB DNS:      $ALB_DNS\e[0m"
echo ""

# ── CHECK TARGET HEALTH ──────────────────────────────────────────────────────
echo -e "\e[33m[1/4] Checking target group health...\e[0m"
echo -e "\e[33m  Waiting for targets to become healthy (polling every 15s)...\e[0m"

maxAttempts=20
attempt=0
allHealthy="false"

while [ "$allHealthy" == "false" ] && [ $attempt -lt $maxAttempts ]; do
    attempt=$((attempt+1))
    
    healthData=$(aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --output json 2>/dev/null)
    
    # Parse json to get counts
    healthyCount=$(echo "$healthData" | jq -r '[.TargetHealthDescriptions[] | select(.TargetHealth.State == "healthy")] | length' 2>/dev/null)
    totalCount=$(echo "$healthData" | jq -r '.TargetHealthDescriptions | length' 2>/dev/null)
    
    # Handle jq failures if no targets are registered yet
    if [ -z "$healthyCount" ]; then healthyCount=0; fi
    if [ -z "$totalCount" ]; then totalCount=0; fi

    echo "  Attempt $attempt: $healthyCount/$totalCount healthy"

    if [ "$healthyCount" -eq "$totalCount" ] && [ "$totalCount" -gt 0 ]; then
        allHealthy="true"
    else
        sleep 15
    fi
done

if [ "$allHealthy" == "true" ]; then
    echo -e "\e[32m  All targets healthy!\e[0m"
else
    echo -e "\e[31m  Timeout — some targets may still be initializing.\e[0m"
fi

# ── DISPLAY TARGET HEALTH TABLE ───────────────────────────────────────────────
echo ""
echo -e "\e[33m[2/4] Target health status:\e[0m"
aws elbv2 describe-target-health \
    --target-group-arn "$TG_ARN" \
    --query "TargetHealthDescriptions[*].{Instance:Target.Id,Port:Target.Port,State:TargetHealth.State}" \
    --output table

# ── CHECK ASG INSTANCES ──────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[3/4] ASG instance status:\e[0m"
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names web-server-asg \
    --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,AZ:AvailabilityZone,State:LifecycleState,Health:HealthStatus}" \
    --output table

# ── TEST LOAD BALANCING ──────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[4/4] Testing load balancing (5 requests)...\e[0m"
echo -e "\e[32m  URL: http://$ALB_DNS\e[0m"
echo ""

for i in {1..5}; do
    response=$(curl -s "http://$ALB_DNS" --max-time 10 || echo "FAILED")
    if [ "$response" == "FAILED" ]; then
        echo -e "\e[31m  Request $i: FAILED\e[0m"
    else
        instanceId=$(echo "$response" | grep -o 'i-[0-9a-f]\{8,17\}' | head -n 1)
        echo -e "\e[32m  Request $i: OK | Instance: $instanceId\e[0m"
    fi
    sleep 0.5
done

# ── OPEN BROWSER ──────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mOpening ALB in browser...\e[0m"
# Not opening browser in bash script automatically to avoid WSL issues
echo -e "Please open \e[36mhttp://$ALB_DNS\e[0m in your browser"

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== Verification Complete ===\e[0m"
echo "  ALB URL: http://$ALB_DNS"
echo ""
echo -e "\e[33m  Refresh the browser multiple times — you should see different\e[0m"
echo -e "\e[33m  Instance IDs and Availability Zones on each refresh.\e[0m"
echo -e "\e[33m  This proves the ALB is distributing traffic across instances.\e[0m"
echo ""
echo -e "\e[36mNext step: Run 09-test-auto-scaling.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 10 — Script 08: Verify and Test
# Checks target health, tests load balancing, opens browser
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Verify and Test ===" -ForegroundColor Cyan
Write-Host ""

# ── PRE-REQUISITES ────────────────────────────────────────────────────────────
$TG_ARN = aws elbv2 describe-target-groups `
    --names web-server-tg `
    --query "TargetGroups[0].TargetGroupArn" --output text

$ALB_DNS = aws elbv2 describe-load-balancers `
    --names my-alb `
    --query "LoadBalancers[0].DNSName" --output text

Write-Host "  Target Group: $TG_ARN" -ForegroundColor Green
Write-Host "  ALB DNS:      $ALB_DNS" -ForegroundColor Green
Write-Host ""

# ── CHECK TARGET HEALTH ──────────────────────────────────────────────────────
Write-Host "[1/4] Checking target group health..." -ForegroundColor Yellow
Write-Host "  Waiting for targets to become healthy (polling every 15s)..." -ForegroundColor Yellow

$maxAttempts = 20
$attempt = 0
$allHealthy = $false

while (-not $allHealthy -and $attempt -lt $maxAttempts) {
    $attempt++
    $healthData = aws elbv2 describe-target-health `
        --target-group-arn $TG_ARN `
        --query "TargetHealthDescriptions[*].{Instance:Target.Id,State:TargetHealth.State}" `
        --output json | ConvertFrom-Json

    $healthyCount = ($healthData | Where-Object { $_.State -eq "healthy" }).Count
    $totalCount = $healthData.Count

    Write-Host "  Attempt $attempt`: $healthyCount/$totalCount healthy" -ForegroundColor $(if ($healthyCount -eq $totalCount -and $totalCount -gt 0) { "Green" } else { "Yellow" })

    if ($healthyCount -eq $totalCount -and $totalCount -gt 0) {
        $allHealthy = $true
    }
    else {
        Start-Sleep -Seconds 15
    }
}

if ($allHealthy) {
    Write-Host "  All targets healthy!" -ForegroundColor Green
}
else {
    Write-Host "  Timeout — some targets may still be initializing." -ForegroundColor Red
}

# ── DISPLAY TARGET HEALTH TABLE ───────────────────────────────────────────────
Write-Host ""
Write-Host "[2/4] Target health status:" -ForegroundColor Yellow
aws elbv2 describe-target-health `
    --target-group-arn $TG_ARN `
    --query "TargetHealthDescriptions[*].{Instance:Target.Id,Port:Target.Port,State:TargetHealth.State}" `
    --output table

# ── CHECK ASG INSTANCES ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/4] ASG instance status:" -ForegroundColor Yellow
aws autoscaling describe-auto-scaling-groups `
    --auto-scaling-group-names web-server-asg `
    --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,AZ:AvailabilityZone,State:LifecycleState,Health:HealthStatus}" `
    --output table

# ── TEST LOAD BALANCING ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "[4/4] Testing load balancing (5 requests)..." -ForegroundColor Yellow
Write-Host "  URL: http://$ALB_DNS" -ForegroundColor Green
Write-Host ""

1..5 | ForEach-Object {
    try {
        $response = Invoke-WebRequest -Uri "http://$ALB_DNS" -UseBasicParsing -TimeoutSec 10
        $instanceId = [regex]::Match($response.Content, 'i-[0-9a-f]{8,17}').Value
        $statusCode = $response.StatusCode
        Write-Host "  Request $_`: Status $statusCode | Instance: $instanceId" -ForegroundColor Green
    }
    catch {
        Write-Host "  Request $_`: FAILED — $($_.Exception.Message)" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 500
}

# ── OPEN BROWSER ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Opening ALB in browser..." -ForegroundColor Yellow
Start-Process "http://$ALB_DNS"

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Verification Complete ===" -ForegroundColor Cyan
Write-Host "  ALB URL: http://$ALB_DNS"
Write-Host ""
Write-Host "  Refresh the browser multiple times — you should see different" -ForegroundColor Yellow
Write-Host "  Instance IDs and Availability Zones on each refresh." -ForegroundColor Yellow
Write-Host "  This proves the ALB is distributing traffic across instances." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run 09-test-auto-scaling.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 9 — SSH AND RUN STRESS TOOL TO SPIKE CPU

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
# Project 10 — Script 09: Test Auto Scaling
# Generates CPU load to trigger scale-out, monitors instance count
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 10 — Test Auto Scaling ===\e[0m"
echo ""

# ── GET INSTANCE IDs ──────────────────────────────────────────────────────────
INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names web-server-asg \
    --query "AutoScalingGroups[0].Instances[*].InstanceId" \
    --output text 2>/dev/null)

INSTANCE1=$(echo "$INSTANCE_IDS" | awk '{print $1}')
echo -e "\e[32m  Target instance for stress test: $INSTANCE1\e[0m"
echo ""

# ── OPTION 1: SSH + STRESS ────────────────────────────────────────────────────
echo -e "\e[33m=== Option 1: SSH Stress Test ===\e[0m"
echo -e "\e[33m  Connect via SSM Session Manager:\e[0m"
echo -e "\e[97m    aws ssm start-session --target $INSTANCE1\e[0m"
echo ""
echo -e "\e[33m  Then run inside the session:\e[0m"
echo -e "\e[97m    sudo stress --cpu 1 --timeout 600 &\e[0m"
echo -e "\e[97m    top  (to verify stress is running)\e[0m"
echo ""

# ── OPTION 2: MANUAL SCALE ───────────────────────────────────────────────────
echo -e "\e[33m=== Option 2: Manual Scale Test ===\e[0m"
echo -e "\e[33m  Scale up to 3 instances:\e[0m"
echo -e "\e[97m    aws autoscaling set-desired-capacity --auto-scaling-group-name web-server-asg --desired-capacity 3\e[0m"
echo ""
echo -e "\e[33m  Scale back down:\e[0m"
echo -e "\e[97m    aws autoscaling set-desired-capacity --auto-scaling-group-name web-server-asg --desired-capacity 2\e[0m"
echo ""

# ── MONITOR ASG ───────────────────────────────────────────────────────────────
echo -e "\e[33m=== Monitoring ASG (Ctrl+C to stop) ===\e[0m"
echo ""

iterations=0
maxIterations=40  # Monitor for ~20 minutes

while [ $iterations -lt $maxIterations ]; do
    iterations=$((iterations+1))

    asg_json=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names web-server-asg \
        --query "AutoScalingGroups[0].{Desired:DesiredCapacity,Instances:Instances[*].{ID:InstanceId,State:LifecycleState}}" \
        --output json 2>/dev/null)

    timestamp=$(date +"%T")
    
    if [ -n "$asg_json" ] && [ "$asg_json" != "null" ]; then
        instanceCount=$(echo "$asg_json" | jq '.Instances | length' 2>/dev/null)
        desired=$(echo "$asg_json" | jq -r '.Desired' 2>/dev/null)
        
        # Determine color
        if [ "$instanceCount" -gt 2 ]; then
            color="\e[32m" # Green
        else
            color="\e[0m"  # Default
        fi

        echo -e "${color}$timestamp — Instances: $instanceCount (Desired: $desired)\e[0m"
        
        # Loop over instances in json
        echo "$asg_json" | jq -c '.Instances[]' 2>/dev/null | while read -r inst; do
            id=$(echo "$inst" | jq -r '.ID')
            state=$(echo "$inst" | jq -r '.State')
            
            if [ "$state" == "InService" ]; then
                stateColor="\e[32m" # Green
            elif [ "$state" == "Pending" ]; then
                stateColor="\e[33m" # Yellow
            else
                stateColor="\e[31m" # Red
            fi
            echo -e "  ${id}: ${stateColor}${state}\e[0m"
        done
    else
        echo -e "$timestamp — Could not fetch ASG status"
    fi

    echo ""
    sleep 30
done

echo ""
echo -e "\e[36m=== Monitoring Complete ===\e[0m"
echo ""
echo -e "\e[33m  Check scaling history:\e[0m"
echo -e "\e[97m    aws autoscaling describe-scaling-activities --auto-scaling-group-name web-server-asg --query \"Activities[*].{Status:StatusCode,Desc:Description}\" --output table\e[0m"
echo ""
echo -e "\e[36mNext step: Run 10-simulate-failure.sh OR 11-cleanup.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 10 — Script 09: Test Auto Scaling
# Generates CPU load to trigger scale-out, monitors instance count
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Test Auto Scaling ===" -ForegroundColor Cyan
Write-Host ""

# ── GET INSTANCE IDs ──────────────────────────────────────────────────────────
$INSTANCE_IDS = aws autoscaling describe-auto-scaling-groups `
    --auto-scaling-group-names web-server-asg `
    --query "AutoScalingGroups[0].Instances[*].InstanceId" `
    --output text

$INSTANCE1 = ($INSTANCE_IDS -split '\s+')[0]
Write-Host "  Target instance for stress test: $INSTANCE1" -ForegroundColor Green
Write-Host ""

# ── OPTION 1: SSH + STRESS ────────────────────────────────────────────────────
Write-Host "=== Option 1: SSH Stress Test ===" -ForegroundColor Yellow
Write-Host "  Connect via SSM Session Manager:" -ForegroundColor Yellow
Write-Host "    aws ssm start-session --target $INSTANCE1" -ForegroundColor White
Write-Host ""
Write-Host "  Then run inside the session:" -ForegroundColor Yellow
Write-Host "    sudo stress --cpu 1 --timeout 600 &" -ForegroundColor White
Write-Host "    top  (to verify stress is running)" -ForegroundColor White
Write-Host ""

# ── OPTION 2: MANUAL SCALE ───────────────────────────────────────────────────
Write-Host "=== Option 2: Manual Scale Test ===" -ForegroundColor Yellow
Write-Host "  Scale up to 3 instances:" -ForegroundColor Yellow
Write-Host "    aws autoscaling set-desired-capacity --auto-scaling-group-name web-server-asg --desired-capacity 3" -ForegroundColor White
Write-Host ""
Write-Host "  Scale back down:" -ForegroundColor Yellow
Write-Host "    aws autoscaling set-desired-capacity --auto-scaling-group-name web-server-asg --desired-capacity 2" -ForegroundColor White
Write-Host ""

# ── MONITOR ASG ───────────────────────────────────────────────────────────────
Write-Host "=== Monitoring ASG (Ctrl+C to stop) ===" -ForegroundColor Yellow
Write-Host ""

$iterations = 0
$maxIterations = 40  # Monitor for ~20 minutes

while ($iterations -lt $maxIterations) {
    $iterations++

    $asg = aws autoscaling describe-auto-scaling-groups `
        --auto-scaling-group-names web-server-asg `
        --query "AutoScalingGroups[0].{
          Desired:DesiredCapacity,
          Instances:Instances[*].{ID:InstanceId,State:LifecycleState}}" `
        --output json | ConvertFrom-Json

    $timestamp = Get-Date -Format 'HH:mm:ss'
    $instanceCount = $asg.Instances.Count
    $desired = $asg.Desired

    # Color based on change
    $color = if ($instanceCount -gt 2) { "Green" } else { "White" }

    Write-Host "$timestamp — Instances: $instanceCount (Desired: $desired)" -ForegroundColor $color
    $asg.Instances | ForEach-Object {
        $stateColor = switch ($_.State) {
            "InService" { "Green" }
            "Pending" { "Yellow" }
            default { "Red" }
        }
        Write-Host "  $($_.ID): $($_.State)" -ForegroundColor $stateColor
    }
    Write-Host ""

    Start-Sleep -Seconds 30
}

Write-Host ""
Write-Host "=== Monitoring Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Check scaling history:" -ForegroundColor Yellow
Write-Host "    aws autoscaling describe-scaling-activities --auto-scaling-group-name web-server-asg --query ""Activities[0:5].[StartTime,Cause,StatusCode]"" --output table" -ForegroundColor White
Write-Host ""
Write-Host "Next step: Run 10-simulate-failure.ps1 OR 11-cleanup.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 10 — TERMINATE AN INSTANCE TO VERIFY SELF-HEALING

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
# Project 10 — Script 10: Simulate Instance Failure
# Terminates an instance to demonstrate ASG self-healing
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 10 — Simulate Instance Failure ===\e[0m"
echo ""

# ── GET CURRENT INSTANCES ─────────────────────────────────────────────────────
echo -e "\e[33m[1/3] Getting current ASG instances...\e[0m"

INSTANCES=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names web-server-asg \
    --query "AutoScalingGroups[0].Instances[*].InstanceId" \
    --output text 2>/dev/null)

if [ -z "$INSTANCES" ] || [ "$INSTANCES" == "None" ]; then
    echo -e "\e[31m  No instances found in ASG!\e[0m"
    exit 1
fi

echo -e "\e[32m  Current instances: ${INSTANCES//$'\t'/, }\e[0m"

FAILED_INSTANCE=$(echo "$INSTANCES" | awk '{print $1}')
echo -e "\e[31m  Instance to terminate (simulate failure): $FAILED_INSTANCE\e[0m"
echo ""

# ── SHOW BEFORE STATE ─────────────────────────────────────────────────────────
echo -e "\e[33m[2/3] Before failure — current state:\e[0m"
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names web-server-asg \
    --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus,AZ:AvailabilityZone}" \
    --output table

# ── TERMINATE INSTANCE ────────────────────────────────────────────────────────
echo ""
echo -e "\e[31m[3/3] Terminating instance: $FAILED_INSTANCE\e[0m"
echo -e "\e[33m  ASG will detect the failure and launch a replacement...\e[0m"

aws ec2 terminate-instances --instance-ids "$FAILED_INSTANCE" >/dev/null 2>&1

echo -e "\e[31m  Termination initiated!\e[0m"
echo ""

# ── MONITOR SELF-HEALING ──────────────────────────────────────────────────────
echo -e "\e[33m=== Monitoring Self-Healing (Ctrl+C to stop) ===\e[0m"
echo -e "\e[33m  Expected: ASG detects failure → launches new instance → registers in ALB\e[0m"
echo ""

iterations=0
maxIterations=20  # Monitor for ~10 minutes

while [ $iterations -lt $maxIterations ]; do
    iterations=$((iterations+1))
    timestamp=$(date +"%T")

    asg_json=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names web-server-asg \
        --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus}" \
        --output json 2>/dev/null)

    if [ -n "$asg_json" ] && [ "$asg_json" != "null" ]; then
        instanceCount=$(echo "$asg_json" | jq 'length')
        echo -e "\e[97m$timestamp — Instance Count: $instanceCount\e[0m"
        
        healthyCount=0
        
        echo "$asg_json" | jq -c '.[]' 2>/dev/null | while read -r inst; do
            id=$(echo "$inst" | jq -r '.ID')
            state=$(echo "$inst" | jq -r '.State')
            health=$(echo "$inst" | jq -r '.Health')
            
            if [ "$state" == "InService" ]; then
                stateColor="\e[32m" # Green
            elif [ "$state" == "Pending" ]; then
                stateColor="\e[33m" # Yellow
            elif [ "$state" == "Terminating" ]; then
                stateColor="\e[31m" # Red
            else
                stateColor="\e[90m" # Gray
            fi
            
            isNew=""
            if [ "$id" != "$FAILED_INSTANCE" ] && [ "$state" == "Pending" ]; then
                isNew=" ← NEW"
            fi
            
            echo -e "  ${id}: ${stateColor}${state}\e[0m (${health})${isNew}"
        done
        echo ""

        # Need to re-evaluate healthyCount outside the pipe subshell
        healthyCount=$(echo "$asg_json" | jq '[.[] | select(.State == "InService")] | length')
        
        if [ "$healthyCount" -ge 2 ] && [ $iterations -gt 2 ]; then
            echo -e "\e[32m  Self-healing complete! All instances InService.\e[0m"
            break
        fi
    else
        echo -e "$timestamp — Could not fetch ASG status"
        echo ""
    fi

    sleep 30
done

# ── FINAL STATE ───────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== Final State After Self-Healing ===\e[0m"
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names web-server-asg \
    --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus,AZ:AvailabilityZone}" \
    --output table

echo ""
echo -e "\e[33m  Key takeaway: ASG automatically replaced the failed instance.\e[0m"
echo -e "\e[33m  The ALB routed traffic to the healthy instance during replacement.\e[0m"
echo -e "\e[33m  Zero manual intervention required!\e[0m"
echo ""
echo -e "\e[36mNext step: Run 11-cleanup.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 10 — Script 10: Simulate Instance Failure
# Terminates an instance to demonstrate ASG self-healing
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Simulate Instance Failure ===" -ForegroundColor Cyan
Write-Host ""

# ── GET CURRENT INSTANCES ─────────────────────────────────────────────────────
Write-Host "[1/3] Getting current ASG instances..." -ForegroundColor Yellow

$INSTANCES = aws autoscaling describe-auto-scaling-groups `
    --auto-scaling-group-names web-server-asg `
    --query "AutoScalingGroups[0].Instances[*].InstanceId" `
    --output text

$INSTANCE_LIST = $INSTANCES -split '\s+'
Write-Host "  Current instances: $($INSTANCE_LIST -join ', ')" -ForegroundColor Green

$FAILED_INSTANCE = $INSTANCE_LIST[0]
Write-Host "  Instance to terminate (simulate failure): $FAILED_INSTANCE" -ForegroundColor Red
Write-Host ""

# ── SHOW BEFORE STATE ─────────────────────────────────────────────────────────
Write-Host "[2/3] Before failure — current state:" -ForegroundColor Yellow
aws autoscaling describe-auto-scaling-groups `
    --auto-scaling-group-names web-server-asg `
    --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus,AZ:AvailabilityZone}" `
    --output table

# ── TERMINATE INSTANCE ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Terminating instance: $FAILED_INSTANCE" -ForegroundColor Red
Write-Host "  ASG will detect the failure and launch a replacement..." -ForegroundColor Yellow

aws ec2 terminate-instances --instance-ids $FAILED_INSTANCE | Out-Null

Write-Host "  Termination initiated!" -ForegroundColor Red
Write-Host ""

# ── MONITOR SELF-HEALING ──────────────────────────────────────────────────────
Write-Host "=== Monitoring Self-Healing (Ctrl+C to stop) ===" -ForegroundColor Yellow
Write-Host "  Expected: ASG detects failure → launches new instance → registers in ALB" -ForegroundColor Yellow
Write-Host ""

$iterations = 0
$maxIterations = 20  # Monitor for ~10 minutes

while ($iterations -lt $maxIterations) {
    $iterations++

    $timestamp = Get-Date -Format 'HH:mm:ss'

    $asg = aws autoscaling describe-auto-scaling-groups `
        --auto-scaling-group-names web-server-asg `
        --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus}" `
        --output json | ConvertFrom-Json

    Write-Host "$timestamp — Instance Count: $($asg.Count)" -ForegroundColor White
    $asg | ForEach-Object {
        $stateColor = switch ($_.State) {
            "InService" { "Green" }
            "Pending" { "Yellow" }
            "Terminating" { "Red" }
            default { "Gray" }
        }
        $isNew = if ($_.ID -ne $FAILED_INSTANCE -and $_.State -eq "Pending") { " ← NEW" } else { "" }
        Write-Host "  $($_.ID): $($_.State) ($($_.Health))$isNew" -ForegroundColor $stateColor
    }
    Write-Host ""

    # Check if we have all healthy instances back
    $healthyCount = ($asg | Where-Object { $_.State -eq "InService" }).Count
    if ($healthyCount -ge 2 -and $iterations -gt 2) {
        Write-Host "  Self-healing complete! All instances InService." -ForegroundColor Green
        break
    }

    Start-Sleep -Seconds 30
}

# ── FINAL STATE ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Final State After Self-Healing ===" -ForegroundColor Cyan
aws autoscaling describe-auto-scaling-groups `
    --auto-scaling-group-names web-server-asg `
    --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus,AZ:AvailabilityZone}" `
    --output table

Write-Host ""
Write-Host "  Key takeaway: ASG automatically replaced the failed instance." -ForegroundColor Yellow
Write-Host "  The ALB routed traffic to the healthy instance during replacement." -ForegroundColor Yellow
Write-Host "  Zero manual intervention required!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run 11-cleanup.ps1" -ForegroundColor Cyan
```

---

## 🧹 TEARDOWN
To prevent recurring AWS charges, proceed to the `docs/cleanup-guide.md` to run the tear-down scripts.
