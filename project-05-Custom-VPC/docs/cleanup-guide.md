# Cleanup Guide

To avoid unexpected AWS charges—specifically from the NAT Gateway and Elastic IP—it is critical to tear down the VPC architecture when you are finished testing.

VPCs have a strict dependency model. You cannot delete a VPC if it still contains subnets, nor delete a subnet if it contains an EC2 instance. **You must follow this exact order.**

## Step 1: Terminate EC2 Instances
All instances running inside the VPC must be terminated first.
```bash
aws ec2 terminate-instances --instance-ids <BASTION_ID> <PRIVATE_ID>
```
*Wait for the instances to reach the `terminated` state before proceeding.*

## Step 2: Delete NAT Gateway
The NAT Gateway is the only resource in this lab that incurs an hourly charge.
```bash
aws ec2 delete-nat-gateway --nat-gateway-id <NAT_GW_ID>
```
*NAT Gateway deletion can take 1-3 minutes. You must wait for the state to become `deleted`.*

## Step 3: Release Elastic IP
If you delete the NAT Gateway but forget to release the Elastic IP, AWS will charge you for holding an unattached EIP.
```bash
aws ec2 release-address --allocation-id <EIP_ALLOC>
```

## Step 4: Delete Security Groups
Because the Private SG references the Bastion SG, delete the Private SG first, then the Bastion SG.
```bash
aws ec2 delete-security-group --group-id <PRIVATE_SG>
aws ec2 delete-security-group --group-id <BASTION_SG>
```

## Step 5: Delete Subnets
Remove all four subnets.
```bash
aws ec2 delete-subnet --subnet-id <PUB_SUBNET_A>
aws ec2 delete-subnet --subnet-id <PUB_SUBNET_B>
aws ec2 delete-subnet --subnet-id <PRI_SUBNET_A>
aws ec2 delete-subnet --subnet-id <PRI_SUBNET_B>
```

## Step 6: Delete Route Tables
Remove the custom route tables you created.
```bash
aws ec2 delete-route-table --route-table-id <PUB_RT_ID>
aws ec2 delete-route-table --route-table-id <PRI_RT_ID>
```

## Step 7: Detach and Delete Internet Gateway
Before deleting the IGW, it must be detached from the VPC.
```bash
aws ec2 detach-internet-gateway --internet-gateway-id <IGW_ID> --vpc-id <VPC_ID>
aws ec2 delete-internet-gateway --internet-gateway-id <IGW_ID>
```

## Step 8: Delete the VPC
Once all dependencies are removed, you can safely delete the VPC.
```bash
aws ec2 delete-vpc --vpc-id <VPC_ID>
```

> [!TIP]
> You can automate this entire teardown process by running the `06-cleanup.ps1` or `06-cleanup.sh` scripts provided in the `scripts/` directory!