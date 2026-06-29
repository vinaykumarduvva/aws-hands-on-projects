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
