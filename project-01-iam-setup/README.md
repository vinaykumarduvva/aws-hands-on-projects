# Project 1 — AWS Account Setup & IAM Foundations

## Overview
Secured an AWS account using IAM best practices: disabled root user for daily use,
enabled MFA, created a least-privilege IAM admin user, configured billing alerts,
and set up AWS CLI v2 on Windows.

## Architecture
Root Account (MFA secured)
    └── IAM User: admin-yourname (AdministratorAccess)
        └── AWS CLI v2 (Windows PowerShell)
CloudWatch Billing Alarm → SNS Topic → Email notification

## Prerequisites
- AWS account (free tier)
- Windows PC
- Smartphone (for MFA authenticator app)

## Setup Steps
1. Enable MFA on root account (Authenticator app)
2. Enable billing alerts in Billing Preferences
3. Create CloudWatch billing alarm at $5 threshold
4. Create IAM admin user with console + programmatic access
5. Install AWS CLI v2 on Windows
6. Run `aws configure` with IAM access keys
7. Verify with `aws sts get-caller-identity`

## Expected Output
```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/admin-yourname"
}
```

## Cost Estimate
$0.00 — IAM and billing alerts are always free.

## Known Issues
- Billing CloudWatch metrics only available in us-east-1 region

## Next Steps
- Project 2: Host a static website on S3 + CloudFront