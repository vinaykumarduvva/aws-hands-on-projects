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
