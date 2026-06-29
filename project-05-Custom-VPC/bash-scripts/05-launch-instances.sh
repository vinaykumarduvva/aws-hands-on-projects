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
