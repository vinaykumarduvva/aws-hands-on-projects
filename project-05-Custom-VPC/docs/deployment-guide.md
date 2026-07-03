# Deployment Guide

## Automated Scripts Available
> [!TIP]
> **Dual-Platform Execution:** This project contains fully automated deployment and teardown scripts for both Windows (PowerShell) and Linux/macOS (Bash). Check the `scripts/` directory for `.ps1` files and the `bash-scripts/` directory for `.sh` files.

## Full Setup Guide

### Part 1 — Create VPC

```powershell
$VPC_ID = aws ec2 create-vpc `
  --cidr-block 10.0.0.0/16 `
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=my-custom-vpc}]" `
  --query "Vpc.VpcId" --output text

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

Write-Host "VPC ID: $VPC_ID"
```

### Part 2 — Create Subnets

```powershell
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

$PRI_SUBNET_A = aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 `
  --availability-zone us-east-1a `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-a}]" `
  --query "Subnet.SubnetId" --output text

$PRI_SUBNET_B = aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.4.0/24 `
  --availability-zone us-east-1b `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-b}]" `
  --query "Subnet.SubnetId" --output text

# Enable auto-assign public IP on public subnets
aws ec2 modify-subnet-attribute `
  --subnet-id $PUB_SUBNET_A --map-public-ip-on-launch
aws ec2 modify-subnet-attribute `
  --subnet-id $PUB_SUBNET_B --map-public-ip-on-launch
```

### Part 3 — Internet Gateway

```powershell
$IGW_ID = aws ec2 create-internet-gateway `
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-vpc-igw}]" `
  --query "InternetGateway.InternetGatewayId" --output text

aws ec2 attach-internet-gateway `
  --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
```

### Part 4 — Route Tables

```powershell
# Public route table
$PUB_RT_ID = aws ec2 create-route-table `
  --vpc-id $VPC_ID `
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=public-route-table}]" `
  --query "RouteTable.RouteTableId" --output text

aws ec2 create-route `
  --route-table-id $PUB_RT_ID `
  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

aws ec2 associate-route-table --route-table-id $PUB_RT_ID --subnet-id $PUB_SUBNET_A
aws ec2 associate-route-table --route-table-id $PUB_RT_ID --subnet-id $PUB_SUBNET_B

# Private route table
$PRI_RT_ID = aws ec2 create-route-table `
  --vpc-id $VPC_ID `
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=private-route-table}]" `
  --query "RouteTable.RouteTableId" --output text

aws ec2 associate-route-table --route-table-id $PRI_RT_ID --subnet-id $PRI_SUBNET_A
aws ec2 associate-route-table --route-table-id $PRI_RT_ID --subnet-id $PRI_SUBNET_B
```

### Part 5 — NAT Gateway

```powershell
$EIP_ALLOC = aws ec2 allocate-address `
  --domain vpc --query "AllocationId" --output text

$NAT_GW_ID = aws ec2 create-nat-gateway `
  --subnet-id $PUB_SUBNET_A `
  --allocation-id $EIP_ALLOC `
  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=my-nat-gateway}]" `
  --query "NatGateway.NatGatewayId" --output text

aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

aws ec2 create-route `
  --route-table-id $PRI_RT_ID `
  --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID
```

### Part 6 — Security Groups

```powershell
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
```

### Part 7 — Launch EC2 Instances

```powershell
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

aws ec2 wait instance-running --instance-ids $BASTION_ID $PRIVATE_ID
```

---

## Cleanup Guide

## Cleanup — Full Teardown

```powershell
# Run in this exact order — dependencies matter

# 1. Terminate instances
aws ec2 terminate-instances --instance-ids $BASTION_ID $PRIVATE_ID
aws ec2 wait instance-terminated --instance-ids $BASTION_ID $PRIVATE_ID

# 2. Delete NAT Gateway immediately (stops billing)
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_ID
Start-Sleep -Seconds 60

# 3. Release Elastic IP
aws ec2 release-address --allocation-id $EIP_ALLOC

# 4. Delete security groups
aws ec2 delete-security-group --group-id $PRIVATE_SG
aws ec2 delete-security-group --group-id $BASTION_SG

# 5. Delete subnets
aws ec2 delete-subnet --subnet-id $PUB_SUBNET_A
aws ec2 delete-subnet --subnet-id $PUB_SUBNET_B
aws ec2 delete-subnet --subnet-id $PRI_SUBNET_A
aws ec2 delete-subnet --subnet-id $PRI_SUBNET_B

# 6. Delete route tables
aws ec2 delete-route-table --route-table-id $PUB_RT_ID
aws ec2 delete-route-table --route-table-id $PRI_RT_ID

# 7. Detach and delete IGW
aws ec2 detach-internet-gateway `
  --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# 8. Delete VPC
aws ec2 delete-vpc --vpc-id $VPC_ID
```

---

