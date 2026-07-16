# Comprehensive Deployment Guide

This guide details the complete process for deploying this project's resources.

## 🏗️ PART 1 — CREATES SNS TOPIC AND EMAIL SUBSCRIPTION

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **SNS** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 7 — Script 01: SNS Topic and Email Subscription
# Creates the notification hub — all alarms route through this topic
# =============================================================================

echo -e "\e[36m=== Project 7 — SNS Setup ===\e[0m"
echo ""

# Pre-flight
aws sts get-caller-identity | Out-Null
if ($LASTEXITCODE -ne 0) {
echo -e "\e[31mERROR: AWS CLI not configured.\e[0m"
    exit 1
}

REGION=$(aws configure get region)
echo "Region: $REGION"
echo ""

# ── CREATE SNS TOPIC ──────────────────────────────────────────────────────────
echo -e "\e[33m[1/3] Creating SNS topic: monitoring-alerts...\e[0m"

SNS_ARN=$(aws sns create-topic \
    --name monitoring-alerts \
    --attributes DisplayName="AWS Monitoring" \
    --query "TopicArn" --output text)

echo -e "\e[32mSNS Topic ARN: $SNS_ARN\e[0m"

# ── CREATE EMAIL SUBSCRIPTION ─────────────────────────────────────────────────
echo ""
echo -e "\e[33m[2/3] Creating email subscription...\e[0m"
echo "Update the email address below before running this script."
echo ""

# ⚠️ Replace this with your actual email address
EMAIL="your-email@gmail.com"

aws sns subscribe \
    --topic-arn $SNS_ARN \
    --protocol email \
    --notification-endpoint $EMAIL | Out-Null

echo -e "\e[32mSubscription created for: $EMAIL\e[0m"
echo ""
echo -e "\e[31mIMPORTANT: Check your inbox and click 'Confirm subscription\e[0m"
echo -e "\e[33mCheck spam/junk folder if not received within 2 minutes.\e[0m"

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[3/3] Verifying subscription status...\e[0m"

aws sns list-subscriptions-by-topic \
    --topic-arn $SNS_ARN \
    --query "Subscriptions[*].{Protocol:Protocol,Endpoint:Endpoint,Status:SubscriptionArn}" \
    --output table

echo ""
echo -e "\e[36m=== SNS Setup Complete ===\e[0m"
echo ""
echo "  SNS_ARN = $SNS_ARN"
echo ""
echo "Status will show 'PendingConfirmation' until you click the email link."
echo "Alarms cannot send email until the subscription is confirmed."
echo ""
echo -e "\e[36mNext step: Run 02-launch-monitoring-ec2.ps1\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 7 — Script 01: SNS Topic and Email Subscription
# Creates the notification hub — all alarms route through this topic
# =============================================================================

Write-Host "=== Project 7 — SNS Setup ===" -ForegroundColor Cyan
Write-Host ""

# Pre-flight
aws sts get-caller-identity | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: AWS CLI not configured." -ForegroundColor Red
    exit 1
}

$REGION = aws configure get region
Write-Host "Region: $REGION"
Write-Host ""

# ── CREATE SNS TOPIC ──────────────────────────────────────────────────────────
Write-Host "[1/3] Creating SNS topic: monitoring-alerts..." -ForegroundColor Yellow

$SNS_ARN = aws sns create-topic `
    --name monitoring-alerts `
    --attributes DisplayName="AWS Monitoring" `
    --query "TopicArn" --output text

Write-Host "SNS Topic ARN: $SNS_ARN" -ForegroundColor Green

# ── CREATE EMAIL SUBSCRIPTION ─────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/3] Creating email subscription..." -ForegroundColor Yellow
Write-Host "Update the email address below before running this script."
Write-Host ""

# ⚠️ Replace this with your actual email address
$EMAIL = "your-email@gmail.com"

aws sns subscribe `
    --topic-arn $SNS_ARN `
    --protocol email `
    --notification-endpoint $EMAIL | Out-Null

Write-Host "Subscription created for: $EMAIL" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: Check your inbox and click 'Confirm subscription'" -ForegroundColor Red
Write-Host "Check spam/junk folder if not received within 2 minutes." -ForegroundColor Yellow

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Verifying subscription status..." -ForegroundColor Yellow

aws sns list-subscriptions-by-topic `
    --topic-arn $SNS_ARN `
    --query "Subscriptions[*].{Protocol:Protocol,Endpoint:Endpoint,Status:SubscriptionArn}" `
    --output table

Write-Host ""
Write-Host "=== SNS Setup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  SNS_ARN = $SNS_ARN"
Write-Host ""
Write-Host "Status will show 'PendingConfirmation' until you click the email link."
Write-Host "Alarms cannot send email until the subscription is confirmed."
Write-Host ""
Write-Host "Next step: Run 02-launch-monitoring-ec2.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 2 — LAUNCHES EC2 INSTANCE FOR TESTING

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
# Project 7 — Script 02: Launch EC2 for Monitoring
# Launches a t2.micro in the default VPC to generate CloudWatch metrics
# =============================================================================

echo -e "\e[36m=== Project 7 — Launch Monitoring EC2 ===\e[0m"
echo ""

if (-not $SNS_ARN) {
echo -e "\e[33mWARNING: SNS_ARN not set. Run 01-sns-setup.ps1 first.\e[0m"
}

# ── GET DEFAULT VPC ───────────────────────────────────────────────────────────
echo -e "\e[33m[1/4] Getting default VPC and subnet...\e[0m"

VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --query "Vpcs[0].VpcId" --output text)

SUBNET_ID=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=defaultForAz,Values=true" \
    --query "Subnets[0].SubnetId" --output text)

echo "Default VPC:    $VPC_ID"
echo "Default Subnet: $SUBNET_ID"

# ── SECURITY GROUP ────────────────────────────────────────────────────────────
echo -e "\e[33m[2/4] Creating security group...\e[0m"

MY_IP=(Invoke-WebRequest -Uri "https://checkip.amazonaws.com" \
        -UseBasicParsing).Content.Trim()

MON_SG=$(aws ec2 create-security-group \
    --group-name monitoring-test-sg \
    --description "SG for CloudWatch monitoring test" \
    --vpc-id $VPC_ID \
    --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $MON_SG \
    --protocol tcp --port 22 --cidr "$MY_IP/32"

echo "Security group: $MON_SG (SSH from $MY_IP only)"

# ── FIND AMI ──────────────────────────────────────────────────────────────────
echo -e "\e[33m[3/4] Finding latest Amazon Linux 2023 AMI...\e[0m"

AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-*-x86_64" \
    "Name=state,Values=available" \
    --query "sort_by(Images,&CreationDate)[-1].ImageId" \
    --output text)

echo "AMI: $AMI_ID"

# ── LAUNCH INSTANCE ───────────────────────────────────────────────────────────
echo -e "\e[33m[4/4] Launching instance...\e[0m"

MON_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --key-name aws-ec2-keypair \
    --subnet-id $SUBNET_ID \
    --security-group-ids $MON_SG \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=monitoring-test}]" \
    --query "Instances[0].InstanceId" \
    --output text)

echo -e "\e[32mInstance ID: $MON_INSTANCE_ID\e[0m"
echo -e "\e[33mWaiting for instance to enter running state...\e[0m"

aws ec2 wait instance-running --instance-ids $MON_INSTANCE_ID

MON_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $MON_INSTANCE_ID \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

echo -e "\e[32mInstance running. Public IP: $MON_PUBLIC_IP\e[0m"

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== EC2 Launch Complete ===\e[0m"
echo ""
echo "  MON_INSTANCE_ID = $MON_INSTANCE_ID"
echo "  MON_PUBLIC_IP   = $MON_PUBLIC_IP"
echo "  MON_SG          = $MON_SG"
echo ""
echo "Wait 5 minutes for CloudWatch metrics to start publishing."
echo "SSH command: ssh -i aws-ec2-keypair.pem ec2-user@$MON_PUBLIC_IP"
echo ""
echo -e "\e[36mNext step: Run 03-create-ec2-alarms.ps1\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 7 — Script 02: Launch EC2 for Monitoring
# Launches a t2.micro in the default VPC to generate CloudWatch metrics
# =============================================================================

Write-Host "=== Project 7 — Launch Monitoring EC2 ===" -ForegroundColor Cyan
Write-Host ""

if (-not $SNS_ARN) {
    Write-Host "WARNING: SNS_ARN not set. Run 01-sns-setup.ps1 first." -ForegroundColor Yellow
}

# ── GET DEFAULT VPC ───────────────────────────────────────────────────────────
Write-Host "[1/4] Getting default VPC and subnet..." -ForegroundColor Yellow

$VPC_ID = aws ec2 describe-vpcs `
    --filters "Name=isDefault,Values=true" `
    --query "Vpcs[0].VpcId" --output text

$SUBNET_ID = aws ec2 describe-subnets `
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=defaultForAz,Values=true" `
    --query "Subnets[0].SubnetId" --output text

Write-Host "Default VPC:    $VPC_ID"
Write-Host "Default Subnet: $SUBNET_ID"

# ── SECURITY GROUP ────────────────────────────────────────────────────────────
Write-Host "[2/4] Creating security group..." -ForegroundColor Yellow

$MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" `
        -UseBasicParsing).Content.Trim()

