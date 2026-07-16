# Cleanup Guide

This guide covers the systematic tear-down of the infrastructure.

## 🧹 DESTROYS THE INFRASTRUCTURE

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the relevant service dashboard (e.g., EC2, VPC, S3, RDS).
2. Locate the resources you created for this project (refer to the `Resources to Delete` table above for the required deletion order).
3. Select each resource and click the primary **Delete**, **Terminate**, or **Empty** button.
4. In the confirmation dialog, type the required confirmation text (e.g., `delete`, `permanently delete`, or the resource name).
5. Click to finalize the deletion, and wait for the resource to completely disappear from the console list before moving to the next service.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# Get Instance ID
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=my-first-ec2" --query "Reservations[*].Instances[*].InstanceId" --output text)

# Step 1 — Terminate the instance (permanent deletion)
if [ -n "$INSTANCE_ID" ]; then
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID
    echo "Waiting for instance to terminate..."
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
    echo "Instance terminated"
fi

# Get Security Group ID
SG_ID=$(aws ec2 describe-security-groups --group-names ec2-web-sg --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

# Step 2 — Delete the security group (must wait for instance to terminate first)
if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
    aws ec2 delete-security-group --group-id $SG_ID
    echo "Security group deleted"
fi

# Step 3 — Delete the key pair from AWS
aws ec2 delete-key-pair --key-name aws-ec2-keypair
echo "Key pair deleted from AWS"

# Step 4 — Detach and delete IAM instance profile
aws iam remove-role-from-instance-profile \
  --instance-profile-name ec2-ssm-profile \
  --role-name ec2-ssm-role 2>/dev/null || true

aws iam detach-role-policy \
  --role-name ec2-ssm-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore 2>/dev/null || true

aws iam delete-instance-profile --instance-profile-name ec2-ssm-profile 2>/dev/null || true
aws iam delete-role --role-name ec2-ssm-role 2>/dev/null || true

echo "IAM role and profile deleted"

# Verify instance is gone
if [ -n "$INSTANCE_ID" ]; then
    aws ec2 describe-instances \
      --instance-ids $INSTANCE_ID \
      --query "Reservations[0].Instances[0].State.Name" \
      --output text
fi
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Get Instance ID
$INSTANCE_ID = aws ec2 describe-instances --filters "Name=tag:Name,Values=my-first-ec2" --query "Reservations[*].Instances[*].InstanceId" --output text

# Step 1 — Terminate the instance (permanent deletion)
if ($INSTANCE_ID) {
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID
    Write-Host "Waiting for instance to terminate..."
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
    Write-Host "Instance terminated"
}

# Get Security Group ID
$SG_ID = aws ec2 describe-security-groups --group-names ec2-web-sg --query "SecurityGroups[0].GroupId" --output text

# Step 2 — Delete the security group (must wait for instance to terminate first)
if ($SG_ID) {
    aws ec2 delete-security-group --group-id $SG_ID
    Write-Host "Security group deleted"
}

# Step 3 — Delete the key pair from AWS
aws ec2 delete-key-pair --key-name aws-ec2-keypair
Write-Host "Key pair deleted from AWS"

# Step 4 — Detach and delete IAM instance profile
aws iam remove-role-from-instance-profile `
  --instance-profile-name ec2-ssm-profile `
  --role-name ec2-ssm-role -ErrorAction SilentlyContinue

aws iam detach-role-policy `
  --role-name ec2-ssm-role `
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore -ErrorAction SilentlyContinue

aws iam delete-instance-profile --instance-profile-name ec2-ssm-profile -ErrorAction SilentlyContinue
aws iam delete-role --role-name ec2-ssm-role -ErrorAction SilentlyContinue

Write-Host "IAM role and profile deleted"

# Verify instance is gone
if ($INSTANCE_ID) {
    aws ec2 describe-instances `
      --instance-ids $INSTANCE_ID `
      --query "Reservations[0].Instances[0].State.Name" `
      --output text
}
```
