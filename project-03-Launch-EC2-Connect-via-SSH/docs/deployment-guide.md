# Comprehensive Deployment Guide

This guide details the complete process for deploying this project's resources.

## 🏗️ PART 1 — GENERATES THE SSH KEY PAIR

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **AWS Console** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# Create the keys folder
mkdir -p ~/aws-keys

# Create key pair and save private key
aws ec2 create-key-pair \
  --key-name aws-ec2-keypair \
  --key-type RSA \
  --key-format ppk \
  --query "KeyMaterial" \
  --output text > ~/aws-keys/aws-ec2-keypair.ppk

# Verify it was created in AWS
aws ec2 describe-key-pairs --key-names aws-ec2-keypair \
  --query "KeyPairs[*].{Name:KeyName,ID:KeyPairId}" \
  --output table

echo -e "\e[32mCreated key pair: aws-ec2-keypair\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Create the keys folder
mkdir C:\Users\$env:USERNAME\aws-keys -ErrorAction SilentlyContinue

# Create key pair and save private key
aws ec2 create-key-pair `
  --key-name aws-ec2-keypair `
  --key-type RSA `
  --key-format ppk `
  --query "KeyMaterial" `
  --output text | Out-File `
  -FilePath "C:\Users\$env:USERNAME\aws-keys\aws-ec2-keypair.ppk" `
  -Encoding ascii

# Verify it was created in AWS
aws ec2 describe-key-pairs --key-names aws-ec2-keypair `
  --query "KeyPairs[*].{Name:KeyName,ID:KeyPairId}" `
  --output table
```

---

## 🏗️ PART 2 — CONFIGURES THE FIREWALL RULES (SSH/HTTP)

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **AWS Console** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# Get your default VPC ID
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" \
  --output text)

echo "Default VPC ID: $VPC_ID"

# Get your current public IP address
MY_IP=$(curl -s https://checkip.amazonaws.com)

echo "Your public IP: $MY_IP"

# Create the security group
SG_ID=$(aws ec2 create-security-group \
  --group-name ec2-web-sg \
  --description "Allow SSH and HTTP access" \
  --vpc-id $VPC_ID \
  --query "GroupId" \
  --output text)

echo "Security Group ID: $SG_ID"

# Add SSH rule — only your IP
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr "$MY_IP/32"

# Add HTTP rule — open to everyone
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr "0.0.0.0/0"

# Verify both rules were added
aws ec2 describe-security-groups --group-ids $SG_ID \
  --query "SecurityGroups[0].IpPermissions[*].{Port:FromPort,Protocol:IpProtocol,Source:IpRanges[0].CidrIp}" \
  --output table
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Get your default VPC ID
$VPC_ID = aws ec2 describe-vpcs `
  --filters "Name=isDefault,Values=true" `
  --query "Vpcs[0].VpcId" `
  --output text

Write-Host "Default VPC ID: $VPC_ID"

# Get your current public IP address
$MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" `
  -UseBasicParsing).Content.Trim()

Write-Host "Your public IP: $MY_IP"

# Create the security group
$SG_ID = aws ec2 create-security-group `
  --group-name ec2-web-sg `
  --description "Allow SSH and HTTP access" `
  --vpc-id $VPC_ID `
  --query "GroupId" `
  --output text

Write-Host "Security Group ID: $SG_ID"

# Add SSH rule — only your IP
aws ec2 authorize-security-group-ingress `
  --group-id $SG_ID `
  --protocol tcp `
  --port 22 `
  --cidr "$MY_IP/32"

# Add HTTP rule — open to everyone
aws ec2 authorize-security-group-ingress `
  --group-id $SG_ID `
  --protocol tcp `
  --port 80 `
  --cidr "0.0.0.0/0"

# Verify both rules were added
aws ec2 describe-security-groups --group-ids $SG_ID `
  --query "SecurityGroups[0].IpPermissions[*].{Port:FromPort,Protocol:IpProtocol,Source:IpRanges[0].CidrIp}" `
  --output table
```

---

## 🏗️ PART 3 — LAUNCHES THE EC2 INSTANCE

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **EC2** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# Get the latest Amazon Linux 2023 AMI ID for us-east-1
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters \
    "Name=name,Values=al2023-ami-*-x86_64" \
    "Name=state,Values=available" \
  --query "sort_by(Images,&CreationDate)[-1].ImageId" \
  --output text)

echo "AMI ID: $AMI_ID"

# Create a user-data script file
cat << 'EOF' > userdata.sh
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo '<html><body style="font-family:Arial;text-align:center;padding:60px">
<h1>EC2 Web Server Running</h1>
<p>Amazon Linux 2023 - Project 3</p>
</body></html>' > /var/www/html/index.html
EOF

# Get the security group ID (Assuming ec2-web-sg)
SG_ID=$(aws ec2 describe-security-groups --group-names ec2-web-sg --query "SecurityGroups[0].GroupId" --output text)

# Launch the instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --key-name aws-ec2-keypair \
  --security-group-ids $SG_ID \
  --associate-public-ip-address \
  --user-data file://userdata.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=my-first-ec2}]" \
  --query "Instances[0].InstanceId" \
  --output text)

