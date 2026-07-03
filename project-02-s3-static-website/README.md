# Project 2 — Static Website on S3 + CloudFront

## Overview
Hosted a static portfolio website on Amazon S3 with CloudFront as a global CDN,
enabling HTTPS delivery from 400+ edge locations worldwide at near-zero cost.

## Architecture
```
Browser → CloudFront (HTTPS, CDN) → S3 Bucket (origin, HTTP)
```

## Services Used
- Amazon S3 — static file storage and website hosting
- Amazon CloudFront — CDN, SSL termination, caching
- AWS CLI v2 — file sync and cache invalidation

## Live URL
S3 static website: https://aws-sample-webiste-2026.s3.ap-south-1.amazonaws.com/index.html

CloudFront: https://d2qfvpm2acd8sv.cloudfront.net/

## Setup Steps
1. Create S3 bucket, disable block public access
2. Enable static website hosting (index.html / error.html)
3. Apply public read bucket policy
4. Upload files: `aws s3 sync ./website/ s3://BUCKET/`
5. Create CloudFront distribution pointing to S3 website endpoint
6. Set viewer protocol to redirect HTTP → HTTPS
7. Test HTTPS URL, then invalidate cache after updates

## Key Commands
```powershell
# Upload files
aws s3 sync .\website\ s3://YOUR-BUCKET/ --region us-east-1

# Invalidate cache
aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"

# Check files in bucket
aws s3 ls s3://YOUR-BUCKET/
```

## Cost Estimate
$0.00 — S3 and CloudFront both within Free Tier limits for this project.

## Cleanup
1. Disable and delete CloudFront distribution
2. `aws s3 rm s3://YOUR-BUCKET --recursive`
3. `aws s3api delete-bucket --bucket YOUR-BUCKET --region us-east-1`

## Next Steps
- Add a custom domain with Route 53
- Add a contact form using API Gateway + Lambda (Project 8)
- Automate deploys with CodePipeline (Project 9)
