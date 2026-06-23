# Cleanup Guide — RDS MySQL + EC2 Two-Tier Application

## Why Cleanup Order Matters

AWS resources have dependencies. Deleting in the wrong order produces `DependencyViolation` errors. Follow the sequence below exactly.

**Critical**: RDS charges money even when idle if Free Tier hours are exhausted. Do not leave it running after the project.

---

## Full Cleanup Sequence

Script: `scripts/10-cleanup.ps1`

### Step 1 — Terminate EC2 App Server

```powershell
aws ec2 terminate-instances --instance-ids $APP_INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $APP_INSTANCE_ID
Write-Host "EC2 terminated"
```

The wait command blocks until the instance is fully terminated (~1–2 minutes).

### Step 2 — Delete RDS Instance

```powershell
aws rds delete-db-instance `
  --db-instance-identifier myapp-database `
  --skip-final-snapshot `
  --delete-automated-backups

aws rds wait db-instance-deleted `
  --db-instance-identifier myapp-database
Write-Host "RDS deleted"
```

`--skip-final-snapshot` avoids creating a snapshot that would cost storage. `--delete-automated-backups` removes the automated backup set immediately.

This step takes **3–5 minutes**.

### Step 3 — Delete RDS Subnet Group

```powershell
aws rds delete-db-subnet-group `
  --db-subnet-group-name rds-subnet-group
Write-Host "Subnet group deleted"
```

Must come after RDS deletion — the subnet group cannot be deleted while an RDS instance uses it.

### Step 4 — Delete Secrets Manager Secret

```powershell
aws secretsmanager delete-secret `
  --secret-id "rds/myapp/credentials" `
  --force-delete-without-recovery
Write-Host "Secret deleted"
```

`--force-delete-without-recovery` skips the 7-day recovery window. For a project secret with no production data, this is appropriate.

### Step 5 — Delete Security Groups

```powershell
aws ec2 delete-security-group --group-id $RDS_SG
aws ec2 delete-security-group --group-id $EC2_SG
Write-Host "Security groups deleted"
```

EC2 and RDS must be gone before their security groups can be deleted.

### Step 6 — Delete IAM Role and Profile

```powershell
aws iam remove-role-from-instance-profile `
  --instance-profile-name ec2-app-profile `
  --role-name ec2-app-role

aws iam detach-role-policy `
  --role-name ec2-app-role `
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

aws iam delete-role-policy `
  --role-name ec2-app-role `
  --policy-name secrets-manager-access

aws iam delete-instance-profile --instance-profile-name ec2-app-profile
aws iam delete-role --role-name ec2-app-role
Write-Host "IAM role deleted"
```

Order within IAM cleanup: remove role from profile → detach managed policy → delete inline policy → delete profile → delete role.

### Step 7 — Delete Subnets

```powershell
aws ec2 delete-subnet --subnet-id $PUB_SUBNET_A
aws ec2 delete-subnet --subnet-id $PUB_SUBNET_B
aws ec2 delete-subnet --subnet-id $PRI_SUBNET_A
aws ec2 delete-subnet --subnet-id $PRI_SUBNET_B
Write-Host "Subnets deleted"
```

### Step 8 — Delete Route Tables

```powershell
aws ec2 delete-route-table --route-table-id $PUB_RT_ID
aws ec2 delete-route-table --route-table-id $PRI_RT_ID
Write-Host "Route tables deleted"
```

Only custom route tables can be deleted — the main route table is deleted with the VPC.

### Step 9 — Detach and Delete Internet Gateway

```powershell
aws ec2 detach-internet-gateway `
  --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
Write-Host "IGW deleted"
```

Must detach before deleting.

### Step 10 — Delete VPC

```powershell
aws ec2 delete-vpc --vpc-id $VPC_ID
Write-Host "VPC deleted"
```

---

## Verification

```powershell
# RDS
aws rds describe-db-instances `
  --db-instance-identifier myapp-database 2>&1 | Select-String "DBInstanceNotFound"
# Expected: line containing "DBInstanceNotFound"

# EC2
aws ec2 describe-instances `
  --instance-ids $APP_INSTANCE_ID `
  --query "Reservations[0].Instances[0].State.Name" --output text
# Expected: terminated

# VPC
aws ec2 describe-vpcs --vpc-ids $VPC_ID 2>&1
# Expected: InvalidVpcID.NotFound error

# Secret
aws secretsmanager describe-secret `
  --secret-id "rds/myapp/credentials" 2>&1
# Expected: ResourceNotFoundException
```

---

## Cost Check After Cleanup

Log in to AWS Console → Billing → Cost Explorer.

After cleanup, you should see:
- RDS: $0.00 (or minimal if left running briefly)
- EC2: $0.00
- Secrets Manager: $0.00–$0.01

If the RDS line still shows charges after cleanup, verify deletion in the RDS console (check all regions — resources may exist in the wrong region if you switched accidentally).

---

## If Variables Are Lost

Re-fetch before running cleanup:

```powershell
$VPC_ID = aws ec2 describe-vpcs `
  --filters "Name=tag:Name,Values=my-custom-vpc" `
  --query "Vpcs[0].VpcId" --output text

$PUB_SUBNET_A = aws ec2 describe-subnets `
  --filters "Name=tag:Name,Values=public-subnet-a" `
  --query "Subnets[0].SubnetId" --output text

$PUB_SUBNET_B = aws ec2 describe-subnets `
  --filters "Name=tag:Name,Values=public-subnet-b" `
  --query "Subnets[0].SubnetId" --output text

$PRI_SUBNET_A = aws ec2 describe-subnets `
  --filters "Name=tag:Name,Values=private-subnet-a" `
  --query "Subnets[0].SubnetId" --output text

$PRI_SUBNET_B = aws ec2 describe-subnets `
  --filters "Name=tag:Name,Values=private-subnet-b" `
  --query "Subnets[0].SubnetId" --output text

$EC2_SG = aws ec2 describe-security-groups `
  --filters "Name=group-name,Values=ec2-app-sg" "Name=vpc-id,Values=$VPC_ID" `
  --query "SecurityGroups[0].GroupId" --output text

$RDS_SG = aws ec2 describe-security-groups `
  --filters "Name=group-name,Values=rds-sg" "Name=vpc-id,Values=$VPC_ID" `
  --query "SecurityGroups[0].GroupId" --output text

$IGW_ID = aws ec2 describe-internet-gateways `
  --filters "Name=tag:Name,Values=my-vpc-igw" `
  --query "InternetGateways[0].InternetGatewayId" --output text

$PUB_RT_ID = aws ec2 describe-route-tables `
  --filters "Name=tag:Name,Values=public-route-table" `
  --query "RouteTables[0].RouteTableId" --output text

$PRI_RT_ID = aws ec2 describe-route-tables `
  --filters "Name=tag:Name,Values=private-route-table" `
  --query "RouteTables[0].RouteTableId" --output text

$APP_INSTANCE_ID = aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=app-server" `
  --query "Reservations[0].Instances[0].InstanceId" --output text

Write-Host "All IDs re-fetched"
Write-Host "VPC: $VPC_ID"
Write-Host "EC2: $APP_INSTANCE_ID"
```