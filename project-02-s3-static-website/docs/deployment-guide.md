# Deployment Guide

## Prerequisites
- AWS CLI
- Appropriate IAM permissions

## Steps
1. Create S3 bucket, disable block public access
2. Enable static website hosting (index.html / error.html)
3. Apply public read bucket policy
4. Upload files: `aws s3 sync ./website/ s3://BUCKET/`
5. Create CloudFront distribution pointing to S3 website endpoint
6. Set viewer protocol to redirect HTTP → HTTPS
7. Test HTTPS URL, then invalidate cache after updates

> [!TIP]
> Use the provided automation scripts in `scripts/powershell/` or `scripts/bash/` to deploy this instantly.