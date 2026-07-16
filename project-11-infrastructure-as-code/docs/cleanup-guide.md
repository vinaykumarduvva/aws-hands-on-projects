# Cleanup Guide

One of the primary benefits of using Infrastructure as Code (CloudFormation) is the ability to cleanly and completely tear down an entire environment without leaving orphaned resources behind.

## PART 11 CLEANUP

```powershell
# Delete the entire stack (removes ALL resources it created)
aws cloudformation delete-stack --stack-name my-app-stack

Write-Host "Stack deletion initiated..."

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete `
  --stack-name my-app-stack

Write-Host "Stack fully deleted â€” all resources removed"

# Verify nothing remains
aws cloudformation describe-stacks `
  --stack-name my-app-stack 2>&1 | Select-String "does not exist"
# Expected: "Stack with id my-app-stack does not exist"

# Double-check no orphaned EC2 instances
aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=cfn-web-app-*" `
    "Name=instance-state-name,Values=running" `
  --query "Reservations[*].Instances[*].InstanceId" `
  --output text
# Expected: empty
```

✅ One command — every VPC, subnet, security group, launch template, ALB, target group, and ASG instance is gone.


