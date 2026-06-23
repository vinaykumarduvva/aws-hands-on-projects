# =============================================================================
# Project 6 — Script 10: Full Cleanup
# Deletes all resources in the correct dependency order
# =============================================================================

Write-Host "=== Project 6 — Full Cleanup ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "WARNING: This will permanently delete all Project 6 resources." -ForegroundColor Red
Write-Host "RDS data, EC2 instance, VPC, secrets — all gone." -ForegroundColor Red
Write-Host ""

# Re-fetch all IDs in case variables were lost between sessions
Write-Host "Re-fetching resource IDs..." -ForegroundColor Yellow

$VPC_ID = aws ec2 describe-vpcs `
    --filters "Name=tag:Name,Values=my-custom-vpc" `
    --query "Vpcs[0].VpcId" --output text

if ($VPC_ID -eq "None" -or -not $VPC_ID) {
    Write-Host "VPC not found — may already be deleted." -ForegroundColor Yellow
    exit 0
}

$APP_INSTANCE_ID = aws ec2 describe-instances `
    --filters "Name=tag:Name,Values=app-server" `
    "Name=instance-state-name,Values=running,stopped,pending" `
    --query "Reservations[0].Instances[0].InstanceId" --output text

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

$SUBNETS = aws ec2 describe-subnets `
    --filters "Name=vpc-id,Values=$VPC_ID" `
    --query "Subnets[*].SubnetId" --output text

Write-Host "IDs fetched. Proceeding with cleanup." -ForegroundColor Green
Write-Host ""

# ── STEP 1: TERMINATE EC2 ─────────────────────────────────────────────────────
if ($APP_INSTANCE_ID -and $APP_INSTANCE_ID -ne "None") {
    Write-Host "[1/10] Terminating EC2 instance $APP_INSTANCE_ID..." -ForegroundColor Yellow
    aws ec2 terminate-instances --instance-ids $APP_INSTANCE_ID | Out-Null
    aws ec2 wait instance-terminated --instance-ids $APP_INSTANCE_ID
    Write-Host "EC2 terminated." -ForegroundColor Green
}
else {
    Write-Host "[1/10] EC2 instance not found — skipping." -ForegroundColor Gray
}

# ── STEP 2: DELETE RDS ────────────────────────────────────────────────────────
Write-Host "[2/10] Deleting RDS instance (no final snapshot)..." -ForegroundColor Yellow

$RDS_STATUS = aws rds describe-db-instances `
    --db-instance-identifier myapp-database `
    --query "DBInstances[0].DBInstanceStatus" --output text 2>&1

if ($LASTEXITCODE -eq 0 -and $RDS_STATUS -ne "deleting") {
    aws rds delete-db-instance `
        --db-instance-identifier myapp-database `
        --skip-final-snapshot `
        --delete-automated-backups | Out-Null

    Write-Host "RDS deletion initiated. Waiting (3-5 minutes)..." -ForegroundColor Yellow
    aws rds wait db-instance-deleted --db-instance-identifier myapp-database
    Write-Host "RDS deleted." -ForegroundColor Green
}
else {
    Write-Host "[2/10] RDS not found or already deleting — skipping." -ForegroundColor Gray
}

# ── STEP 3: DELETE RDS SUBNET GROUP ──────────────────────────────────────────
Write-Host "[3/10] Deleting RDS subnet group..." -ForegroundColor Yellow
aws rds delete-db-subnet-group --db-subnet-group-name rds-subnet-group 2>&1 | Out-Null
Write-Host "Subnet group deleted." -ForegroundColor Green

# ── STEP 4: DELETE SECRET ─────────────────────────────────────────────────────
Write-Host "[4/10] Deleting Secrets Manager secret..." -ForegroundColor Yellow
aws secretsmanager delete-secret `
    --secret-id "rds/myapp/credentials" `
    --force-delete-without-recovery 2>&1 | Out-Null
Write-Host "Secret deleted." -ForegroundColor Green

