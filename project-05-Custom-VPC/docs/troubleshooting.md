# Troubleshooting Guide

When building VPC infrastructure from scratch, the strict dependency chain of AWS networking often leads to deployment or teardown errors if steps are executed out of order. 

Use this table to diagnose and resolve common issues encountered during this project.

| Problem | Cause | Fix |
|:--------|:------|:----|
| **Cannot delete VPC** (`DependencyViolation`) | Subnets, IGW, or EC2 instances still exist within the VPC. AWS prevents deleting a VPC that has active resources. | Delete in exact order: EC2 Instances → NAT GW → Subnets → Route Tables → IGW → VPC. |
| **NAT Gateway stuck in `Pending` state** | This is normal behavior. NAT Gateways take time to provision underlying ENIs. | Wait 1–2 minutes. Run `aws ec2 describe-nat-gateways` until the state says `Available`. |
| **Private instance cannot reach the internet** | The NAT Gateway route is missing from the Private Route Table. | Verify your private route table has a route for `0.0.0.0/0` pointing to `nat-xxxxxx`. |
| **Bastion SSH connection times out** | The Bastion Security Group is missing port 22 access, or your local IP address changed since you created the rule. | Re-check `bastion-sg`. Ensure the Inbound Rule allows Port `22` specifically from your current Public IP (`curl ifconfig.me`). |
| **SSM Session Manager won't connect** | The IAM profile isn't attached, or the SSM agent on the instance hasn't checked in yet. | Wait 3 minutes after attaching the instance profile. Verify the profile contains the `AmazonSSMManagedInstanceCore` managed policy. |
| **`delete-security-group` fails** | An EC2 instance is still attached to the group, or another security group references it. | Terminate instances first and wait for the `terminated` state. Then delete the referencing SG (`private-sg`) before the base SG (`bastion-sg`). |
| **Elastic IP not releasing** | The EIP is still associated with the NAT Gateway. | Wait for the NAT Gateway deletion to fully complete (state: `deleted`), then release the EIP. |

## Useful CLI Diagnostic Commands

**Check Route Tables:**
```bash
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<YOUR_VPC_ID>"
```

**Check Security Group Rules:**
```bash
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=<YOUR_VPC_ID>"
```

**Check Instance States:**
```bash
aws ec2 describe-instances --filters "Name=vpc-id,Values=<YOUR_VPC_ID>" --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name}"
```