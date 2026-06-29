# Deployment Guide

## Automated Scripts Available
> [!TIP]
> **Dual-Platform Execution:** This project contains fully automated deployment and teardown scripts for both Windows (PowerShell) and Linux/macOS (Bash). Check the `scripts/` directory for `.ps1` files and the `bash-scripts/` directory for `.sh` files.

## Setup Steps
1. Enable MFA on root account (Authenticator app)
2. Enable billing alerts in Billing Preferences
3. Create CloudWatch billing alarm at $5 threshold
4. Create IAM admin user with console + programmatic access
5. Install AWS CLI v2 on Windows
6. Run `aws configure` with IAM access keys
7. Verify with `aws sts get-caller-identity`

