# =============================================================================
# Project 8 — Script 03: Package Lambda Function
# Zips lambda_function.py into function.zip for deployment
# =============================================================================

Write-Host "=== Project 8 — Package Lambda ===" -ForegroundColor Cyan
Write-Host ""

# Verify source file exists
if (-not (Test-Path "lambda\lambda_function.py")) {
    Write-Host "ERROR: lambda\lambda_function.py not found." -ForegroundColor Red
    Write-Host "Ensure you are running this from the project root directory."
    Write-Host "Expected: project-08-serverless-rest-api\"
    exit 1
}

Write-Host "Source file: lambda\lambda_function.py" -ForegroundColor Yellow
Write-Host "Output:      lambda\function.zip"
Write-Host ""

# Remove old zip if exists
if (Test-Path "lambda\function.zip") {
    Remove-Item "lambda\function.zip"
    Write-Host "Removed existing function.zip"
}

# Package
Compress-Archive `
  -Path lambda\lambda_function.py `
  -DestinationPath lambda\function.zip

# Verify
$ZIP = Get-Item "lambda\function.zip"
Write-Host ""
Write-Host "Package created successfully:" -ForegroundColor Green
Write-Host "  File:    $($ZIP.FullName)"
Write-Host "  Size:    $($ZIP.Length) bytes"
Write-Host ""

if ($ZIP.Length -lt 500) {
    Write-Host "WARNING: Zip file is very small. Verify lambda_function.py has content." -ForegroundColor Yellow
}

Write-Host "=== Package Complete ===" -ForegroundColor Cyan
Write-Host "Next step: Run 04-deploy-lambda.ps1" -ForegroundColor Cyan