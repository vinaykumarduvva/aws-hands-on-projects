#!/bin/bash
# 06-cleanup.sh

# Delete the entire stack (removes ALL resources it created)
aws cloudformation delete-stack --stack-name my-app-stack

echo "Stack deletion initiated..."

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete \
  --stack-name my-app-stack

echo "Stack fully deleted — all resources removed"

# Verify nothing remains
aws cloudformation describe-stacks \
  --stack-name my-app-stack 2>&1 | grep "does not exist" || true

# Double-check no orphaned EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=cfn-web-app-*" \
    "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text
