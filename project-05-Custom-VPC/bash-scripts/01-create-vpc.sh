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
