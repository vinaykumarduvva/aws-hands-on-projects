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
