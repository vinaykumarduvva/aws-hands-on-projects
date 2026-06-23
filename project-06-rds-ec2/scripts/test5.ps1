aws secretsmanager describe-secret `
    --secret-id "rds/myapp/credentials" `
    --query "{Name:Name,ARN:ARN,Created:CreatedDate}" `
    --output table

Write-Host ""
Write-Host "=== Secrets Manager Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  SECRET_ARN = $SECRET_ARN"
Write-Host ""
Write-Host "Password rules applied:"
Write-Host "  8+ chars, uppercase + lowercase + numbers + special chars"
Write-Host '  No @ / " or \ characters (break MySQL connection strings)'
Write-Host ""
