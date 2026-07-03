# Deployment Guide

## Automated Scripts Available
> [!TIP]
> **Dual-Platform Execution:** This project contains fully automated deployment and teardown scripts for both Windows (PowerShell) and Linux/macOS (Bash). Check the `scripts/` directory for `.ps1` files and the `bash-scripts/` directory for `.sh` files.

## Cleanup Guide

## Cleanup (full teardown)

```powershell
# 1. Terminate instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID

# 2. Delete security group
aws ec2 delete-security-group --group-id $SG_ID

# 3. Delete key pair from AWS (keep local .ppk file)
aws ec2 delete-key-pair --key-name aws-ec2-keypair

# 4. Remove IAM role and profile
aws iam remove-role-from-instance-profile `
  --instance-profile-name ec2-ssm-profile --role-name ec2-ssm-role
aws iam detach-role-policy `
  --role-name ec2-ssm-role `
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam delete-instance-profile --instance-profile-name ec2-ssm-profile
aws iam delete-role --role-name ec2-ssm-role

# 5. Verify cleanup
aws ec2 describe-instances --instance-ids $INSTANCE_ID `
  --query "Reservations[0].Instances[0].State.Name" --output text
# Expected: terminated
```

---

