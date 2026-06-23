# Security Implementation

## Principle of Least Privilege

The database is not exposed to the public internet.

Only EC2 instances attached to ec2-app-sg can access RDS.

## Security Layers

1. Private Subnets
2. Security Group Chaining
3. Secrets Manager
4. IAM Role Permissions
5. Encrypted RDS Storage

## Secrets Management

Credentials are stored in:

rds/myapp/credentials

Access granted through:

secretsmanager:GetSecretValue