$MON_SG = aws ec2 create-security-group `
    --group-name monitoring-test-sg `
    --description "SG for CloudWatch monitoring test" `
    --vpc-id $VPC_ID `
    --query "GroupId" --output text

aws ec2 authorize-security-group-ingress `
    --group-id $MON_SG `
    --protocol tcp --port 22 --cidr "$MY_IP/32"

Write-Host "Security group: $MON_SG (SSH from $MY_IP only)"

# ── FIND AMI ──────────────────────────────────────────────────────────────────
Write-Host "[3/4] Finding latest Amazon Linux 2023 AMI..." -ForegroundColor Yellow

$AMI_ID = aws ec2 describe-images `
    --owners amazon `
    --filters "Name=name,Values=al2023-ami-*-x86_64" `
    "Name=state,Values=available" `
    --query "sort_by(Images,&CreationDate)[-1].ImageId" `
    --output text

Write-Host "AMI: $AMI_ID"

# ── LAUNCH INSTANCE ───────────────────────────────────────────────────────────
Write-Host "[4/4] Launching instance..." -ForegroundColor Yellow

$MON_INSTANCE_ID = aws ec2 run-instances `
    --image-id $AMI_ID `
    --instance-type t2.micro `
    --key-name aws-ec2-keypair `
    --subnet-id $SUBNET_ID `
    --security-group-ids $MON_SG `
    --associate-public-ip-address `
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=monitoring-test}]" `
    --query "Instances[0].InstanceId" `
    --output text

Write-Host "Instance ID: $MON_INSTANCE_ID" -ForegroundColor Green
Write-Host "Waiting for instance to enter running state..." -ForegroundColor Yellow

aws ec2 wait instance-running --instance-ids $MON_INSTANCE_ID

$MON_PUBLIC_IP = aws ec2 describe-instances `
    --instance-ids $MON_INSTANCE_ID `
    --query "Reservations[0].Instances[0].PublicIpAddress" `
    --output text

Write-Host "Instance running. Public IP: $MON_PUBLIC_IP" -ForegroundColor Green

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== EC2 Launch Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  MON_INSTANCE_ID = $MON_INSTANCE_ID"
Write-Host "  MON_PUBLIC_IP   = $MON_PUBLIC_IP"
Write-Host "  MON_SG          = $MON_SG"
Write-Host ""
Write-Host "Wait 5 minutes for CloudWatch metrics to start publishing."
Write-Host "SSH command: ssh -i aws-ec2-keypair.pem ec2-user@$MON_PUBLIC_IP"
Write-Host ""
Write-Host "Next step: Run 03-create-ec2-alarms.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 3 — CREATES CPU, NETWORK, AND STATUSCHECK ALARMS

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **CloudWatch** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 7 — Script 03: EC2 CloudWatch Alarms
# Creates CPU, StatusCheck, and NetworkIn alarms for the monitoring EC2 instance
# =============================================================================

echo -e "\e[36m=== Project 7 — EC2 CloudWatch Alarms ===\e[0m"
echo ""

if (-not $MON_INSTANCE_ID -or -not $SNS_ARN) {
echo -e "\e[31mERROR: MON_INSTANCE_ID or SNS_ARN not set.\e[0m"
echo "Run 01-sns-setup.ps1 and 02-launch-monitoring-ec2.ps1 first."
    exit 1
}

echo "Instance: $MON_INSTANCE_ID"
echo "SNS ARN:  $SNS_ARN"
echo ""

# ── ALARM 1: EC2 HIGH CPU ─────────────────────────────────────────────────────
echo -e "\e[33m[1/3] Creating EC2-CPU-High alarm...\e[0m"

aws cloudwatch put-metric-alarm \
  --alarm-name "EC2-CPU-High" \
  --alarm-description "EC2 CPU utilization exceeded 70% for 10 minutes" \
  --namespace "AWS/EC2" \
  --metric-name "CPUUtilization" \
  --dimensions Name=InstanceId,Value=$MON_INSTANCE_ID \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 70 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions $SNS_ARN \
  --ok-actions $SNS_ARN \
  --treat-missing-data notBreaching

echo -e "\e[32m  EC2-CPU-High created (Average CPU > 70% for 2x5min)\e[0m"

# ── ALARM 2: STATUS CHECK FAILED ──────────────────────────────────────────────
echo -e "\e[33m[2/3] Creating EC2-StatusCheck-Failed alarm...\e[0m"

aws cloudwatch put-metric-alarm \
  --alarm-name "EC2-StatusCheck-Failed" \
  --alarm-description "EC2 instance failed status check — hardware or OS issue" \
  --namespace "AWS/EC2" \
  --metric-name "StatusCheckFailed" \
  --dimensions Name=InstanceId,Value=$MON_INSTANCE_ID \
  --statistic Maximum \
  --period 60 \
  --evaluation-periods 2 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --alarm-actions $SNS_ARN \
  --treat-missing-data notBreaching

echo -e "\e[32m  EC2-StatusCheck-Failed created (Maximum >= 1 for 2x1min)\e[0m"

# ── ALARM 3: HIGH NETWORK IN ──────────────────────────────────────────────────
echo -e "\e[33m[3/3] Creating EC2-NetworkIn-High alarm...\e[0m"

aws cloudwatch put-metric-alarm \
  --alarm-name "EC2-NetworkIn-High" \
  --alarm-description "EC2 inbound network traffic unusually high — potential anomaly" \
  --namespace "AWS/EC2" \
  --metric-name "NetworkIn" \
  --dimensions Name=InstanceId,Value=$MON_INSTANCE_ID \
  --statistic Average \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 5000000 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions $SNS_ARN \
  --treat-missing-data notBreaching

