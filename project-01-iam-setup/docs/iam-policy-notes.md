# IAM Policy Notes

## What is an IAM Policy?
A JSON document that defines what actions are allowed or denied,
on which resources, and under what conditions.

## Policy Structure (every policy has these 4 parts)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":    "Allow" or "Deny",
      "Action":    "what API calls are permitted",
      "Resource":  "which AWS resources this applies to",
      "Condition": "optional - when this rule applies"
    }
  ]
}
```

## The 3 Types of Policies You'll Use Most

| Type | What it is | Example |
|---|---|---|
| AWS Managed | Pre-built by AWS, maintained by AWS | AdministratorAccess, ReadOnlyAccess |
| Customer Managed | You write and own it | Your custom S3 read-only policy |
| Inline | Attached directly to one user/role | One-off permissions, avoid these |

## Policies Created in This Project

### 1. AdministratorAccess (AWS Managed)
Attached to: admin-yourname
Effect: Allows ALL actions on ALL resources.
Use case: Your personal admin user only. Never attach this to an app or service.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
```
⚠️ This is the most powerful policy in AWS. Treat it like a master key.

### 2. S3 Read-Only (Mini Challenge — Customer Managed)
Attached to: s3-readonly user
Effect: Can list buckets and read objects, nothing else.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets",
        "s3:GetObject"
      ],
      "Resource": "*"
    }
  ]
}
```

## The Golden Rule: Least Privilege
Always grant the MINIMUM permissions needed to do the job.
- A Lambda function reading from S3? Give it s3:GetObject only.
- A developer deploying code? Give CodeDeploy permissions only.
- Never use AdministratorAccess for apps, services, or CI/CD pipelines.

## IAM Concepts Cheat Sheet

| Term | Meaning |
|---|---|
| User | A person. Has long-term credentials (password + access keys). |
| Group | A collection of users. Attach policies to groups, not individual users. |
| Role | An identity assumed temporarily by a service or person. No long-term keys. |
| Policy | The JSON document that defines permissions. |
| ARN | Amazon Resource Name — unique ID for every AWS resource. |
| MFA | Multi-Factor Authentication. Always enable on root + admin users. |

## ARN Format
arn:aws:SERVICE:REGION:ACCOUNT-ID:RESOURCE
Example: arn:aws:iam::123456789012:user/admin-raj
         arn:aws:s3:::my-bucket-name
         arn:aws:ec2:us-east-1:123456789012:instance/i-0abc123

## Policies I Will Add Here as Projects Progress
- Project 2: S3 bucket policy for static website hosting
- Project 3: EC2 instance profile role
- Project 5: VPC Flow Logs role
- Project 6: RDS access policy
- Project 8: Lambda execution role
- Project 9: CodePipeline service role
...and so on.

## Common Mistakes to Avoid
- ❌ Storing access keys in code or committing them to GitHub
- ❌ Using root user for day-to-day work
- ❌ Giving AdministratorAccess to Lambda functions or EC2 instances
- ❌ Creating users with no MFA for console access
- ✅ Use roles for services (EC2, Lambda) — never access keys
- ✅ Use groups to manage permissions at scale
- ✅ Review IAM Access Analyzer regularly for unused permissions