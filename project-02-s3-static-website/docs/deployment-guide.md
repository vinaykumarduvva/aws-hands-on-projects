# Deployment Guide

## Automated Scripts Available
> [!TIP]
> **Dual-Platform Execution:** This project contains fully automated deployment and teardown scripts for both Windows (PowerShell) and Linux/macOS (Bash). Check the `scripts/` directory for `.ps1` files and the `bash-scripts/` directory for `.sh` files.

## Setup Steps
1. Create S3 bucket, disable block public access
2. Enable static website hosting (index.html / error.html)
3. Apply public read bucket policy
4. Upload files: `aws s3 sync ./website/ s3://BUCKET/`
5. Create CloudFront distribution pointing to S3 website endpoint
6. Set viewer protocol to redirect HTTP → HTTPS
7. Test HTTPS URL, then invalidate cache after updates

## Cleanup Guide

## Cleanup
1. Disable and delete CloudFront distribution
2. `aws s3 rm s3://YOUR-BUCKET --recursive`
3. `aws s3api delete-bucket --bucket YOUR-BUCKET --region us-east-1`

