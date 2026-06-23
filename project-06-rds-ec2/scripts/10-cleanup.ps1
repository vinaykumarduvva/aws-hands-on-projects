# ============================================================
# 08-cleanup.ps1 — Project 6 Full Teardown
# Fill in your resource IDs then run this script
# Usage: .\scripts\08-cleanup.ps1
# ============================================================

# ── SET YOUR IDs HERE BEFORE RUNNING ─────────────────────────
$APP_INSTANCE_ID = "i-XXXXXXXXXXXXXXXXX"
$EC2_SG = "sg-XXXXXXXXXXXXXXXXX"   # ec2-app-sg
$RDS_SG = "sg-XXXXXXXXXXXXXXXXX"   # rds-sg
$PUB_SUBNET_A = "subnet-XXXXXXXXXX"
$PRI_SUBNET_A = "subnet-XXXXXXXXXX"
$PRI_SUBNET_B = "subnet-XXXXXXXXXX"
$PUB_RT_ID = "rtb-XXXXXXXXXXXXXXXXX"
$IGW_ID = "igw-XXXXXXXXXXXXXXXXX"
$VPC_ID = "vpc-XXXXXXXXXXXXXXXXX"

Write-Host "============================================"
Write-Host "  Project 6 — Full Teardown Starting"
Write-Host "============================================"
Write-Host ""

# Step 1 — Terminate EC2 App Server
Write-Host "[1/10] Terminating EC2 app server..."
aws ec2 terminate-instances --instance-ids $APP_INSTANCE_ID | Out-Null
aws ec2 wait instance-terminated --instance-ids $APP_INSTANCE_ID
Write-Host "       EC2 terminated ✅"
Write-Host ""

# Step 2 — Delete RDS Instance
Write-Host "[2/10] Deleting RDS MySQL instance..."
Write-Host "       (This takes 3-5 minutes)"
aws rds delete-db-instance `
    --db-instance-identifier myapp-database `
    --skip-final-snapshot `
    --delete-automated-backups | Out-Null

aws rds wait db-instance-deleted `
    --db-instance-identifier myapp-database
Write-Host "       RDS deleted ✅"
Write-Host ""

# Step 3 — Delete RDS Subnet Group
Write-Host "[3/10] Deleting RDS subnet group..."
aws rds delete-db-subnet-group `
    --db-subnet-group-name rds-subnet-group | Out-Null
Write-Host "       RDS subnet group deleted ✅"
Write-Host ""

# Step 4 — Delete Secret from Secrets Manager
Write-Host "[4/10] Deleting secret from Secrets Manager..."
aws secretsmanager delete-secret `
    --secret-id "rds/myapp/credentials" `
    --force-delete-without-recovery | Out-Null
Write-Host "       Secret deleted ✅"
Write-Host ""

# Step 5 — Delete Security Groups
Write-Host "[5/10] Deleting security groups..."
# Delete rds-sg first (references ec2-app-sg)
aws ec2 delete-security-group --group-id $RDS_SG | Out-Null
Write-Host "       rds-sg deleted ✅"
aws ec2 delete-security-group --group-id $EC2_SG | Out-Null
Write-Host "       ec2-app-sg deleted ✅"
Write-Host ""

# Step 6 — Delete IAM Role and Profile
Write-Host "[6/10] Deleting IAM role and instance profile..."
aws iam remove-role-from-instance-profile `
    --instance-profile-name ec2-app-profile `
    --role-name ec2-app-role | Out-Null

aws iam detach-role-policy `
    --role-name ec2-app-role `
    --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore | Out-Null

aws iam delete-role-policy `
    --role-name ec2-app-role `
    --policy-name secrets-manager-access | Out-Null

aws iam delete-instance-profile `
    --instance-profile-name ec2-app-profile | Out-Null

aws iam delete-role --role-name ec2-app-role | Out-Null
Write-Host "       IAM role and profile deleted ✅"
Write-Host ""

# Step 7 — Delete Subnets
Write-Host "[7/10] Deleting subnets..."
aws ec2 delete-subnet --subnet-id $PUB_SUBNET_A | Out-Null
aws ec2 delete-subnet --subnet-id $PRI_SUBNET_A | Out-Null
aws ec2 delete-subnet --subnet-id $PRI_SUBNET_B | Out-Null
Write-Host "       All subnets deleted ✅"
Write-Host ""

# Step 8 — Delete Route Table
Write-Host "[8/10] Deleting route table..."
aws ec2 delete-route-table --route-table-id $PUB_RT_ID | Out-Null
Write-Host "       Route table deleted ✅"
Write-Host ""

# Step 9 — Detach and Delete IGW
Write-Host "[9/10] Detaching and deleting Internet Gateway..."
aws ec2 detach-internet-gateway `
    --internet-gateway-id $IGW_ID `
    --vpc-id $VPC_ID | Out-Null
aws ec2 delete-internet-gateway `
    --internet-gateway-id $IGW_ID | Out-Null
Write-Host "       IGW deleted ✅"
Write-Host ""

# Step 10 — Delete VPC
Write-Host "[10/10] Deleting VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID | Out-Null
Write-Host "        VPC deleted ✅"
Write-Host ""

# Final Verification
Write-Host "============================================"
Write-Host "  Verifying Cleanup..."
Write-Host "============================================"

# Check RDS
try {
    aws rds describe-db-instances `
        --db-instance-identifier myapp-database 2>$null | Out-Null
    Write-Host "  ⚠️  RDS still exists - check manually"
}
catch {
    Write-Host "  ✅ RDS fully deleted"
}

# Check VPC
$VPC_CHECK = aws ec2 describe-vpcs `
    --filters "Name=tag:Name,Values=my-custom-vpc" `
    --query "Vpcs[*].VpcId" --output text

if ($VPC_CHECK) {
    Write-Host "  ⚠️  VPC still exists: $VPC_CHECK"
}
else {
    Write-Host "  ✅ VPC fully deleted"
}

# Check secrets
$SECRET_CHECK = aws secretsmanager list-secrets `
    --query "SecretList[?Name=='rds/myapp/credentials'].Name" `
    --output text

if ($SECRET_CHECK) {
    Write-Host "  ⚠️  Secret still exists (may take up to 7 days to fully purge)"
}
else {
    Write-Host "  ✅ Secret deleted"
}

Write-Host ""
Write-Host "============================================"
Write-Host "  Cleanup Complete"
Write-Host "  Estimated total cost: ~`$0.01"
Write-Host "  (Secrets Manager only)"
Write-Host "============================================"