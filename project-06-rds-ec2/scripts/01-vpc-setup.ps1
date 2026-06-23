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