echo -e "\e[32m  EC2-NetworkIn-High created (Average > 5MB per 5min)\e[0m"

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mVerifying EC2 alarms...\e[0m"

aws cloudwatch describe-alarms \
  --alarm-names "EC2-CPU-High" "EC2-StatusCheck-Failed" "EC2-NetworkIn-High" \
  --query "MetricAlarms[*].{Name:AlarmName,State:StateValue,Metric:MetricName,Threshold:Threshold}" \
  --output table

echo ""
echo -e "\e[36m=== EC2 Alarms Complete ===\e[0m"
echo ""
echo "Expected states: INSUFFICIENT_DATA (until first metric data points arrive)"
echo "States transition to OK within 5-10 minutes of instance running."
echo ""
echo -e "\e[36mNext step: Run 04-create-rds-alarms.ps1\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 7 — Script 03: EC2 CloudWatch Alarms
# Creates CPU, StatusCheck, and NetworkIn alarms for the monitoring EC2 instance
# =============================================================================

Write-Host "=== Project 7 — EC2 CloudWatch Alarms ===" -ForegroundColor Cyan
Write-Host ""

if (-not $MON_INSTANCE_ID -or -not $SNS_ARN) {
    Write-Host "ERROR: MON_INSTANCE_ID or SNS_ARN not set." -ForegroundColor Red
    Write-Host "Run 01-sns-setup.ps1 and 02-launch-monitoring-ec2.ps1 first."
    exit 1
}

Write-Host "Instance: $MON_INSTANCE_ID"
Write-Host "SNS ARN:  $SNS_ARN"
Write-Host ""

# ── ALARM 1: EC2 HIGH CPU ─────────────────────────────────────────────────────
Write-Host "[1/3] Creating EC2-CPU-High alarm..." -ForegroundColor Yellow

aws cloudwatch put-metric-alarm `
  --alarm-name "EC2-CPU-High" `
  --alarm-description "EC2 CPU utilization exceeded 70% for 10 minutes" `
  --namespace "AWS/EC2" `
  --metric-name "CPUUtilization" `
  --dimensions Name=InstanceId,Value=$MON_INSTANCE_ID `
  --statistic Average `
  --period 300 `
  --evaluation-periods 2 `
  --threshold 70 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --ok-actions $SNS_ARN `
  --treat-missing-data notBreaching

Write-Host "  EC2-CPU-High created (Average CPU > 70% for 2x5min)" -ForegroundColor Green

# ── ALARM 2: STATUS CHECK FAILED ──────────────────────────────────────────────
Write-Host "[2/3] Creating EC2-StatusCheck-Failed alarm..." -ForegroundColor Yellow

aws cloudwatch put-metric-alarm `
  --alarm-name "EC2-StatusCheck-Failed" `
  --alarm-description "EC2 instance failed status check — hardware or OS issue" `
  --namespace "AWS/EC2" `
  --metric-name "StatusCheckFailed" `
  --dimensions Name=InstanceId,Value=$MON_INSTANCE_ID `
  --statistic Maximum `
  --period 60 `
  --evaluation-periods 2 `
  --threshold 1 `
  --comparison-operator GreaterThanOrEqualToThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data notBreaching

Write-Host "  EC2-StatusCheck-Failed created (Maximum >= 1 for 2x1min)" -ForegroundColor Green

# ── ALARM 3: HIGH NETWORK IN ──────────────────────────────────────────────────
Write-Host "[3/3] Creating EC2-NetworkIn-High alarm..." -ForegroundColor Yellow

aws cloudwatch put-metric-alarm `
  --alarm-name "EC2-NetworkIn-High" `
  --alarm-description "EC2 inbound network traffic unusually high — potential anomaly" `
  --namespace "AWS/EC2" `
  --metric-name "NetworkIn" `
  --dimensions Name=InstanceId,Value=$MON_INSTANCE_ID `
  --statistic Average `
  --period 300 `
  --evaluation-periods 1 `
  --threshold 5000000 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data notBreaching

Write-Host "  EC2-NetworkIn-High created (Average > 5MB per 5min)" -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying EC2 alarms..." -ForegroundColor Yellow

aws cloudwatch describe-alarms `
  --alarm-names "EC2-CPU-High" "EC2-StatusCheck-Failed" "EC2-NetworkIn-High" `
  --query "MetricAlarms[*].{Name:AlarmName,State:StateValue,Metric:MetricName,Threshold:Threshold}" `
  --output table

Write-Host ""
Write-Host "=== EC2 Alarms Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Expected states: INSUFFICIENT_DATA (until first metric data points arrive)"
Write-Host "States transition to OK within 5-10 minutes of instance running."
Write-Host ""
Write-Host "Next step: Run 04-create-rds-alarms.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 4 — CREATES RDS CPU, STORAGE, AND CONNECTIONS ALARMS

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **RDS** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 7 — Script 04: RDS CloudWatch Alarms
# Creates CPU, storage, and connection alarms for myapp-database
# Note: Alarms stay INSUFFICIENT_DATA if RDS from Project 6 was deleted — this is normal
# =============================================================================

echo -e "\e[36m=== Project 7 — RDS CloudWatch Alarms ===\e[0m"
echo ""

if (-not $SNS_ARN) {
echo -e "\e[31mERROR: SNS_ARN not set. Run 01-sns-setup.ps1 first.\e[0m"
    exit 1
}

echo "Target RDS instance: myapp-database"
echo "SNS ARN: $SNS_ARN"
echo ""
echo "Note: Alarms will be INSUFFICIENT_DATA if myapp-database does not exist."
echo "This is expected if Project 6 was cleaned up. Alarms are still valid."
echo ""

# ── ALARM 4: RDS HIGH CPU ─────────────────────────────────────────────────────
echo -e "\e[33m[1/3] Creating RDS-CPU-High alarm...\e[0m"

aws cloudwatch put-metric-alarm \
  --alarm-name "RDS-CPU-High" \
  --alarm-description "RDS CPU utilization exceeded 80% for 10 minutes" \
  --namespace "AWS/RDS" \
  --metric-name "CPUUtilization" \
  --dimensions Name=DBInstanceIdentifier,Value=myapp-database \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions $SNS_ARN \
  --ok-actions $SNS_ARN \
  --treat-missing-data notBreaching

echo -e "\e[32m  RDS-CPU-High created (Average CPU > 80% for 2x5min)\e[0m"

# ── ALARM 5: RDS LOW FREE STORAGE ─────────────────────────────────────────────
echo -e "\e[33m[2/3] Creating RDS-Storage-Low alarm...\e[0m"

# Threshold: 2,000,000,000 bytes = ~2GB
aws cloudwatch put-metric-alarm \
  --alarm-name "RDS-Storage-Low" \
  --alarm-description "RDS free storage space below 2GB — action required before write failures" \
  --namespace "AWS/RDS" \
  --metric-name "FreeStorageSpace" \
  --dimensions Name=DBInstanceIdentifier,Value=myapp-database \
  --statistic Average \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 2000000000 \
  --comparison-operator LessThanThreshold \
  --alarm-actions $SNS_ARN \
  --ok-actions $SNS_ARN \
  --treat-missing-data notBreaching

echo -e "\e[32m  RDS-Storage-Low created (FreeStorage < 2GB)\e[0m"

# ── ALARM 6: RDS HIGH CONNECTIONS ─────────────────────────────────────────────
echo -e "\e[33m[3/3] Creating RDS-Connections-High alarm...\e[0m"

# db.t3.micro max connections = 66; alert at 50 (76% of max)
aws cloudwatch put-metric-alarm \
  --alarm-name "RDS-Connections-High" \
  --alarm-description "RDS connection count exceeded 50 (db.t3.micro max: 66)" \
  --namespace "AWS/RDS" \
  --metric-name "DatabaseConnections" \
  --dimensions Name=DBInstanceIdentifier,Value=myapp-database \
  --statistic Average \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions $SNS_ARN \
  --treat-missing-data notBreaching

echo -e "\e[32m  RDS-Connections-High created (DatabaseConnections > 50)\e[0m"

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mVerifying RDS alarms...\e[0m"

aws cloudwatch describe-alarms \
  --alarm-names "RDS-CPU-High" "RDS-Storage-Low" "RDS-Connections-High" \
  --query "MetricAlarms[*].{Name:AlarmName,State:StateValue,Metric:MetricName,Threshold:Threshold}" \
  --output table

echo ""
echo -e "\e[36m=== RDS Alarms Complete ===\e[0m"
echo ""
echo -e "\e[36mNext step: Run 05-create-billing-alarm.ps1\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 7 — Script 04: RDS CloudWatch Alarms
# Creates CPU, storage, and connection alarms for myapp-database
# Note: Alarms stay INSUFFICIENT_DATA if RDS from Project 6 was deleted — this is normal
# =============================================================================

Write-Host "=== Project 7 — RDS CloudWatch Alarms ===" -ForegroundColor Cyan
Write-Host ""

if (-not $SNS_ARN) {
    Write-Host "ERROR: SNS_ARN not set. Run 01-sns-setup.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "Target RDS instance: myapp-database"
Write-Host "SNS ARN: $SNS_ARN"
Write-Host ""
Write-Host "Note: Alarms will be INSUFFICIENT_DATA if myapp-database does not exist."
Write-Host "This is expected if Project 6 was cleaned up. Alarms are still valid."
Write-Host ""

# ── ALARM 4: RDS HIGH CPU ─────────────────────────────────────────────────────
Write-Host "[1/3] Creating RDS-CPU-High alarm..." -ForegroundColor Yellow

aws cloudwatch put-metric-alarm `
  --alarm-name "RDS-CPU-High" `
  --alarm-description "RDS CPU utilization exceeded 80% for 10 minutes" `
  --namespace "AWS/RDS" `
  --metric-name "CPUUtilization" `
  --dimensions Name=DBInstanceIdentifier,Value=myapp-database `
  --statistic Average `
  --period 300 `
  --evaluation-periods 2 `
  --threshold 80 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --ok-actions $SNS_ARN `
  --treat-missing-data notBreaching

Write-Host "  RDS-CPU-High created (Average CPU > 80% for 2x5min)" -ForegroundColor Green

# ── ALARM 5: RDS LOW FREE STORAGE ─────────────────────────────────────────────
Write-Host "[2/3] Creating RDS-Storage-Low alarm..." -ForegroundColor Yellow

# Threshold: 2,000,000,000 bytes = ~2GB
aws cloudwatch put-metric-alarm `
  --alarm-name "RDS-Storage-Low" `
  --alarm-description "RDS free storage space below 2GB — action required before write failures" `
  --namespace "AWS/RDS" `
  --metric-name "FreeStorageSpace" `
  --dimensions Name=DBInstanceIdentifier,Value=myapp-database `
  --statistic Average `
  --period 300 `
  --evaluation-periods 1 `
  --threshold 2000000000 `
  --comparison-operator LessThanThreshold `
  --alarm-actions $SNS_ARN `
  --ok-actions $SNS_ARN `
  --treat-missing-data notBreaching

Write-Host "  RDS-Storage-Low created (FreeStorage < 2GB)" -ForegroundColor Green

# ── ALARM 6: RDS HIGH CONNECTIONS ─────────────────────────────────────────────
Write-Host "[3/3] Creating RDS-Connections-High alarm..." -ForegroundColor Yellow

# db.t3.micro max connections = 66; alert at 50 (76% of max)
aws cloudwatch put-metric-alarm `
  --alarm-name "RDS-Connections-High" `
  --alarm-description "RDS connection count exceeded 50 (db.t3.micro max: 66)" `
  --namespace "AWS/RDS" `
  --metric-name "DatabaseConnections" `
  --dimensions Name=DBInstanceIdentifier,Value=myapp-database `
  --statistic Average `
  --period 300 `
  --evaluation-periods 1 `
  --threshold 50 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data notBreaching

Write-Host "  RDS-Connections-High created (DatabaseConnections > 50)" -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying RDS alarms..." -ForegroundColor Yellow

aws cloudwatch describe-alarms `
  --alarm-names "RDS-CPU-High" "RDS-Storage-Low" "RDS-Connections-High" `
  --query "MetricAlarms[*].{Name:AlarmName,State:StateValue,Metric:MetricName,Threshold:Threshold}" `
  --output table

Write-Host ""
Write-Host "=== RDS Alarms Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next step: Run 05-create-billing-alarm.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 5 — CREATES $5 BILLING THRESHOLD ALARM IN US-EAST-1

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **CloudWatch** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 7 — Script 05: Billing Alarm
# MUST run in us-east-1 — billing metrics are only in this region
# =============================================================================

echo -e "\e[36m=== Project 7 — Billing Alarm ===\e[0m"
echo ""
echo -e "\e[31mIMPORTANT: Billing metrics are only available in us-east-1\e[0m"
echo -e "\e[33mThis script forces us-east-1 regardless of your configured region.\e[0m"
echo ""

if (-not $SNS_ARN) {
echo -e "\e[31mERROR: SNS_ARN not set. Run 01-sns-setup.ps1 first.\e[0m"
    exit 1
}

# Force us-east-1 for billing metrics
$env:AWS_DEFAULT_REGION = "us-east-1"
echo -e "\e[32mRegion forced to: us-east-1\e[0m"
echo ""

# ── BILLING ALARM ─────────────────────────────────────────────────────────────
echo -e "\e[33mCreating Billing-Alert-5USD alarm...\e[0m"
echo "Threshold: EstimatedCharges > USD 5.00 (daily evaluation)"
echo ""

aws cloudwatch put-metric-alarm \
  --alarm-name "Billing-Alert-5USD" \
  --alarm-description "AWS monthly estimated charges exceeded USD 5 — check for unintended resources" \
  --namespace "AWS/Billing" \
  --metric-name "EstimatedCharges" \
  --dimensions Name=Currency,Value=USD \
  --statistic Maximum \
  --period 86400 \
  --evaluation-periods 1 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions $SNS_ARN \
  --treat-missing-data notBreaching \
  --region us-east-1

echo -e "\e[32mBilling-Alert-5USD created.\e[0m"

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mVerifying billing alarm (us-east-1)...\e[0m"

aws cloudwatch describe-alarms \
  --alarm-names "Billing-Alert-5USD" \
  --region us-east-1 \
  --query "MetricAlarms[0].{Name:AlarmName,State:StateValue,Threshold:Threshold,Namespace:Namespace}" \
  --output table

echo ""
echo -e "\e[36m=== Billing Alarm Complete ===\e[0m"
echo ""
echo "Note: Billing metrics update once per day."
echo "The alarm may show INSUFFICIENT_DATA until the next daily metric update."
echo ""
echo "Console path: CloudWatch (us-east-1) -> Alarms -> Billing-Alert-5USD"
echo ""
echo -e "\e[36mNext step: Run 06-generate-cpu-load.sh on the EC2 instance (via SSH)\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 7 — Script 05: Billing Alarm
# MUST run in us-east-1 — billing metrics are only in this region
# =============================================================================

Write-Host "=== Project 7 — Billing Alarm ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: Billing metrics are only available in us-east-1" -ForegroundColor Red
Write-Host "This script forces us-east-1 regardless of your configured region." -ForegroundColor Yellow
Write-Host ""

if (-not $SNS_ARN) {
    Write-Host "ERROR: SNS_ARN not set. Run 01-sns-setup.ps1 first." -ForegroundColor Red
    exit 1
}

# Force us-east-1 for billing metrics
$env:AWS_DEFAULT_REGION = "us-east-1"
Write-Host "Region forced to: us-east-1" -ForegroundColor Green
Write-Host ""

# ── BILLING ALARM ─────────────────────────────────────────────────────────────
Write-Host "Creating Billing-Alert-5USD alarm..." -ForegroundColor Yellow
Write-Host "Threshold: EstimatedCharges > USD 5.00 (daily evaluation)"
Write-Host ""

aws cloudwatch put-metric-alarm `
  --alarm-name "Billing-Alert-5USD" `
  --alarm-description "AWS monthly estimated charges exceeded USD 5 — check for unintended resources" `
  --namespace "AWS/Billing" `
  --metric-name "EstimatedCharges" `
  --dimensions Name=Currency,Value=USD `
  --statistic Maximum `
  --period 86400 `
  --evaluation-periods 1 `
  --threshold 5 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data notBreaching `
  --region us-east-1

Write-Host "Billing-Alert-5USD created." -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying billing alarm (us-east-1)..." -ForegroundColor Yellow

aws cloudwatch describe-alarms `
  --alarm-names "Billing-Alert-5USD" `
  --region us-east-1 `
  --query "MetricAlarms[0].{Name:AlarmName,State:StateValue,Threshold:Threshold,Namespace:Namespace}" `
  --output table

Write-Host ""
Write-Host "=== Billing Alarm Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Billing metrics update once per day."
Write-Host "The alarm may show INSUFFICIENT_DATA until the next daily metric update."
Write-Host ""
Write-Host "Console path: CloudWatch (us-east-1) -> Alarms -> Billing-Alert-5USD"
Write-Host ""
Write-Host "Next step: Run 06-generate-cpu-load.sh on the EC2 instance (via SSH)" -ForegroundColor Cyan
```

---

## 🏗️ PART 6 — STRESSES EC2 TO TRIGGER CPU ALARM

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
# Project 7 — Script 06: Generate CPU Load
# Run this INSIDE the EC2 instance via SSH to trigger the CPU alarm
# =============================================================================
# SSH command: ssh -i aws-ec2-keypair.pem ec2-user@YOUR_PUBLIC_IP
# Then run: bash 06-generate-cpu-load.sh
# =============================================================================

echo "=== Project 7 — CPU Load Generator ==="
echo ""
echo "Purpose: Push CPU above 70% for 2 consecutive 5-minute periods"
echo "This triggers the EC2-CPU-High CloudWatch alarm."
echo ""
echo "The alarm requires 2 x 5-minute periods above 70% = 10 minutes minimum."
echo "We run stress for 12 minutes to guarantee two full evaluation windows."
echo ""

# Install stress if not already present
if ! command -v stress &> /dev/null; then
    echo "Installing stress tool..."
    sudo yum install -y stress -q
    echo "stress installed."
fi

echo "Current CPU usage (before stress):"
top -bn1 | grep "Cpu(s)" | awk '{print "  " $0}'
echo ""

echo "Starting CPU stress — 1 core for 720 seconds (12 minutes)..."
echo "Watch: CloudWatch -> Alarms -> EC2-CPU-High (updates every 5 min)"
echo ""
echo "To monitor progress from a second SSH session:"
echo "  watch -n 5 'top -bn1 | grep Cpu'"
echo ""
echo "Expected alarm timeline:"
echo "  0:00  — stress starts, CPU hits ~100%"
echo "  5:00  — first evaluation period completes (breach #1)"
echo "  10:00 — second evaluation period completes (breach #2) -> ALARM fires"
echo "  10:00 — SNS email sent to your inbox"
echo "  12:00 — stress stops, CPU returns to baseline"
echo "  17:00 — alarm transitions OK -> SNS recovery email sent"
echo ""

# Run stress for 720 seconds (12 minutes)
sudo stress --cpu 1 --timeout 720 &
STRESS_PID=$!

echo "Stress process started (PID: $STRESS_PID)"
echo ""

# Show live CPU every 60 seconds while stress runs
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    sleep 60
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | tr -d '%us,')
    echo "  Minute $i — CPU utilization: ${CPU}%"
done

echo ""
echo "Stress complete. CPU returning to baseline."
echo ""
echo "Check CloudWatch in 5-10 minutes for alarm state transition."
echo "Check your email for the alarm notification."
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 7 — Script 06: Generate CPU Load
# Run this locally to get SSH instructions for the EC2 instance
# =============================================================================

Write-Host "=== Project 7 — CPU Load Generator ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Purpose: Push CPU above 70% for 2 consecutive 5-minute periods"
Write-Host "This triggers the EC2-CPU-High CloudWatch alarm."
Write-Host ""
Write-Host "To generate CPU load, you must SSH into the EC2 instance and run stress." -ForegroundColor Yellow
Write-Host ""

if (-not $MON_INSTANCE_ID) {
    $MON_INSTANCE_ID = aws ec2 describe-instances `
      --filters "Name=tag:Name,Values=monitoring-test" `
      --query "Reservations[0].Instances[0].InstanceId" `
      --output text
}

if ($MON_INSTANCE_ID -and $MON_INSTANCE_ID -ne "None") {
    $MON_PUBLIC_IP = aws ec2 describe-instances `
      --instance-ids $MON_INSTANCE_ID `
      --query "Reservations[0].Instances[0].PublicIpAddress" `
      --output text

    Write-Host "1. Open a new terminal and run:" -ForegroundColor Green
    Write-Host "   ssh -i aws-ec2-keypair.pem ec2-user@$MON_PUBLIC_IP"
    Write-Host ""
    Write-Host "2. Once connected, run the following commands:" -ForegroundColor Green
    Write-Host "   sudo yum install -y stress"
    Write-Host "   sudo stress --cpu 1 --timeout 720"
    Write-Host ""
    Write-Host "3. Watch the alarm state change in the AWS Console (CloudWatch -> Alarms)." -ForegroundColor Green
} else {
    Write-Host "Could not find monitoring-test instance. Please launch it first." -ForegroundColor Red
}
```

---

## 🏗️ PART 7 — DEPLOYS CLOUDWATCH MULTI-WIDGET DASHBOARD

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **CloudWatch** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 7 — Script 07: CloudWatch Dashboard
# Creates AWS-Bootcamp-Dashboard with EC2, RDS, and billing widgets
# =============================================================================

echo -e "\e[36m=== Project 7 — CloudWatch Dashboard ===\e[0m"
echo ""

if (-not $MON_INSTANCE_ID) {
echo -e "\e[31mERROR: MON_INSTANCE_ID not set. Run 02-launch-monitoring-ec2.ps1 first.\e[0m"
    exit 1
}

echo -e "\e[33mBuilding dashboard for instance: $MON_INSTANCE_ID\e[0m"
echo ""

# ── BUILD DASHBOARD JSON ──────────────────────────────────────────────────────
DASHBOARD_BODY=@"
{
  "widgets": [
    {
      "type": "metric",
      "x": 0, "y": 0, "width": 12, "height": 6,
      "properties": {
        "title": "EC2 CPU Utilization",
        "metrics": [
          ["AWS/EC2","CPUUtilization","InstanceId","$MON_INSTANCE_ID",
           {"stat":"Average","period":300,"color":"#2196F3","label":"CPU %"}]
        ],
        "view": "timeSeries",
        "annotations": {
          "horizontal": [{"value":70,"color":"#f44336","label":"Alarm threshold (70%)"}]
        },
        "period": 300,
        "yAxis": {"left":{"min":0,"max":100}},
        "region": "us-east-1",
        "legend": {"position":"bottom"}
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 0, "width": 12, "height": 6,
      "properties": {
        "title": "EC2 Network Traffic",
        "metrics": [
          ["AWS/EC2","NetworkIn","InstanceId","$MON_INSTANCE_ID",
           {"stat":"Average","period":300,"color":"#4CAF50","label":"Network In (bytes)"}],
          ["AWS/EC2","NetworkOut","InstanceId","$MON_INSTANCE_ID",
           {"stat":"Average","period":300,"color":"#FF9800","label":"Network Out (bytes)"}]
        ],
        "view": "timeSeries",
        "region": "us-east-1",
        "legend": {"position":"bottom"}
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 6, "width": 12, "height": 6,
      "properties": {
        "title": "RDS CPU Utilization",
        "metrics": [
          ["AWS/RDS","CPUUtilization","DBInstanceIdentifier","myapp-database",
           {"stat":"Average","period":300,"color":"#9C27B0","label":"RDS CPU %"}]
        ],
        "view": "timeSeries",
        "annotations": {
          "horizontal": [{"value":80,"color":"#f44336","label":"Alarm threshold (80%)"}]
        },
        "region": "us-east-1"
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 6, "width": 6, "height": 6,
      "properties": {
        "title": "RDS Database Connections",
        "metrics": [
          ["AWS/RDS","DatabaseConnections","DBInstanceIdentifier","myapp-database",
           {"stat":"Average","period":300,"color":"#E91E63"}]
        ],
        "view": "singleValue",
        "region": "us-east-1"
      }
    },
    {
      "type": "metric",
      "x": 18, "y": 6, "width": 6, "height": 6,
      "properties": {
        "title": "Estimated AWS Charges (USD)",
        "metrics": [
          ["AWS/Billing","EstimatedCharges","Currency","USD",
           {"stat":"Maximum","period":86400,"color":"#FF5722"}]
        ],
        "view": "singleValue",
        "region": "us-east-1"
      }
    }
  ]
}
"@

# Save dashboard JSON
$DASHBOARD_BODY | Out-File -FilePath "dashboard.json" -Encoding utf8
echo -e "\e[32mDashboard JSON saved to dashboard.json\e[0m"

# ── UPLOAD DASHBOARD ──────────────────────────────────────────────────────────
echo -e "\e[33mUploading dashboard to CloudWatch...\e[0m"

aws cloudwatch put-dashboard \
  --dashboard-name "AWS-Bootcamp-Dashboard" \
  --dashboard-body file://dashboard.json

echo -e "\e[32mDashboard created.\e[0m"

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mVerifying dashboard...\e[0m"

aws cloudwatch list-dashboards \
  --query "DashboardEntries[?DashboardName=='AWS-Bootcamp-Dashboard'].{Name:DashboardName,Size:Size,Modified:LastModified}" \
  --output table

echo ""
echo -e "\e[36m=== Dashboard Complete ===\e[0m"
echo ""
echo "Console path: CloudWatch -> Dashboards -> AWS-Bootcamp-Dashboard"
echo ""
echo "Widgets created:"
echo "  1. EC2 CPU Utilization (line chart, 70% threshold line)"
echo "  2. EC2 Network Traffic (NetworkIn + NetworkOut dual line)"
echo "  3. RDS CPU Utilization (line chart, 80% threshold line)"
echo "  4. RDS Database Connections (single value)"
echo "  5. Estimated AWS Charges USD (single value)"
echo ""
echo -e "\e[36mNext step: Run 08-create-log-group.ps1\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 7 — Script 07: CloudWatch Dashboard
# Creates AWS-Bootcamp-Dashboard with EC2, RDS, and billing widgets
# =============================================================================

Write-Host "=== Project 7 — CloudWatch Dashboard ===" -ForegroundColor Cyan
Write-Host ""

if (-not $MON_INSTANCE_ID) {
    Write-Host "ERROR: MON_INSTANCE_ID not set. Run 02-launch-monitoring-ec2.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "Building dashboard for instance: $MON_INSTANCE_ID" -ForegroundColor Yellow
Write-Host ""

# ── BUILD DASHBOARD JSON ──────────────────────────────────────────────────────
$DASHBOARD_BODY = @"
{
  "widgets": [
    {
      "type": "metric",
      "x": 0, "y": 0, "width": 12, "height": 6,
      "properties": {
        "title": "EC2 CPU Utilization",
        "metrics": [
          ["AWS/EC2","CPUUtilization","InstanceId","$MON_INSTANCE_ID",
           {"stat":"Average","period":300,"color":"#2196F3","label":"CPU %"}]
        ],
        "view": "timeSeries",
        "annotations": {
          "horizontal": [{"value":70,"color":"#f44336","label":"Alarm threshold (70%)"}]
        },
        "period": 300,
        "yAxis": {"left":{"min":0,"max":100}},
        "region": "us-east-1",
        "legend": {"position":"bottom"}
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 0, "width": 12, "height": 6,
      "properties": {
        "title": "EC2 Network Traffic",
        "metrics": [
          ["AWS/EC2","NetworkIn","InstanceId","$MON_INSTANCE_ID",
           {"stat":"Average","period":300,"color":"#4CAF50","label":"Network In (bytes)"}],
          ["AWS/EC2","NetworkOut","InstanceId","$MON_INSTANCE_ID",
           {"stat":"Average","period":300,"color":"#FF9800","label":"Network Out (bytes)"}]
        ],
        "view": "timeSeries",
        "region": "us-east-1",
        "legend": {"position":"bottom"}
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 6, "width": 12, "height": 6,
      "properties": {
        "title": "RDS CPU Utilization",
        "metrics": [
          ["AWS/RDS","CPUUtilization","DBInstanceIdentifier","myapp-database",
           {"stat":"Average","period":300,"color":"#9C27B0","label":"RDS CPU %"}]
        ],
        "view": "timeSeries",
        "annotations": {
          "horizontal": [{"value":80,"color":"#f44336","label":"Alarm threshold (80%)"}]
        },
        "region": "us-east-1"
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 6, "width": 6, "height": 6,
      "properties": {
        "title": "RDS Database Connections",
        "metrics": [
          ["AWS/RDS","DatabaseConnections","DBInstanceIdentifier","myapp-database",
           {"stat":"Average","period":300,"color":"#E91E63"}]
        ],
        "view": "singleValue",
        "region": "us-east-1"
      }
    },
    {
      "type": "metric",
      "x": 18, "y": 6, "width": 6, "height": 6,
      "properties": {
        "title": "Estimated AWS Charges (USD)",
        "metrics": [
          ["AWS/Billing","EstimatedCharges","Currency","USD",
           {"stat":"Maximum","period":86400,"color":"#FF5722"}]
        ],
        "view": "singleValue",
        "region": "us-east-1"
      }
    }
  ]
}
"@

# Save dashboard JSON
$DASHBOARD_BODY | Out-File -FilePath "dashboard.json" -Encoding utf8
Write-Host "Dashboard JSON saved to dashboard.json" -ForegroundColor Green

# ── UPLOAD DASHBOARD ──────────────────────────────────────────────────────────
Write-Host "Uploading dashboard to CloudWatch..." -ForegroundColor Yellow

aws cloudwatch put-dashboard `
  --dashboard-name "AWS-Bootcamp-Dashboard" `
  --dashboard-body file://dashboard.json

Write-Host "Dashboard created." -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying dashboard..." -ForegroundColor Yellow

aws cloudwatch list-dashboards `
  --query "DashboardEntries[?DashboardName=='AWS-Bootcamp-Dashboard'].{Name:DashboardName,Size:Size,Modified:LastModified}" `
  --output table

Write-Host ""
Write-Host "=== Dashboard Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Console path: CloudWatch -> Dashboards -> AWS-Bootcamp-Dashboard"
Write-Host ""
Write-Host "Widgets created:"
Write-Host "  1. EC2 CPU Utilization (line chart, 70% threshold line)"
Write-Host "  2. EC2 Network Traffic (NetworkIn + NetworkOut dual line)"
Write-Host "  3. RDS CPU Utilization (line chart, 80% threshold line)"
Write-Host "  4. RDS Database Connections (single value)"
Write-Host "  5. Estimated AWS Charges USD (single value)"
Write-Host ""
Write-Host "Next step: Run 08-create-log-group.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 8 — SETS UP CLOUDWATCH LOGS WITH 7-DAY RETENTION

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **CloudWatch** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 7 — Script 08: CloudWatch Log Group
# Creates log group with 7-day retention policy
# =============================================================================

echo -e "\e[36m=== Project 7 — CloudWatch Log Group ===\e[0m"
echo ""

LOG_GROUP="/aws/ec2/monitoring-test"

echo -e "\e[33m[1/3] Creating log group: $LOG_GROUP...\e[0m"

aws logs create-log-group \
  --log-group-name $LOG_GROUP

if ($LASTEXITCODE -eq 0) {
echo -e "\e[32mLog group created.\e[0m"
} else {
echo -e "\e[33mLog group may already exist — continuing.\e[0m"
}

# ── SET RETENTION ─────────────────────────────────────────────────────────────
echo -e "\e[33m[2/3] Setting 7-day retention policy...\e[0m"

aws logs put-retention-policy \
  --log-group-name $LOG_GROUP \
  --retention-in-days 7

echo -e "\e[32mRetention set to 7 days.\e[0m"

# ── CREATE LOG STREAM ─────────────────────────────────────────────────────────
echo -e "\e[33m[3/3] Creating log stream: app-server-1...\e[0m"

aws logs create-log-stream \
  --log-group-name $LOG_GROUP \
  --log-stream-name "app-server-1"

echo -e "\e[32mLog stream created.\e[0m"

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mVerifying log group...\e[0m"

aws logs describe-log-groups \
  --log-group-name-prefix "/aws/ec2" \
  --query "logGroups[*].{Name:logGroupName,Retention:retentionInDays,StoredBytes:storedBytes}" \
  --output table

echo ""
echo -e "\e[36m=== Log Group Complete ===\e[0m"
echo ""
echo "  Log Group:   $LOG_GROUP"
echo "  Log Stream:  app-server-1"
echo "  Retention:   7 days"
echo ""
echo -e "\e[36mNext step: Run 09-create-metric-filter.ps1\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 7 — Script 08: CloudWatch Log Group
# Creates log group with 7-day retention policy
# =============================================================================

Write-Host "=== Project 7 — CloudWatch Log Group ===" -ForegroundColor Cyan
Write-Host ""

$LOG_GROUP = "/aws/ec2/monitoring-test"

Write-Host "[1/3] Creating log group: $LOG_GROUP..." -ForegroundColor Yellow

aws logs create-log-group `
  --log-group-name $LOG_GROUP

if ($LASTEXITCODE -eq 0) {
    Write-Host "Log group created." -ForegroundColor Green
} else {
    Write-Host "Log group may already exist — continuing." -ForegroundColor Yellow
}

# ── SET RETENTION ─────────────────────────────────────────────────────────────
Write-Host "[2/3] Setting 7-day retention policy..." -ForegroundColor Yellow

aws logs put-retention-policy `
  --log-group-name $LOG_GROUP `
  --retention-in-days 7

Write-Host "Retention set to 7 days." -ForegroundColor Green

# ── CREATE LOG STREAM ─────────────────────────────────────────────────────────
Write-Host "[3/3] Creating log stream: app-server-1..." -ForegroundColor Yellow

aws logs create-log-stream `
  --log-group-name $LOG_GROUP `
  --log-stream-name "app-server-1"

Write-Host "Log stream created." -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying log group..." -ForegroundColor Yellow

aws logs describe-log-groups `
  --log-group-name-prefix "/aws/ec2" `
  --query "logGroups[*].{Name:logGroupName,Retention:retentionInDays,StoredBytes:storedBytes}" `
  --output table

Write-Host ""
Write-Host "=== Log Group Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Log Group:   $LOG_GROUP"
Write-Host "  Log Stream:  app-server-1"
Write-Host "  Retention:   7 days"
Write-Host ""
Write-Host "Next step: Run 09-create-metric-filter.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 9 — CREATES FILTER AND ALARM FOR APPLICATION ERRORS

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **CloudWatch** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 7 — Script 09: Metric Filter + Custom Alarm
# Creates a metric filter that counts ERROR log lines, then alarms on it
# =============================================================================

echo -e "\e[36m=== Project 7 — Metric Filter and Custom Alarm ===\e[0m"
echo ""

if (-not $SNS_ARN) {
echo -e "\e[31mERROR: SNS_ARN not set. Run 01-sns-setup.ps1 first.\e[0m"
    exit 1
}

LOG_GROUP="/aws/ec2/monitoring-test"

# ── CREATE METRIC FILTER ──────────────────────────────────────────────────────
echo -e "\e[33m[1/2] Creating metric filter 'ErrorCount'...\e[0m"
echo "  Pattern:          ERROR (case-sensitive)"
echo "  Metric namespace: CustomMetrics"
echo "  Metric name:      ApplicationErrors"
echo "  On match:         increment by 1"
echo "  Default value:    0 (prevents INSUFFICIENT_DATA gaps)"
echo ""

aws logs put-metric-filter \
  --log-group-name $LOG_GROUP \
  --filter-name "ErrorCount" \
  --filter-pattern "ERROR" \
  --metric-transformations \
    metricName=ApplicationErrors,metricNamespace=CustomMetrics,metricValue=1,defaultValue=0

echo -e "\e[32mMetric filter created.\e[0m"

# ── CREATE ALARM ON CUSTOM METRIC ─────────────────────────────────────────────
echo ""
echo -e "\e[33m[2/2] Creating App-Errors-High alarm on CustomMetrics/ApplicationErrors...\e[0m"

aws cloudwatch put-metric-alarm \
  --alarm-name "App-Errors-High" \
  --alarm-description "Application error rate exceeded 5 errors in a 5-minute window" \
  --namespace "CustomMetrics" \
  --metric-name "ApplicationErrors" \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions $SNS_ARN \
  --treat-missing-data notBreaching

echo -e "\e[32mApp-Errors-High alarm created.\e[0m"

# ── VERIFY FILTER ─────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mVerifying metric filter...\e[0m"

aws logs describe-metric-filters \
  --log-group-name $LOG_GROUP \
  --query "metricFilters[*].{Name:filterName,Pattern:filterPattern,Metric:metricTransformations[0].metricName}" \
  --output table

echo ""
echo -e "\e[36m=== Metric Filter and Alarm Complete ===\e[0m"
echo ""
echo "Pipeline:"
echo "  Log Group (/aws/ec2/monitoring-test)"
echo "    -> Metric Filter (ErrorCount, pattern: 'ERROR')"
echo "    -> Custom Metric (CustomMetrics/ApplicationErrors)"
echo "    -> Alarm (App-Errors-High, threshold: Sum > 5 per 5min)"
echo "    -> SNS -> Email"
echo ""
echo -e "\e[36mNext step: Run 10-test-log-events.ps1 to push test ERROR log lines\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 7 — Script 09: Metric Filter + Custom Alarm
# Creates a metric filter that counts ERROR log lines, then alarms on it
# =============================================================================

Write-Host "=== Project 7 — Metric Filter and Custom Alarm ===" -ForegroundColor Cyan
Write-Host ""

if (-not $SNS_ARN) {
    Write-Host "ERROR: SNS_ARN not set. Run 01-sns-setup.ps1 first." -ForegroundColor Red
    exit 1
}

$LOG_GROUP = "/aws/ec2/monitoring-test"

# ── CREATE METRIC FILTER ──────────────────────────────────────────────────────
Write-Host "[1/2] Creating metric filter 'ErrorCount'..." -ForegroundColor Yellow
Write-Host "  Pattern:          ERROR (case-sensitive)"
Write-Host "  Metric namespace: CustomMetrics"
Write-Host "  Metric name:      ApplicationErrors"
Write-Host "  On match:         increment by 1"
Write-Host "  Default value:    0 (prevents INSUFFICIENT_DATA gaps)"
Write-Host ""

aws logs put-metric-filter `
  --log-group-name $LOG_GROUP `
  --filter-name "ErrorCount" `
  --filter-pattern "ERROR" `
  --metric-transformations `
    metricName=ApplicationErrors,metricNamespace=CustomMetrics,metricValue=1,defaultValue=0

Write-Host "Metric filter created." -ForegroundColor Green

# ── CREATE ALARM ON CUSTOM METRIC ─────────────────────────────────────────────
Write-Host ""
Write-Host "[2/2] Creating App-Errors-High alarm on CustomMetrics/ApplicationErrors..." -ForegroundColor Yellow

aws cloudwatch put-metric-alarm `
  --alarm-name "App-Errors-High" `
  --alarm-description "Application error rate exceeded 5 errors in a 5-minute window" `
  --namespace "CustomMetrics" `
  --metric-name "ApplicationErrors" `
  --statistic Sum `
  --period 300 `
  --evaluation-periods 1 `
  --threshold 5 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data notBreaching

Write-Host "App-Errors-High alarm created." -ForegroundColor Green

# ── VERIFY FILTER ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying metric filter..." -ForegroundColor Yellow

aws logs describe-metric-filters `
  --log-group-name $LOG_GROUP `
  --query "metricFilters[*].{Name:filterName,Pattern:filterPattern,Metric:metricTransformations[0].metricName}" `
  --output table

Write-Host ""
Write-Host "=== Metric Filter and Alarm Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pipeline:"
Write-Host "  Log Group (/aws/ec2/monitoring-test)"
Write-Host "    -> Metric Filter (ErrorCount, pattern: 'ERROR')"
Write-Host "    -> Custom Metric (CustomMetrics/ApplicationErrors)"
Write-Host "    -> Alarm (App-Errors-High, threshold: Sum > 5 per 5min)"
Write-Host "    -> SNS -> Email"
Write-Host ""
Write-Host "Next step: Run 10-test-log-events.ps1 to push test ERROR log lines" -ForegroundColor Cyan
```

---

## 🏗️ PART 10 — INGESTS MOCK LOGS TO TRIGGER ERROR ALARM

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **CloudWatch** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 7 — Script 10: Push Test Log Events
# Simulates application logs with INFO and ERROR lines to trigger metric filter
# =============================================================================

echo -e "\e[36m=== Project 7 — Push Test Log Events ===\e[0m"
echo ""
echo "Pushing 8 log events (3 INFO + 5 ERROR) to simulate an error spike."
echo "The metric filter will count the 5 ERROR lines."
echo "App-Errors-High alarm threshold is > 5, so this tests near-threshold."
echo ""
echo "To guarantee the alarm fires: add more ERROR lines or lower threshold to >= 5."
echo ""

LOG_GROUP="/aws/ec2/monitoring-test"
LOG_STREAM="app-server-1"

# Timestamps in milliseconds — each event 1 second apart
BASE_TIME=[int64](Get-Date -UFormat %s) * 1000

# ── PUSH LOG EVENTS ───────────────────────────────────────────────────────────
echo -e "\e[33mPushing log events to: $LOG_GROUP / $LOG_STREAM\e[0m"
echo ""

aws logs put-log-events \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LOG_STREAM \
    --log-events \
    "timestamp=$($BASE_TIME),message=\"INFO: Application started successfully\"" \
    "timestamp=$($BASE_TIME+1000),message=\"INFO: User login successful - user_id=1042\"" \
    "timestamp=$($BASE_TIME+2000),message=\"ERROR: Database connection timeout after 30s - host=rds-endpoint\"" \
    "timestamp=$($BASE_TIME+3000),message=\"ERROR: Failed to process payment - transaction_id=TXN9981\"" \
    "timestamp=$($BASE_TIME+4000),message=\"ERROR: Null pointer exception in OrderService.processOrder()\"" \
    "timestamp=$($BASE_TIME+5000),message=\"ERROR: Authentication service unavailable - retrying\"" \
    "timestamp=$($BASE_TIME+6000),message=\"ERROR: Rate limit exceeded - IP=203.0.113.45\"" \
    "timestamp=$($BASE_TIME+7000),message=\"INFO: Retry attempt 1 of 3 - backoff 2s\""

echo -e "\e[32mLog events pushed successfully.\e[0m"
echo ""
echo "Events sent:"
echo "  INFO:  Application started successfully"
echo "  INFO:  User login successful"
echo "  ERROR: Database connection timeout"
echo "  ERROR: Failed to process payment"
echo "  ERROR: Null pointer exception"
echo "  ERROR: Authentication service unavailable"
echo "  ERROR: Rate limit exceeded"
echo "  INFO:  Retry attempt 1 of 3"
echo ""
echo -e "\e[33mMetric filter will count: 5 ERROR events\e[0m"
echo ""

# Push 2 more ERROR events to guarantee alarm fires (total = 7 > threshold of 5)
echo -e "\e[33mPushing 2 additional ERROR events to guarantee alarm threshold breach (7 > 5)...\e[0m"

BASE_TIME2=$BASE_TIME + 10000

aws logs put-log-events \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LOG_STREAM \
    --log-events \
    "timestamp=$($BASE_TIME2),message=\"ERROR: Memory allocation failed - heap exhausted\"" \
    "timestamp=$($BASE_TIME2+1000),message=\"ERROR: Disk I/O error on /var/app/data\""

echo -e "\e[32mAdditional ERROR events pushed. Total: 7 ERROR events\e[0m"
echo ""
echo -e "\e[36m=== Log Events Complete ===\e[0m"
echo ""
echo "Wait 5 minutes for the App-Errors-High alarm to evaluate."
echo "Check alarm state:"
echo "  aws cloudwatch describe-alarms --alarm-names App-Errors-High --query "
echo ""
echo "Console path: CloudWatch -> Alarms -> App-Errors-High"
echo ""
echo -e "\e[36mNext step: Run 11-verify-alarms.ps1\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 7 — Script 10: Push Test Log Events
# Simulates application logs with INFO and ERROR lines to trigger metric filter
# =============================================================================

Write-Host "=== Project 7 — Push Test Log Events ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pushing 8 log events (3 INFO + 5 ERROR) to simulate an error spike."
Write-Host "The metric filter will count the 5 ERROR lines."
Write-Host "App-Errors-High alarm threshold is > 5, so this tests near-threshold."
Write-Host ""
Write-Host "To guarantee the alarm fires: add more ERROR lines or lower threshold to >= 5."
Write-Host ""

$LOG_GROUP = "/aws/ec2/monitoring-test"
$LOG_STREAM = "app-server-1"

# Timestamps in milliseconds — each event 1 second apart
$BASE_TIME = [int64](Get-Date -UFormat %s) * 1000

# ── PUSH LOG EVENTS ───────────────────────────────────────────────────────────
Write-Host "Pushing log events to: $LOG_GROUP / $LOG_STREAM" -ForegroundColor Yellow
Write-Host ""

aws logs put-log-events `
    --log-group-name $LOG_GROUP `
    --log-stream-name $LOG_STREAM `
    --log-events `
    "timestamp=$($BASE_TIME),message=`"INFO: Application started successfully`"" `
    "timestamp=$($BASE_TIME+1000),message=`"INFO: User login successful - user_id=1042`"" `
    "timestamp=$($BASE_TIME+2000),message=`"ERROR: Database connection timeout after 30s - host=rds-endpoint`"" `
    "timestamp=$($BASE_TIME+3000),message=`"ERROR: Failed to process payment - transaction_id=TXN9981`"" `
    "timestamp=$($BASE_TIME+4000),message=`"ERROR: Null pointer exception in OrderService.processOrder()`"" `
    "timestamp=$($BASE_TIME+5000),message=`"ERROR: Authentication service unavailable - retrying`"" `
    "timestamp=$($BASE_TIME+6000),message=`"ERROR: Rate limit exceeded - IP=203.0.113.45`"" `
    "timestamp=$($BASE_TIME+7000),message=`"INFO: Retry attempt 1 of 3 - backoff 2s`""

Write-Host "Log events pushed successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Events sent:"
Write-Host "  INFO:  Application started successfully"
Write-Host "  INFO:  User login successful"
Write-Host "  ERROR: Database connection timeout"
Write-Host "  ERROR: Failed to process payment"
Write-Host "  ERROR: Null pointer exception"
Write-Host "  ERROR: Authentication service unavailable"
Write-Host "  ERROR: Rate limit exceeded"
Write-Host "  INFO:  Retry attempt 1 of 3"
Write-Host ""
Write-Host "Metric filter will count: 5 ERROR events" -ForegroundColor Yellow
Write-Host ""

# Push 2 more ERROR events to guarantee alarm fires (total = 7 > threshold of 5)
Write-Host "Pushing 2 additional ERROR events to guarantee alarm threshold breach (7 > 5)..." -ForegroundColor Yellow

$BASE_TIME2 = $BASE_TIME + 10000

aws logs put-log-events `
    --log-group-name $LOG_GROUP `
    --log-stream-name $LOG_STREAM `
    --log-events `
    "timestamp=$($BASE_TIME2),message=`"ERROR: Memory allocation failed - heap exhausted`"" `
    "timestamp=$($BASE_TIME2+1000),message=`"ERROR: Disk I/O error on /var/app/data`""

Write-Host "Additional ERROR events pushed. Total: 7 ERROR events" -ForegroundColor Green
Write-Host ""
Write-Host "=== Log Events Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Wait 5 minutes for the App-Errors-High alarm to evaluate."
Write-Host "Check alarm state:"
Write-Host "  aws cloudwatch describe-alarms --alarm-names App-Errors-High --query ""MetricAlarms[0].StateValue"" --output text"
Write-Host ""
Write-Host "Console path: CloudWatch -> Alarms -> App-Errors-High"
Write-Host ""
Write-Host "Next step: Run 11-verify-alarms.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 11 — QUERIES AND VALIDATES ALL ALARM STATES

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **CloudWatch** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 7 — Script 11: Verify All Alarms and Metrics
# Lists all alarms, queries metric data, and checks alarm history
# =============================================================================

echo -e "\e[36m=== Project 7 — Alarm Verification ===\e[0m"
echo ""

START_TIME=(Get-Date).AddHours(-2).ToString("yyyy-MM-ddTHH:mm:ssZ")
END_TIME=(Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

# ── ALL ALARMS OVERVIEW ───────────────────────────────────────────────────────
echo -e "\e[33m--- All Alarms (current state) ---\e[0m"
aws cloudwatch describe-alarms \
  --query "MetricAlarms[*].{Name:AlarmName,State:StateValue,Metric:MetricName,Threshold:Threshold,Namespace:Namespace}" \
  --output table

# ── ALARM COUNTS BY STATE ─────────────────────────────────────────────────────
echo ""
echo -e "\e[33m--- Alarm State Summary ---\e[0m"
ALARMS=$(aws cloudwatch describe-alarms \
  --query "MetricAlarms[*].StateValue" --output text)

OK_COUNT=$(ALARMS  | Where-Object {$_ -eq "OK"}).Count
ALARM_COUNT=$(ALARMS  | Where-Object {$_ -eq "ALARM"}).Count
INSUFF=$(ALARMS  | Where-Object {$_ -eq "INSUFFICIENT_DATA"}).Count

echo "  OK:                 $OK_COUNT"
echo "  ALARM:              $ALARM_COUNT"
echo "  INSUFFICIENT_DATA:  $INSUFF"

# ── EC2 CPU METRIC DATA ───────────────────────────────────────────────────────
if ($MON_INSTANCE_ID) {
echo ""
echo -e "\e[33m--- EC2 CPU Utilization (last 2 hours) ---\e[0m"
    aws cloudwatch get-metric-statistics \
      --namespace AWS/EC2 \
      --metric-name CPUUtilization \
      --dimensions Name=InstanceId,Value=$MON_INSTANCE_ID \
      --start-time $START_TIME \
      --end-time $END_TIME \
      --period 300 \
      --statistics Average Maximum \
      --query "sort_by(Datapoints,&Timestamp)[*].{Time:Timestamp,Avg:Average,Max:Maximum}" \
      --output table
}

# ── EC2-CPU-HIGH ALARM HISTORY ────────────────────────────────────────────────
echo ""
echo -e "\e[33m--- EC2-CPU-High Alarm History ---\e[0m"
aws cloudwatch describe-alarm-history \
  --alarm-name "EC2-CPU-High" \
  --query "AlarmHistoryItems[*].{Time:Timestamp,Type:HistoryItemType,Summary:HistorySummary}" \
  --output table

# ── APP-ERRORS-HIGH ALARM HISTORY ────────────────────────────────────────────
echo ""
echo -e "\e[33m--- App-Errors-High Alarm History ---\e[0m"
aws cloudwatch describe-alarm-history \
  --alarm-name "App-Errors-High" \
  --query "AlarmHistoryItems[*].{Time:Timestamp,Type:HistoryItemType,Summary:HistorySummary}" \
  --output table

# ── CUSTOM METRIC DATA ────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m--- ApplicationErrors Custom Metric (last 2 hours) ---\e[0m"
aws cloudwatch get-metric-statistics \
  --namespace CustomMetrics \
  --metric-name ApplicationErrors \
  --start-time $START_TIME \
  --end-time $END_TIME \
  --period 300 \
  --statistics Sum \
  --query "sort_by(Datapoints,&Timestamp)[*].{Time:Timestamp,Errors:Sum}" \
  --output table

# ── SNS TOPIC STATUS ──────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m--- SNS Subscription Status ---\e[0m"
if ($SNS_ARN) {
    aws sns list-subscriptions-by-topic \
      --topic-arn $SNS_ARN \
      --query "Subscriptions[*].{Protocol:Protocol,Endpoint:Endpoint,Status:SubscriptionArn}" \
      --output table
} else {
echo "SNS_ARN not set — skipping."
}

# ── DASHBOARD STATUS ──────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m--- Dashboard Status ---\e[0m"
aws cloudwatch list-dashboards \
  --query "DashboardEntries[*].{Name:DashboardName,Modified:LastModified}" \
  --output table

echo ""
echo -e "\e[36m=== Verification Complete ===\e[0m"
echo ""
echo "Expected states after full project build:"
echo "  EC2-CPU-High             OK (or ALARM if stress test ran recently)"
echo "  EC2-StatusCheck-Failed   OK"
echo "  EC2-NetworkIn-High       OK"
echo "  RDS-CPU-High             INSUFFICIENT_DATA (no RDS)"
echo "  RDS-Storage-Low          INSUFFICIENT_DATA (no RDS)"
echo "  RDS-Connections-High     INSUFFICIENT_DATA (no RDS)"
echo "  Billing-Alert-5USD       OK"
echo "  App-Errors-High          ALARM (after test log events pushed)"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 7 — Script 11: Verify All Alarms and Metrics
# Lists all alarms, queries metric data, and checks alarm history
# =============================================================================

Write-Host "=== Project 7 — Alarm Verification ===" -ForegroundColor Cyan
Write-Host ""

$START_TIME = (Get-Date).AddHours(-2).ToString("yyyy-MM-ddTHH:mm:ssZ")
$END_TIME   = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

# ── ALL ALARMS OVERVIEW ───────────────────────────────────────────────────────
Write-Host "--- All Alarms (current state) ---" -ForegroundColor Yellow
aws cloudwatch describe-alarms `
  --query "MetricAlarms[*].{Name:AlarmName,State:StateValue,Metric:MetricName,Threshold:Threshold,Namespace:Namespace}" `
  --output table

# ── ALARM COUNTS BY STATE ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Alarm State Summary ---" -ForegroundColor Yellow
$ALARMS = aws cloudwatch describe-alarms `
  --query "MetricAlarms[*].StateValue" --output text

$OK_COUNT    = ($ALARMS -split '\s+' | Where-Object {$_ -eq "OK"}).Count
$ALARM_COUNT = ($ALARMS -split '\s+' | Where-Object {$_ -eq "ALARM"}).Count
$INSUFF      = ($ALARMS -split '\s+' | Where-Object {$_ -eq "INSUFFICIENT_DATA"}).Count

Write-Host "  OK:                 $OK_COUNT"
Write-Host "  ALARM:              $ALARM_COUNT"
Write-Host "  INSUFFICIENT_DATA:  $INSUFF"

# ── EC2 CPU METRIC DATA ───────────────────────────────────────────────────────
if ($MON_INSTANCE_ID) {
    Write-Host ""
    Write-Host "--- EC2 CPU Utilization (last 2 hours) ---" -ForegroundColor Yellow
    aws cloudwatch get-metric-statistics `
      --namespace AWS/EC2 `
      --metric-name CPUUtilization `
      --dimensions Name=InstanceId,Value=$MON_INSTANCE_ID `
      --start-time $START_TIME `
      --end-time $END_TIME `
      --period 300 `
      --statistics Average Maximum `
      --query "sort_by(Datapoints,&Timestamp)[*].{Time:Timestamp,Avg:Average,Max:Maximum}" `
      --output table
}

# ── EC2-CPU-HIGH ALARM HISTORY ────────────────────────────────────────────────
Write-Host ""
Write-Host "--- EC2-CPU-High Alarm History ---" -ForegroundColor Yellow
aws cloudwatch describe-alarm-history `
  --alarm-name "EC2-CPU-High" `
  --query "AlarmHistoryItems[*].{Time:Timestamp,Type:HistoryItemType,Summary:HistorySummary}" `
  --output table

# ── APP-ERRORS-HIGH ALARM HISTORY ────────────────────────────────────────────
Write-Host ""
Write-Host "--- App-Errors-High Alarm History ---" -ForegroundColor Yellow
aws cloudwatch describe-alarm-history `
  --alarm-name "App-Errors-High" `
  --query "AlarmHistoryItems[*].{Time:Timestamp,Type:HistoryItemType,Summary:HistorySummary}" `
  --output table

# ── CUSTOM METRIC DATA ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- ApplicationErrors Custom Metric (last 2 hours) ---" -ForegroundColor Yellow
aws cloudwatch get-metric-statistics `
  --namespace CustomMetrics `
  --metric-name ApplicationErrors `
  --start-time $START_TIME `
  --end-time $END_TIME `
  --period 300 `
  --statistics Sum `
  --query "sort_by(Datapoints,&Timestamp)[*].{Time:Timestamp,Errors:Sum}" `
  --output table

# ── SNS TOPIC STATUS ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- SNS Subscription Status ---" -ForegroundColor Yellow
if ($SNS_ARN) {
    aws sns list-subscriptions-by-topic `
      --topic-arn $SNS_ARN `
      --query "Subscriptions[*].{Protocol:Protocol,Endpoint:Endpoint,Status:SubscriptionArn}" `
      --output table
} else {
    Write-Host "SNS_ARN not set — skipping."
}

# ── DASHBOARD STATUS ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Dashboard Status ---" -ForegroundColor Yellow
aws cloudwatch list-dashboards `
  --query "DashboardEntries[*].{Name:DashboardName,Modified:LastModified}" `
  --output table

Write-Host ""
Write-Host "=== Verification Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Expected states after full project build:"
Write-Host "  EC2-CPU-High             OK (or ALARM if stress test ran recently)"
Write-Host "  EC2-StatusCheck-Failed   OK"
Write-Host "  EC2-NetworkIn-High       OK"
Write-Host "  RDS-CPU-High             INSUFFICIENT_DATA (no RDS)"
Write-Host "  RDS-Storage-Low          INSUFFICIENT_DATA (no RDS)"
Write-Host "  RDS-Connections-High     INSUFFICIENT_DATA (no RDS)"
Write-Host "  Billing-Alert-5USD       OK"
Write-Host "  App-Errors-High          ALARM (after test log events pushed)"
```

---

## 🧹 TEARDOWN
To prevent recurring AWS charges, proceed to the `docs/cleanup-guide.md` to run the tear-down scripts.
