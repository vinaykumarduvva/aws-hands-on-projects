#!/bin/bash

SG_ID=$(aws ec2 describe-security-groups --group-names ec2-web-sg --query "SecurityGroups[0].GroupId" --output text)
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
  --query "sort_by(Images,&CreationDate)[-1].ImageId" --output text)

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --key-name aws-ec2-keypair \
  --security-group-ids $SG_ID \
  --associate-public-ip-address \
  --user-data file://scripts/userdata.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=my-first-ec2}]" \
  --query "Instances[0].InstanceId" --output text)

aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

echo -e "\e[32m\e[0m"
