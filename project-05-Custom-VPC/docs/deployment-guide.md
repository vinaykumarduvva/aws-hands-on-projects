# Comprehensive Deployment Guide

This guide details the complete process for deploying this project's resources.

## 🏗️ PART 1 — PROVISIONS THE CUSTOM VPC AND 4 SUBNETS

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **VPC** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=my-custom-vpc}]" \
  --query "Vpc.VpcId" --output text)

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

PUB_SUBNET_A=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-a}]" \
  --query "Subnet.SubnetId" --output text)

PUB_SUBNET_B=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-b}]" \
  --query "Subnet.SubnetId" --output text)

PRI_SUBNET_A=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-a}]" \
  --query "Subnet.SubnetId" --output text)

PRI_SUBNET_B=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID --cidr-block 10.0.4.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-b}]" \
  --query "Subnet.SubnetId" --output text)

aws ec2 modify-subnet-attribute --subnet-id $PUB_SUBNET_A --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $PUB_SUBNET_B --map-public-ip-on-launch

echo -e "\e[32m\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
$VPC_ID = aws ec2 create-vpc `
  --cidr-block 10.0.0.0/16 `
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=my-custom-vpc}]" `
  --query "Vpc.VpcId" --output text

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

$PUB_SUBNET_A = aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 `
  --availability-zone us-east-1a `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-a}]" `
  --query "Subnet.SubnetId" --output text

$PUB_SUBNET_B = aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 `
  --availability-zone us-east-1b `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-b}]" `
  --query "Subnet.SubnetId" --output text

aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 `
  --availability-zone us-east-1a `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-a}]" `
  --query "Subnet.SubnetId" --output text

aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.4.0/24 `
  --availability-zone us-east-1b `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-b}]" `
  --query "Subnet.SubnetId" --output text

aws ec2 modify-subnet-attribute --subnet-id $PUB_SUBNET_A --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $PUB_SUBNET_B --map-public-ip-on-launch

Write-Host -ForegroundColor Green "VPC and Subnets created."
Write-Host "VPC ID: $VPC_ID"
Write-Host "Public Subnets: $PUB_SUBNET_A, $PUB_SUBNET_B"
```

---

## 🏗️ PART 2 — CREATES IGW, ROUTE TABLES, AND SUBNET ASSOCIATIONS

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **VPC** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=my-custom-vpc" --query "Vpcs[0].VpcId" --output text)
PUB_SUBNET_A=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-subnet-a" --query "Subnets[0].SubnetId" --output text)
PUB_SUBNET_B=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-subnet-b" --query "Subnets[0].SubnetId" --output text)
PRI_SUBNET_A=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-subnet-a" --query "Subnets[0].SubnetId" --output text)
PRI_SUBNET_B=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-subnet-b" --query "Subnets[0].SubnetId" --output text)

IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-vpc-igw}]" \
  --query "InternetGateway.InternetGatewayId" --output text)

aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

PUB_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=public-route-table}]" \
  --query "RouteTable.RouteTableId" --output text)

aws ec2 create-route \
  --route-table-id $PUB_RT_ID \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

aws ec2 associate-route-table --route-table-id $PUB_RT_ID --subnet-id $PUB_SUBNET_A
aws ec2 associate-route-table --route-table-id $PUB_RT_ID --subnet-id $PUB_SUBNET_B

PRI_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=private-route-table}]" \
  --query "RouteTable.RouteTableId" --output text)

aws ec2 associate-route-table --route-table-id $PRI_RT_ID --subnet-id $PRI_SUBNET_A
aws ec2 associate-route-table --route-table-id $PRI_RT_ID --subnet-id $PRI_SUBNET_B

echo -e "\e[32m\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
$VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Name,Values=my-custom-vpc" --query "Vpcs[0].VpcId" --output text
$PUB_SUBNET_A = aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-subnet-a" --query "Subnets[0].SubnetId" --output text
$PUB_SUBNET_B = aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-subnet-b" --query "Subnets[0].SubnetId" --output text
$PRI_SUBNET_A = aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-subnet-a" --query "Subnets[0].SubnetId" --output text
$PRI_SUBNET_B = aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-subnet-b" --query "Subnets[0].SubnetId" --output text

$IGW_ID = aws ec2 create-internet-gateway `
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-vpc-igw}]" `
  --query "InternetGateway.InternetGatewayId" --output text

aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

$PUB_RT_ID = aws ec2 create-route-table `
  --vpc-id $VPC_ID `
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=public-route-table}]" `
  --query "RouteTable.RouteTableId" --output text

aws ec2 create-route `
  --route-table-id $PUB_RT_ID `
  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

aws ec2 associate-route-table --route-table-id $PUB_RT_ID --subnet-id $PUB_SUBNET_A
aws ec2 associate-route-table --route-table-id $PUB_RT_ID --subnet-id $PUB_SUBNET_B

$PRI_RT_ID = aws ec2 create-route-table `
  --vpc-id $VPC_ID `
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=private-route-table}]" `
  --query "RouteTable.RouteTableId" --output text

aws ec2 associate-route-table --route-table-id $PRI_RT_ID --subnet-id $PRI_SUBNET_A
aws ec2 associate-route-table --route-table-id $PRI_RT_ID --subnet-id $PRI_SUBNET_B

Write-Host -ForegroundColor Green "Internet Gateway and Route Tables created."
```

---

## 🏗️ PART 3 — DEPLOYS NAT GATEWAY WITH ELASTIC IP

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **VPC** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

PUB_SUBNET_A=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-subnet-a" --query "Subnets[0].SubnetId" --output text)
PRI_RT_ID=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=private-route-table" --query "RouteTables[0].RouteTableId" --output text)

EIP_ALLOC=$(aws ec2 allocate-address \
  --domain vpc --query "AllocationId" --output text)

NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUB_SUBNET_A \
  --allocation-id $EIP_ALLOC \
  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=my-nat-gateway}]" \
  --query "NatGateway.NatGatewayId" --output text)

echo "Waiting for NAT Gateway to become available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

aws ec2 create-route \
  --route-table-id $PRI_RT_ID \
  --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID

echo -e "\e[32m\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
$PUB_SUBNET_A = aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-subnet-a" --query "Subnets[0].SubnetId" --output text
$PRI_RT_ID = aws ec2 describe-route-tables --filters "Name=tag:Name,Values=private-route-table" --query "RouteTables[0].RouteTableId" --output text

$EIP_ALLOC = aws ec2 allocate-address `
  --domain vpc --query "AllocationId" --output text

$NAT_GW_ID = aws ec2 create-nat-gateway `
  --subnet-id $PUB_SUBNET_A `
  --allocation-id $EIP_ALLOC `
  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=my-nat-gateway}]" `
  --query "NatGateway.NatGatewayId" --output text

Write-Host "Waiting for NAT Gateway to become available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

aws ec2 create-route `
  --route-table-id $PRI_RT_ID `
  --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID

Write-Host -ForegroundColor Green "NAT Gateway created and configured."
```

---

## 🏗️ PART 4 — CONFIGURES PUBLIC BASTION AND PRIVATE SECURITY GROUPS

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **EC2** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=my-custom-vpc" --query "Vpcs[0].VpcId" --output text)

MY_IP=(Invoke-WebRequest -Uri "https://checkip.amazonaws.com" \
  -UseBasicParsing).Content.Trim()

BASTION_SG=$(aws ec2 create-security-group \
  --group-name bastion-sg \
  --description "Allow SSH from my IP only" \
  --vpc-id $VPC_ID --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $BASTION_SG --protocol tcp --port 22 --cidr "$MY_IP/32"

PRIVATE_SG=$(aws ec2 create-security-group \
  --group-name private-sg \
  --description "Allow SSH from bastion only" \
  --vpc-id $VPC_ID --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $PRIVATE_SG --protocol tcp --port 22 \
  --source-group $BASTION_SG

echo -e "\e[32m\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
$VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Name,Values=my-custom-vpc" --query "Vpcs[0].VpcId" --output text

$MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" `
  -UseBasicParsing).Content.Trim()

