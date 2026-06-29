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
