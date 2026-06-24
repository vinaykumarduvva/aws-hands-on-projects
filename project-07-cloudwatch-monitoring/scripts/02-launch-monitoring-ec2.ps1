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