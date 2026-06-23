#Requires -Version 5.1
<#
.SYNOPSIS
Empties and deletes the S3 bucket.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$BucketName
)

Write-Host "Emptying bucket $BucketName..." -ForegroundColor Yellow
aws s3 rm s3://$BucketName --recursive

Write-Host "Deleting bucket $BucketName..." -ForegroundColor Yellow
aws s3api delete-bucket --bucket $BucketName --region us-east-1

Write-Host "Bucket cleanup complete. Remember to disable and delete your CloudFront distribution in the console." -ForegroundColor Green
