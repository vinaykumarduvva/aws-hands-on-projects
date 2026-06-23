# =============================================================================
# Project 6 — Script 04: Secrets Manager
# Stores RDS credentials securely — never hardcode passwords in scripts or code
# =============================================================================

Write-Host "=== Project 6 — Secrets Manager ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Storing RDS credentials in AWS Secrets Manager..." -ForegroundColor Yellow
Write-Host "Secret path: rds/myapp/credentials"
Write-Host ""

# Store credentials as a JSON object
# NOTE: Update the password here if you used something different during RDS creation
$SECRET_ARN = aws secretsmanager create-secret `
    --name "rds/myapp/credentials" `
    --description "RDS MySQL admin credentials for Project 6" `
    --secret-string '{
    "username": "appadmin",
    "password": "[PASSWORD]",
    "engine": "mysql",
    "port": 3306,
    "dbname": "appdb"
  }' `
    --query "ARN" --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "Secret may already exist. Checking..." -ForegroundColor Yellow

    $SECRET_ARN = aws secretsmanager describe-secret `
        --secret-id "rds/myapp/credentials" `
        --query "ARN" --output text

    Write-Host "Existing secret found: $SECRET_ARN" -ForegroundColor Yellow
}
else {
    Write-Host "Secret created: $SECRET_ARN" -ForegroundColor Green
}

# Verify
Write-Host ""
Write-Host "Verifying secret..." -ForegroundColor Yellow
