# Troubleshooting Guide

## MySQL Connection Refused

Cause:
- Security Group misconfiguration

Fix:
- Verify RDS SG allows 3306 from EC2 SG

## RDS Endpoint Not Resolving

Cause:
- DNS disabled in VPC

Fix:
- Enable DNS Hostnames
- Enable DNS Resolution

## Access Denied

Cause:
- Incorrect password

Fix:
- Verify Secrets Manager credentials

## Secrets Manager Access Denied

Cause:
- IAM role missing permissions

Fix:
- Attach Secrets Manager policy