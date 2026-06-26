# =============================================================================
# Project 9 — Script 04: Launch EC2 Deployment Target
# Launches t2.micro with CodeDeploy agent and Apache pre-installed
# Region: ap-south-1 — tagged Environment=production for CodeDeploy targeting
# =============================================================================

Write-Host "=== Project 9 — Launch EC2 Deployment Target ===" -ForegroundColor Cyan
Write-Host ""

# ── FIND AMI ──────────────────────────────────────────────────────────────────
Write-Host "[1/5] Finding latest Amazon Linux 2023 AMI in ap-south-1..." -ForegroundColor Yellow
$AMI_ID = aws ec2 describe-images `
    --owners amazon `
    --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" `
    --region ap-south-1 `
    --query "sort_by(Images,&CreationDate)[-1].ImageId" `
    --output text
Write-Host "AMI: $AMI_ID"

# ── DEFAULT VPC + SUBNET ──────────────────────────────────────────────────────
Write-Host "[2/5] Getting default VPC and subnet..." -ForegroundColor Yellow
$VPC_ID = aws ec2 describe-vpcs `
    --filters "Name=isDefault,Values=true" `
    --region ap-south-1 `
    --query "Vpcs[0].VpcId" --output text

$SUBNET_ID = aws ec2 describe-subnets `
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=defaultForAz,Values=true" `
    --region ap-south-1 `
    --query "Subnets[0].SubnetId" --output text

Write-Host "VPC: $VPC_ID  Subnet: $SUBNET_ID"

# ── SECURITY GROUP ────────────────────────────────────────────────────────────
Write-Host "[3/5] Creating security group..." -ForegroundColor Yellow
$MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" -UseBasicParsing).Content.Trim()

$DEPLOY_SG = aws ec2 create-security-group `
    --group-name cicd-deploy-sg `
    --description "CI/CD deployment target security group" `
    --vpc-id $VPC_ID `
    --region ap-south-1 `
    --query "GroupId" --output text

aws ec2 authorize-security-group-ingress --group-id $DEPLOY_SG `
    --protocol tcp --port 22 --cidr "$MY_IP/32" --region ap-south-1
aws ec2 authorize-security-group-ingress --group-id $DEPLOY_SG `
    --protocol tcp --port 80 --cidr "0.0.0.0/0" --region ap-south-1

Write-Host "Security group: $DEPLOY_SG"

# ── USER DATA ─────────────────────────────────────────────────────────────────
Write-Host "[4/5] Preparing user data script..." -ForegroundColor Yellow
$USER_DATA = @"
#!/bin/bash
yum update -y
yum install -y ruby wget httpd

# Install CodeDeploy agent for ap-south-1
cd /home/ec2-user
wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x ./install
./install auto

# Start services
systemctl start codedeploy-agent
systemctl enable codedeploy-agent
systemctl start httpd
systemctl enable httpd

# Placeholder page
echo '<html><body style="font-family:Arial;text-align:center;padding:60px;background:#f0f2f5">
<h1 style="color:#232f3e">Waiting for CI/CD deployment...</h1>
<p>CodeDeploy agent installed and ready</p>
<p style="color:#888">Region: ap-south-1</p>
</body></html>' > /var/www/html/index.html

echo "EC2 setup complete" > /tmp/setup-done.txt
"@

$USER_DATA | Out-File -FilePath "userdata-deploy.sh" -Encoding ascii

# ── LAUNCH INSTANCE ───────────────────────────────────────────────────────────
Write-Host "[5/5] Launching EC2 instance..." -ForegroundColor Yellow

$DEPLOY_INSTANCE_ID = aws ec2 run-instances `
    --image-id $AMI_ID `
    --instance-type t2.micro `
    --key-name aws-ec2-keypair `
    --subnet-id $SUBNET_ID `
    --security-group-ids $DEPLOY_SG `
    --iam-instance-profile Name=ec2-codedeploy-profile `
    --associate-public-ip-address `
    --user-data file://userdata-deploy.sh `
    --region ap-south-1 `
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=cicd-deploy-server},{Key=Environment,Value=production}]" `
    --query "Instances[0].InstanceId" --output text

Write-Host "Instance ID: $DEPLOY_INSTANCE_ID" -ForegroundColor Green
Write-Host "Waiting for status checks (3-4 minutes for CodeDeploy agent install)..." -ForegroundColor Yellow

aws ec2 wait instance-status-ok --instance-ids $DEPLOY_INSTANCE_ID --region ap-south-1
Write-Host "EC2 ready." -ForegroundColor Green

$DEPLOY_PUBLIC_IP = aws ec2 describe-instances `
    --instance-ids $DEPLOY_INSTANCE_ID `
    --region ap-south-1 `
    --query "Reservations[0].Instances[0].PublicIpAddress" --output text

Write-Host ""
Write-Host "=== EC2 Launch Complete ===" -ForegroundColor Cyan
Write-Host "  DEPLOY_INSTANCE_ID = $DEPLOY_INSTANCE_ID"
Write-Host "  DEPLOY_PUBLIC_IP   = $DEPLOY_PUBLIC_IP"
Write-Host "  App URL:             http://$DEPLOY_PUBLIC_IP"
Write-Host ""
Write-Host "IMPORTANT: Tag Environment=production is set — CodeDeploy uses this to find instances"
Write-Host ""
Write-Host "Next step: Run 05-create-codedeploy.ps1" -ForegroundColor Cyan