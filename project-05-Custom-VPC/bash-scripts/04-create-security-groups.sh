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
