# =============================================================================
# Project 6 — Script 03: RDS Subnet Group
# Creates the DB subnet group spanning both private subnets across two AZs
# =============================================================================

Write-Host "=== Project 6 — RDS Subnet Group ===" -ForegroundColor Cyan
Write-Host ""

if (-not $PRI_SUBNET_A -or -not $PRI_SUBNET_B) {
    Write-Host "ERROR: Private subnet IDs not set. Run 01-vpc-setup.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "Using private subnets:" -ForegroundColor Yellow
Write-Host "  private-subnet-a: $PRI_SUBNET_A (us-east-1a)"
Write-Host "  private-subnet-b: $PRI_SUBNET_B (us-east-1b)"
Write-Host ""

Write-Host "Creating rds-subnet-group..." -ForegroundColor Yellow

aws rds create-db-subnet-group `
    --db-subnet-group-name rds-subnet-group `
    --db-subnet-group-description "Private subnets for RDS across two AZs" `
    --subnet-ids $PRI_SUBNET_A $PRI_SUBNET_B `
    --tags Key=Name,Value=rds-subnet-group | Out-Null

# Verify
Write-Host "Verifying subnet group..." -ForegroundColor Yellow
aws rds describe-db-subnet-groups `
    --db-subnet-group-name rds-subnet-group `
    --query "DBSubnetGroups[0].{Name:DBSubnetGroupName,VPC:VpcId,Status:SubnetGroupStatus,Subnets:Subnets[*].SubnetIdentifier}" `
    --output table

Write-Host ""
Write-Host "=== RDS Subnet Group Complete ===" -ForegroundColor Cyan
Write-Host "  Name:    rds-subnet-group"
Write-Host "  Subnets: $PRI_SUBNET_A, $PRI_SUBNET_B"
Write-Host "  AZs:     us-east-1a, us-east-1b"
Write-Host ""
Write-Host "Note: RDS requires subnet groups spanning 2+ AZs even for single-AZ instances."
Write-Host ""
Write-Host "Next step: Run 04-secrets-manager.ps1" -ForegroundColor Cyan