# ── STEP 5: DELETE SECURITY GROUPS ───────────────────────────────────────────
Write-Host "[5/10] Deleting security groups..." -ForegroundColor Yellow
if ($RDS_SG -and $RDS_SG -ne "None") {
    aws ec2 delete-security-group --group-id $RDS_SG 2>&1 | Out-Null
}
if ($EC2_SG -and $EC2_SG -ne "None") {
    aws ec2 delete-security-group --group-id $EC2_SG 2>&1 | Out-Null
}
Write-Host "Security groups deleted." -ForegroundColor Green

# ── STEP 6: DELETE IAM ROLE AND PROFILE ──────────────────────────────────────
Write-Host "[6/10] Deleting IAM role and instance profile..." -ForegroundColor Yellow
aws iam remove-role-from-instance-profile `
    --instance-profile-name ec2-app-profile --role-name ec2-app-role 2>&1 | Out-Null
aws iam detach-role-policy `
    --role-name ec2-app-role `
    --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore 2>&1 | Out-Null
aws iam delete-role-policy `
    --role-name ec2-app-role `
    --policy-name secrets-manager-access 2>&1 | Out-Null
aws iam delete-instance-profile `
    --instance-profile-name ec2-app-profile 2>&1 | Out-Null
aws iam delete-role `
    --role-name ec2-app-role 2>&1 | Out-Null
Write-Host "IAM role deleted." -ForegroundColor Green

# ── STEP 7: DELETE SUBNETS ────────────────────────────────────────────────────
Write-Host "[7/10] Deleting subnets..." -ForegroundColor Yellow
foreach ($SUBNET_ID in $SUBNETS.Split()) {
    if ($SUBNET_ID -and $SUBNET_ID -ne "None") {
        aws ec2 delete-subnet --subnet-id $SUBNET_ID 2>&1 | Out-Null
    }
}
Write-Host "Subnets deleted." -ForegroundColor Green

# ── STEP 8: DELETE ROUTE TABLES ───────────────────────────────────────────────
Write-Host "[8/10] Deleting route tables..." -ForegroundColor Yellow
if ($PUB_RT_ID -and $PUB_RT_ID -ne "None") {
    aws ec2 delete-route-table --route-table-id $PUB_RT_ID 2>&1 | Out-Null
}
if ($PRI_RT_ID -and $PRI_RT_ID -ne "None") {
    aws ec2 delete-route-table --route-table-id $PRI_RT_ID 2>&1 | Out-Null
}
Write-Host "Route tables deleted." -ForegroundColor Green

# ── STEP 9: DETACH AND DELETE IGW ─────────────────────────────────────────────
Write-Host "[9/10] Removing Internet Gateway..." -ForegroundColor Yellow
if ($IGW_ID -and $IGW_ID -ne "None") {
    aws ec2 detach-internet-gateway `
        --internet-gateway-id $IGW_ID --vpc-id $VPC_ID 2>&1 | Out-Null
    aws ec2 delete-internet-gateway `
        --internet-gateway-id $IGW_ID 2>&1 | Out-Null
}
Write-Host "IGW deleted." -ForegroundColor Green

# ── STEP 10: DELETE VPC ───────────────────────────────────────────────────────
Write-Host "[10/10] Deleting VPC..." -ForegroundColor Yellow
aws ec2 delete-vpc --vpc-id $VPC_ID 2>&1 | Out-Null
Write-Host "VPC deleted." -ForegroundColor Green

# ── FINAL VERIFICATION ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Cleanup Verification ===" -ForegroundColor Cyan
Write-Host ""

$RDS_CHECK = aws rds describe-db-instances `
    --db-instance-identifier myapp-database 2>&1
if ($RDS_CHECK -match "DBInstanceNotFound") {
    Write-Host "RDS:    DELETED" -ForegroundColor Green
}
else {
    Write-Host "RDS:    Still present — check manually" -ForegroundColor Red
}

$VPC_CHECK = aws ec2 describe-vpcs --vpc-ids $VPC_ID 2>&1
if ($VPC_CHECK -match "InvalidVpcID") {
    Write-Host "VPC:    DELETED" -ForegroundColor Green
}
else {
    Write-Host "VPC:    Still present — check manually" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Project 6 Cleanup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check AWS Billing -> Cost Explorer in 24 hours to confirm $0 charges."