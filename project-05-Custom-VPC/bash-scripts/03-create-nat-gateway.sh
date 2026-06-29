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
