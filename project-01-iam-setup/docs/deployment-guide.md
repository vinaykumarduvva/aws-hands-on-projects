# Deployment Guide

## Prerequisites
- AWS CLI
- Appropriate IAM permissions

## Steps
1. Enable MFA on root account (Authenticator app)
2. Enable billing alerts in Billing Preferences
3. Create CloudWatch billing alarm at $5 threshold
4. Create IAM admin user with console + programmatic access
5. Install AWS CLI v2 on Windows
6. Run `aws configure` with IAM access keys
7. Verify with `aws sts get-caller-identity`

> [!TIP]
> Use the provided automation scripts in `scripts/powershell/` or `scripts/bash/` to deploy this instantly.