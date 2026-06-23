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