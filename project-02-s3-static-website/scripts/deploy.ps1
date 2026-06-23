#Requires -Version 5.1
<#
.SYNOPSIS
Syncs local HTML files to the designated S3 bucket.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$BucketName
)

$SourcePath = "..\website\"

Write-Host "Syncing files to S3 bucket: $BucketName..." -ForegroundColor Cyan
aws s3 sync $SourcePath s3://$BucketName/ --region us-east-1

Write-Host "Deployment complete." -ForegroundColor Green
