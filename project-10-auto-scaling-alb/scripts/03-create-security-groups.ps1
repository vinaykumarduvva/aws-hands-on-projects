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
