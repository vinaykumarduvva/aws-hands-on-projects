# =============================================================================
# Project 6 — Script 05: Create RDS MySQL Instance
# Launches db.t3.micro MySQL 8.0 in private subnets — no public access
# =============================================================================

Write-Host "=== Project 6 — Launch RDS MySQL ===" -ForegroundColor Cyan
Write-Host ""

if (-not $RDS_SG) {
    Write-Host "ERROR: \$RDS_SG not set. Run 02-security-groups.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Engine:         MySQL 8.0"
Write-Host "  Instance class: db.t3.micro (Free Tier eligible)"
Write-Host "  Storage:        20 GiB gp2"
Write-Host "  Subnet group:   rds-subnet-group"
Write-Host "  Security group: $RDS_SG (rds-sg)"
Write-Host "  Public access:  No"
Write-Host "  Initial DB:     appdb"
Write-Host ""

Write-Host "Launching RDS instance (this command returns immediately)..." -ForegroundColor Yellow

aws rds create-db-instance `
    --db-instance-identifier myapp-database `
    --db-instance-class db.t3.micro `
    --engine mysql `
    --engine-version 8.0 `
    --master-username admin `
    --master-user-password "MyDB#Secure2024!" `
    --db-name appdb `
    --vpc-security-group-ids $RDS_SG `
    --db-subnet-group-name rds-subnet-group `
    --allocated-storage 20 `
    --storage-type gp2 `
    --no-multi-az `
    --no-publicly-accessible `
    --backup-retention-period 1 `
    --no-deletion-protection `
    --tags Key=Name,Value=myapp-database | Out-Null

Write-Host "RDS creation initiated." -ForegroundColor Green
Write-Host ""
Write-Host "Waiting for RDS to become available (typically 5-10 minutes)..." -ForegroundColor Yellow
Write-Host "You can monitor progress in: RDS console -> Databases -> myapp-database"
Write-Host ""

# Block until available — this is the most reliable approach
aws rds wait db-instance-available `
    --db-instance-identifier myapp-database

Write-Host "RDS is available!" -ForegroundColor Green
Write-Host ""

# Fetch and display the endpoint
$RDS_ENDPOINT = aws rds describe-db-instances `
    --db-instance-identifier myapp-database `
    --query "DBInstances[0].Endpoint.Address" `
    --output text

$RDS_PORT = aws rds describe-db-instances `
    --db-instance-identifier myapp-database `
    --query "DBInstances[0].Endpoint.Port" `
    --output text

Write-Host "=== RDS MySQL Ready ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Endpoint: $RDS_ENDPOINT"
Write-Host "  Port:     $RDS_PORT"
Write-Host ""
Write-Host "IMPORTANT: Copy the endpoint above. You will need it in Part 7."
Write-Host ""

# Describe the instance
aws rds describe-db-instances `
    --db-instance-identifier myapp-database `
    --query "DBInstances[0].{ID:DBInstanceIdentifier,Class:DBInstanceClass,Engine:Engine,Status:DBInstanceStatus,Endpoint:Endpoint.Address,Storage:AllocatedStorage,Public:PubliclyAccessible}" `
    --output table

Write-Host ""
Write-Host "Next step: Run 06-launch-ec2.ps1" -ForegroundColor Cyan