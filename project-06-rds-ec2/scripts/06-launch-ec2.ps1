# =============================================================================
# Project 6 — Script 06: Launch EC2 App Server + IAM Role
# Launches t2.micro in public subnet with MySQL client and Apache installed
# Also creates and attaches IAM role for Secrets Manager access
# =============================================================================

Write-Host "=== Project 6 — Launch EC2 App Server ===" -ForegroundColor Cyan
Write-Host ""

if (-not $EC2_SG -or -not $PUB_SUBNET_A) {
    Write-Host "ERROR: EC2_SG or PUB_SUBNET_A not set. Run earlier scripts first." -ForegroundColor Red
    exit 1
}

# ── FIND LATEST AMAZON LINUX 2023 AMI ─────────────────────────────────────────
Write-Host "[1/4] Finding latest Amazon Linux 2023 AMI..." -ForegroundColor Yellow

$AMI_ID = aws ec2 describe-images `
    --owners amazon `
    --filters "Name=name,Values=al2023-ami-*-x86_64" `
    "Name=state,Values=available" `
    --query "sort_by(Images,&CreationDate)[-1].ImageId" `
    --output text

Write-Host "AMI: $AMI_ID" -ForegroundColor Green

# ── USER DATA SCRIPT ──────────────────────────────────────────────────────────
Write-Host "[2/4] Preparing user data..." -ForegroundColor Yellow

$USER_DATA_CONTENT = @"
#!/bin/bash
yum update -y
yum install -y mysql httpd
systemctl start httpd
systemctl enable httpd

echo '<html>
<head><title>App Server - Project 6</title></head>
<body style="font-family:Arial,sans-serif;text-align:center;padding:60px;background:#f0f2f5">
  <h1 style="color:#232f3e">App Server Running</h1>
  <p style="color:#555;font-size:18px">EC2 + RDS Two-Tier Architecture — Project 6</p>
  <p style="color:#28a745;font-size:16px">MySQL client installed and ready to connect to RDS</p>
  <hr style="max-width:400px;margin:30px auto">
  <p style="color:#888;font-size:14px">Amazon Linux 2023 · t2.micro · public-subnet-a</p>
</body>
</html>' > /var/www/html/index.html
"@

$USER_DATA_CONTENT | Out-File -FilePath "userdata-app.sh" -Encoding ascii
Write-Host "User data script written to userdata-app.sh" -ForegroundColor Green

# ── LAUNCH EC2 INSTANCE ───────────────────────────────────────────────────────
Write-Host "[3/4] Launching EC2 instance..." -ForegroundColor Yellow

$APP_INSTANCE_ID = aws ec2 run-instances `
    --image-id $AMI_ID `
    --instance-type t2.micro `
    --key-name aws-ec2-keypair `
    --subnet-id $PUB_SUBNET_A `
    --security-group-ids $EC2_SG `
    --associate-public-ip-address `
    --user-data file://userdata-app.sh `
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=app-server}]" `
    --query "Instances[0].InstanceId" `
    --output text

Write-Host "Instance launched: $APP_INSTANCE_ID" -ForegroundColor Green
Write-Host "Waiting for instance to pass status checks (2-3 minutes)..." -ForegroundColor Yellow

aws ec2 wait instance-status-ok --instance-ids $APP_INSTANCE_ID
Write-Host "Instance ready." -ForegroundColor Green

$APP_PUBLIC_IP = aws ec2 describe-instances `
    --instance-ids $APP_INSTANCE_ID `
    --query "Reservations[0].Instances[0].PublicIpAddress" `
    --output text

Write-Host "Public IP: $APP_PUBLIC_IP" -ForegroundColor Green

# ── IAM ROLE FOR SECRETS MANAGER ─────────────────────────────────────────────
Write-Host "[4/4] Creating IAM role for Secrets Manager access..." -ForegroundColor Yellow

$ENHANCED_POLICY = '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:*:secret:rds/myapp/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:UpdateInstanceInformation",
        "ssmmessages:*",
        "ec2messages:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "rds:DescribeDBInstances",
        "rds:DescribeDBClusters"
      ],
      "Resource": "*"
    }
  ]
}'

# Create IAM role
aws iam create-role `
    --role-name ec2-app-role `
    --assume-role-policy-document '{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Principal":{"Service":"ec2.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }]
  }' | Out-Null

# Attach AWS managed SSM policy
aws iam attach-role-policy `
    --role-name ec2-app-role `
    --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Add scoped Secrets Manager policy
aws iam put-role-policy `
    --role-name ec2-app-role `
    --policy-name secrets-manager-access `
    --policy-document $ENHANCED_POLICY

# Create instance profile and attach role
aws iam create-instance-profile `
    --instance-profile-name ec2-app-profile | Out-Null

aws iam add-role-to-instance-profile `
    --instance-profile-name ec2-app-profile `
    --role-name ec2-app-role

# Wait briefly for IAM to propagate
Start-Sleep -Seconds 10

# Associate instance profile with EC2
aws ec2 associate-iam-instance-profile `
    --instance-id $APP_INSTANCE_ID `
    --iam-instance-profile Name=ec2-app-profile | Out-Null

Write-Host "IAM role created and attached." -ForegroundColor Green

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== EC2 App Server Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  APP_INSTANCE_ID = $APP_INSTANCE_ID"
Write-Host "  APP_PUBLIC_IP   = $APP_PUBLIC_IP"
Write-Host ""
Write-Host "Test the web server: http://$APP_PUBLIC_IP"
Write-Host ""
Write-Host "SSH command:"
Write-Host "  ssh -i aws-ec2-keypair.pem ec2-user@$APP_PUBLIC_IP"
Write-Host ""
Write-Host "Wait 2 minutes before testing Secrets Manager from EC2"
Write-Host "(IAM credentials need time to propagate to instance metadata)"
Write-Host ""
Write-Host "Next step: SSH into the instance, then use 07-rds-connect.sql" -ForegroundColor Cyan