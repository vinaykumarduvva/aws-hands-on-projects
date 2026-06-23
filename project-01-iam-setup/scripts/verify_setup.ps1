#Requires -Version 5.1
<#
.SYNOPSIS
Verifies the AWS CLI installation and IAM user configuration.
#>

Write-Host "Checking AWS CLI version..." -ForegroundColor Cyan
aws --version

if ($LASTEXITCODE -ne 0) {
    Write-Host "AWS CLI is not installed or not in the system PATH." -ForegroundColor Red
    exit 1
}

Write-Host "`nFetching caller identity to verify IAM configuration..." -ForegroundColor Cyan
$identity = aws sts get-caller-identity | ConvertFrom-Json

if ($null -ne $identity) {
    Write-Host "Success! You are authenticated." -ForegroundColor Green
    Write-Host "Account ID : $($identity.Account)"
    Write-Host "User ARN   : $($identity.Arn)"
} else {
    Write-Host "Failed to authenticate. Run 'aws configure' to set up your credentials." -ForegroundColor Red
}
