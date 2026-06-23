#Requires -Version 5.1
<#
.SYNOPSIS
Invalidates the CloudFront cache to force edge locations to fetch new S3 files.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$DistributionId
)

Write-Host "Requesting cache invalidation for distribution: $DistributionId..." -ForegroundColor Cyan
aws cloudfront create-invalidation --distribution-id $DistributionId --paths "/*"

Write-Host "Invalidation requested. It will take a few moments to propagate." -ForegroundColor Green
