#!/bin/bash
set -e
set -u

echo "=> PART 1 - BUILD THE NETWORK LAYER"
echo "=> Step 1 - Create VPC"
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=capstone-vpc},{Key=Project,Value=project-14-capstone}]" \
  --query "Vpc.VpcId" --output text)

aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support
echo "VPC: $VPC_ID"

echo "=> Step 2 - Create all 6 subnets"
# Public subnets (Web Tier)
PUB_A=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/24 --availability-zone ap-south-1a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-a},{Key=Tier,Value=web}]" --query "Subnet.SubnetId" --output text)
PUB_B=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.2.0/24 --availability-zone ap-south-1b --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-b},{Key=Tier,Value=web}]" --query "Subnet.SubnetId" --output text)

# Private App subnets (App Tier)
APP_A=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.3.0/24 --availability-zone ap-south-1a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-app-subnet-a},{Key=Tier,Value=app}]" --query "Subnet.SubnetId" --output text)
APP_B=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.4.0/24 --availability-zone ap-south-1b --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-app-subnet-b},{Key=Tier,Value=app}]" --query "Subnet.SubnetId" --output text)

# Private DB subnets (DB Tier)
DB_A=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.5.0/24 --availability-zone ap-south-1a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-db-subnet-a},{Key=Tier,Value=db}]" --query "Subnet.SubnetId" --output text)
DB_B=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.6.0/24 --availability-zone ap-south-1b --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-db-subnet-b},{Key=Tier,Value=db}]" --query "Subnet.SubnetId" --output text)

echo "=> Enabling auto-assign public IP on public subnets"
aws ec2 modify-subnet-attribute --subnet-id "$PUB_A" --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id "$PUB_B" --map-public-ip-on-launch
echo "All 6 subnets created"

echo "=> Step 3 - Internet Gateway"
IGW_ID=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=capstone-igw}]" --query "InternetGateway.InternetGatewayId" --output text)
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
echo "IGW: $IGW_ID"

echo "=> Step 4 - NAT Gateway"
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc --query "AllocationId" --output text)
NAT_GW_ID=$(aws ec2 create-nat-gateway --subnet-id "$PUB_A" --allocation-id "$EIP_ALLOC" --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=capstone-nat}]" --query "NatGateway.NatGatewayId" --output text)
echo "NAT Gateway: $NAT_GW_ID - waiting..."
aws ec2 wait nat-gateway-available --nat-gateway-ids "$NAT_GW_ID"
echo "NAT Gateway available"

echo "=> Step 5 - Route Tables"
PUB_RT=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=public-rt}]" --query "RouteTable.RouteTableId" --output text)
aws ec2 create-route --route-table-id "$PUB_RT" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" > /dev/null
aws ec2 associate-route-table --route-table-id "$PUB_RT" --subnet-id "$PUB_A" > /dev/null
aws ec2 associate-route-table --route-table-id "$PUB_RT" --subnet-id "$PUB_B" > /dev/null

PRI_RT=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=private-rt}]" --query "RouteTable.RouteTableId" --output text)
aws ec2 create-route --route-table-id "$PRI_RT" --destination-cidr-block 0.0.0.0/0 --nat-gateway-id "$NAT_GW_ID" > /dev/null

for SUBNET in "$APP_A" "$APP_B" "$DB_A" "$DB_B"; do
  aws ec2 associate-route-table --route-table-id "$PRI_RT" --subnet-id "$SUBNET" > /dev/null
done
echo "Route tables configured"