echo "Instance ID: $INSTANCE_ID"

# Wait until the instance is running
echo "Waiting for instance to start..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo "Instance is running!"

# Get the public IP address
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo "Public IP: $PUBLIC_IP"

# Wait for status checks to pass (2/2)
echo "Waiting for status checks (takes 2-3 minutes)..."
aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID
echo "Instance passed all status checks - ready to connect!"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Get the latest Amazon Linux 2023 AMI ID for us-east-1
$AMI_ID = aws ec2 describe-images `
  --owners amazon `
  --filters `
    "Name=name,Values=al2023-ami-*-x86_64" `
    "Name=state,Values=available" `
  --query "sort_by(Images,&CreationDate)[-1].ImageId" `
  --output text

Write-Host "AMI ID: $AMI_ID"

# Create a user-data script file
$USER_DATA = @"
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo '<html><body style="font-family:Arial;text-align:center;padding:60px">
<h1>EC2 Web Server Running</h1>
<p>Amazon Linux 2023 - Project 3</p>
</body></html>' > /var/www/html/index.html
"@

$USER_DATA | Out-File -FilePath "userdata.sh" -Encoding ascii

# Get the security group ID (Assuming ec2-web-sg)
$SG_ID = aws ec2 describe-security-groups --group-names ec2-web-sg --query "SecurityGroups[0].GroupId" --output text

# Launch the instance
$INSTANCE_ID = aws ec2 run-instances `
  --image-id $AMI_ID `
  --instance-type t2.micro `
  --key-name aws-ec2-keypair `
  --security-group-ids $SG_ID `
  --associate-public-ip-address `
  --user-data file://userdata.sh `
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=my-first-ec2}]" `
  --query "Instances[0].InstanceId" `
  --output text

Write-Host "Instance ID: $INSTANCE_ID"

# Wait until the instance is running
Write-Host "Waiting for instance to start..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
Write-Host "Instance is running!"

# Get the public IP address
$PUBLIC_IP = aws ec2 describe-instances `
  --instance-ids $INSTANCE_ID `
  --query "Reservations[0].Instances[0].PublicIpAddress" `
  --output text

Write-Host "Public IP: $PUBLIC_IP"

# Wait for status checks to pass (2/2)
Write-Host "Waiting for status checks (takes 2-3 minutes)..."
aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID
Write-Host "Instance passed all status checks - ready to connect!"
```

---

## 🏗️ PART 4 — CONNECTS VIA SESSION MANAGER

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **AWS Console** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# Create the IAM role with EC2 trust policy
aws iam create-role \
  --role-name ec2-ssm-role \
  --assume-role-policy-document '{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Principal":{"Service":"ec2.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }]
  }'

# Attach the SSM managed policy
aws iam attach-role-policy \
  --role-name ec2-ssm-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Create instance profile and add role to it
aws iam create-instance-profile \
  --instance-profile-name ec2-ssm-profile

aws iam add-role-to-instance-profile \
  --instance-profile-name ec2-ssm-profile \
  --role-name ec2-ssm-role

# Get Instance ID (assuming one running instance for my-first-ec2)
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=my-first-ec2" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text)

# Attach the instance profile to your EC2 instance
aws ec2 associate-iam-instance-profile \
  --instance-id $INSTANCE_ID \
  --iam-instance-profile Name=ec2-ssm-profile

# Verify
aws ec2 describe-iam-instance-profile-associations \
  --query "IamInstanceProfileAssociations[*].{Instance:InstanceId,Profile:IamInstanceProfile.Arn,State:State}" \
  --output table

echo "Wait a few minutes, then connect via Session Manager (console) or CLI:"
echo "aws ssm start-session --target $INSTANCE_ID"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Create the IAM role with EC2 trust policy
aws iam create-role `
  --role-name ec2-ssm-role `
  --assume-role-policy-document '{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Principal":{"Service":"ec2.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }]
  }'

# Attach the SSM managed policy
aws iam attach-role-policy `
  --role-name ec2-ssm-role `
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Create instance profile and add role to it
aws iam create-instance-profile `
  --instance-profile-name ec2-ssm-profile

aws iam add-role-to-instance-profile `
  --instance-profile-name ec2-ssm-profile `
  --role-name ec2-ssm-role

# Get Instance ID (assuming one running instance for my-first-ec2)
$INSTANCE_ID = aws ec2 describe-instances --filters "Name=tag:Name,Values=my-first-ec2" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text

# Attach the instance profile to your EC2 instance
aws ec2 associate-iam-instance-profile `
  --instance-id $INSTANCE_ID `
  --iam-instance-profile Name=ec2-ssm-profile

# Verify
aws ec2 describe-iam-instance-profile-associations `
  --query "IamInstanceProfileAssociations[*].{Instance:InstanceId,Profile:IamInstanceProfile.Arn,State:State}" `
  --output table

Write-Host "Wait a few minutes, then connect via Session Manager (console) or CLI:"
Write-Host "aws ssm start-session --target $INSTANCE_ID"
```

---

## 🧹 TEARDOWN
To prevent recurring AWS charges, proceed to the `docs/cleanup-guide.md` to run the tear-down scripts.
