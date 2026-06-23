# Project 06: AWS RDS MySQL + EC2 Two-Tier Architecture

## Overview

This project demonstrates a production-style two-tier architecture on AWS where an EC2 application server communicates with a managed MySQL database hosted on Amazon RDS.

The database is deployed in private subnets while the application server resides in a public subnet. Security Group chaining ensures that database access is restricted exclusively to the application server.

## Architecture

![Architecture](architecture/architecture-diagram.svg)

## AWS Services Used

- Amazon EC2
- Amazon RDS (MySQL)
- Amazon VPC
- Security Groups
- AWS Secrets Manager
- IAM
- CloudWatch

## Key Features

- Managed MySQL database using Amazon RDS
- Private subnet deployment
- Security Group chaining
- Automated backups
- Secrets Manager integration
- CloudWatch monitoring
- Manual snapshots
- Complete cleanup automation

## Architecture Flow

Internet
→ Internet Gateway
→ EC2 Application Server
→ Security Group
→ RDS MySQL Database

## Validation Steps

- Created VPC and networking resources
- Created Security Groups
- Created RDS Subnet Group
- Stored credentials in Secrets Manager
- Launched MySQL RDS instance
- Connected EC2 to RDS
- Created MySQL schema and tables
- Queried application data
- Monitored RDS using CloudWatch
- Created manual snapshots

## Sample Query

```sql
SELECT * FROM users;