$BASTION_SG = aws ec2 create-security-group `
  --group-name bastion-sg `
  --description "Allow SSH from my IP only" `
  --vpc-id $VPC_ID --query "GroupId" --output text

aws ec2 authorize-security-group-ingress `
  --group-id $BASTION_SG --protocol tcp --port 22 --cidr "$MY_IP/32"

$PRIVATE_SG = aws ec2 create-security-group `
  --group-name private-sg `
  --description "Allow SSH from bastion only" `
  --vpc-id $VPC_ID --query "GroupId" --output text

aws ec2 authorize-security-group-ingress `
  --group-id $PRIVATE_SG --protocol tcp --port 22 `
  --source-group $BASTION_SG

Write-Host -ForegroundColor Green "Security groups bastion-sg and private-sg created."
```

---

## 🏗️ PART 5 — LAUNCHES EC2 INSTANCES TO TEST ROUTING

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **EC2** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=my-custom-vpc" --query "Vpcs[0].VpcId" --output text)
PUB_SUBNET_A=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-subnet-a" --query "Subnets[0].SubnetId" --output text)
PRI_SUBNET_A=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-subnet-a" --query "Subnets[0].SubnetId" --output text)
BASTION_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=bastion-sg" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text)
PRIVATE_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=private-sg" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text)

AMI_ID=$(aws ec2 describe-images --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
  --query "sort_by(Images,&CreationDate)[-1].ImageId" --output text)

BASTION_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID --instance-type t2.micro \
  --key-name aws-ec2-keypair --subnet-id $PUB_SUBNET_A \
  --security-group-ids $BASTION_SG --associate-public-ip-address \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=bastion-host}]" \
  --query "Instances[0].InstanceId" --output text)

PRIVATE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID --instance-type t2.micro \
  --key-name aws-ec2-keypair --subnet-id $PRI_SUBNET_A \
  --security-group-ids $PRIVATE_SG --no-associate-public-ip-address \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=private-instance}]" \
  --query "Instances[0].InstanceId" --output text)

echo "Waiting for instances to be running..."
aws ec2 wait instance-running --instance-ids $BASTION_ID $PRIVATE_ID
echo -e "\e[32m\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
$VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Name,Values=my-custom-vpc" --query "Vpcs[0].VpcId" --output text
$PUB_SUBNET_A = aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-subnet-a" --query "Subnets[0].SubnetId" --output text
$PRI_SUBNET_A = aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-subnet-a" --query "Subnets[0].SubnetId" --output text
$BASTION_SG = aws ec2 describe-security-groups --filters "Name=group-name,Values=bastion-sg" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text
$PRIVATE_SG = aws ec2 describe-security-groups --filters "Name=group-name,Values=private-sg" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text

$AMI_ID = aws ec2 describe-images --owners amazon `
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" `
  --query "sort_by(Images,&CreationDate)[-1].ImageId" --output text

$BASTION_ID = aws ec2 run-instances `
  --image-id $AMI_ID --instance-type t2.micro `
  --key-name aws-ec2-keypair --subnet-id $PUB_SUBNET_A `
  --security-group-ids $BASTION_SG --associate-public-ip-address `
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=bastion-host}]" `
  --query "Instances[0].InstanceId" --output text

$PRIVATE_ID = aws ec2 run-instances `
  --image-id $AMI_ID --instance-type t2.micro `
  --key-name aws-ec2-keypair --subnet-id $PRI_SUBNET_A `
  --security-group-ids $PRIVATE_SG --no-associate-public-ip-address `
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=private-instance}]" `
  --query "Instances[0].InstanceId" --output text

Write-Host "Waiting for instances to be running..."
aws ec2 wait instance-running --instance-ids $BASTION_ID $PRIVATE_ID
Write-Host -ForegroundColor Green "Instances running: $BASTION_ID, $PRIVATE_ID"
```

---

## 🧹 TEARDOWN
To prevent recurring AWS charges, proceed to the `docs/cleanup-guide.md` to run the tear-down scripts.
