#!/bin/bash

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

aws iam attach-role-policy \
  --role-name ec2-ssm-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

aws iam create-instance-profile --instance-profile-name ec2-ssm-profile
aws iam add-role-to-instance-profile \
  --instance-profile-name ec2-ssm-profile --role-name ec2-ssm-role

INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=my-first-ec2" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text)

aws ec2 associate-iam-instance-profile \
  --instance-id $INSTANCE_ID \
  --iam-instance-profile Name=ec2-ssm-profile

echo -e "\e[32m\e[0m"
echo "Connect with: aws ssm start-session --target $INSTANCE_ID"
