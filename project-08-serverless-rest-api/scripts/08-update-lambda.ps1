#Requires -Version 5.1
<#
.SYNOPSIS
Packages the local Python script and updates the deployed Lambda function code.
#>

Write-Host "Packaging Lambda function code..." -ForegroundColor Cyan
if (Test-Path "lambda\function.zip") {
    Remove-Item "lambda\function.zip" -Force
}

Compress-Archive `
  -Path lambda\lambda_function.py `
  -DestinationPath lambda\function.zip `
  -Force

Write-Host "Deploying code update to AWS..." -ForegroundColor Cyan
aws lambda update-function-code `
  --function-name users-api `
  --zip-file fileb://lambda/function.zip | Out-Null

Write-Host "Waiting for the update to complete..." -ForegroundColor Yellow
aws lambda wait function-updated --function-name users-api

Write-Host "Lambda updated successfully." -ForegroundColor Green