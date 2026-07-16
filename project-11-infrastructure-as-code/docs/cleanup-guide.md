# Project 11 Cleanup Guide: CloudFormation

One of the primary benefits of using Infrastructure as Code (CloudFormation) is the ability to cleanly and completely tear down an entire environment without leaving orphaned resources behind.

> [!CAUTION]
> Deleting this stack is an irreversible action. All underlying resources (VPC, Subnets, EC2 instances, ALB) will be permanently destroyed. Ensure you do not have any critical data or manual modifications on the instances before proceeding.

## 📋 Resources to Delete

| Resource | Service | Deletion Order Rationale |
|:---|:---|:---|
| `my-app-stack` | CloudFormation | Deleting the parent stack automatically handles the strict deletion dependency order of all nested resources (ASG -> ALB -> EC2 -> SG -> VPC). |

## 🧹 TEARDOWN ALL RESOURCES AUTOMATICALLY

### 🖥️ Method 1: AWS Management Console

1. Navigate to the **CloudFormation Console**.
2. Select **Stacks** from the left navigation pane.
3. Select the `my-app-stack` from the list.
4. Click the **Delete** button at the top right.
5. In the confirmation dialog, click **Delete**.
6. The status will change to `DELETE_IN_PROGRESS`. You can monitor the Events tab to watch the resources being deleted in reverse dependency order. It will eventually disappear from the list.

### 🐧 Method 2: AWS CLI (Bash)

Run the following script to initiate and wait for the complete stack deletion:

```bash
# Delete the entire stack (removes ALL resources it created)
aws cloudformation delete-stack --stack-name my-app-stack

echo "Stack deletion initiated..."

# Wait for deletion to complete (blocks until done)
aws cloudformation wait stack-delete-complete \
  --stack-name my-app-stack

echo "Stack fully deleted all resources removed"
```

### 🪟 Method 3: AWS CLI (PowerShell)

Run the following script to initiate and wait for the complete stack deletion:

```powershell
# Delete the entire stack (removes ALL resources it created)
aws cloudformation delete-stack --stack-name my-app-stack

Write-Host "Stack deletion initiated..."

# Wait for deletion to complete (blocks until done)
aws cloudformation wait stack-delete-complete `
  --stack-name my-app-stack

Write-Host "Stack fully deleted all resources removed"
```

## ✅ Cleanup Verification

Run the following commands to guarantee all resources have been permanently removed:

```bash
# Verify the stack no longer exists
aws cloudformation describe-stacks --stack-name my-app-stack 2>&1
# Expected Output: "An error occurred (ValidationError)... Stack with id my-app-stack does not exist"

# Double-check no orphaned EC2 instances are still running
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=cfn-web-app-*" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text
# Expected Output: empty
```

## 💰 Cost Implications

By completing this cleanup, you will immediately stop accruing charges for:
- **Application Load Balancer (ALB):** ~$0.0225 per hour plus LCU charges.
- **Amazon EC2:** Compute time for any instances provisioned by the ASG.
- **Amazon EBS:** Storage costs for the gp3 root volumes attached to the instances.
- **NAT Gateways / EIPs:** If any were provisioned as part of the stack.
