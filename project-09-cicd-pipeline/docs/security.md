# Security — Project 9 CI/CD Pipeline

## Security Architecture Overview

```
IAM Boundaries:

codebuild-service-role         ← CodeBuild assumes this
  └── Can: S3 read/write, CloudWatch Logs, CodeBuild ops
  └── Cannot: access RDS, Lambda, modify IAM, EC2

codedeploy-service-role        ← CodeDeploy assumes this
  └── Can: EC2 describe, Auto Scaling ops, S3 read
  └── Cannot: delete EC2, modify network, IAM changes

codepipeline-service-role      ← CodePipeline assumes this
  └── Can: trigger CodeBuild/CodeDeploy, S3 R/W
  └── Cannot: direct EC2 access, IAM modification

ec2-codedeploy-role            ← EC2 instance assumes this
  └── Can: S3 read (artifact bucket), SSM operations
  └── Cannot: write to S3, CodeDeploy API, IAM changes
```

---

## IAM Roles Deep Dive

### 1. codebuild-service-role

**Trust policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "codebuild.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
```
Only CodeBuild service can assume this role.

**Permissions:**
```
AWSCodeBuildAdminAccess      → Manage build projects and executions
CloudWatchLogsFullAccess     → Write build logs to CloudWatch
AmazonS3FullAccess           → Read source, write build artifacts
```

**Least privilege improvement for production:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:ap-south-1:ACCOUNT:log-group:/aws/codebuild/*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::codepipeline-artifacts-ACCOUNT-ap-south-1/*"
    },
    {
      "Effect": "Allow",
      "Action": ["codecommit:GitPull"],
      "Resource": "arn:aws:codecommit:ap-south-1:ACCOUNT:my-web-app"
    }
  ]
}
```

---

### 2. codedeploy-service-role

**Trust policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "codedeploy.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
```

**Permissions:**
```
AWSCodeDeployRole → EC2 describe, Auto Scaling, ELB, S3 read
                    Enough for EC2 deployments
```

**What AWSCodeDeployRole includes:**
```json
{
  "Effect": "Allow",
  "Action": [
    "ec2:Describe*",
    "autoscaling:CompleteLifecycleAction",
    "autoscaling:DeleteLifecycleHook",
    "autoscaling:DescribeAutoScalingGroups",
    "autoscaling:PutLifecycleHook",
    "autoscaling:RecordLifecycleActionHeartbeat",
    "s3:GetObject", "s3:GetObjectVersion",
    "s3:ListBucket"
  ],
  "Resource": "*"
}
```

---

### 3. codepipeline-service-role

**Trust policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "codepipeline.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
```

**Key permissions needed:**
```
codecommit:GetBranch         → Read source branch
codecommit:GetCommit         → Fetch commit details
codecommit:UploadArchive     → Store source in S3
codebuild:BatchGetBuilds     → Check build status
codebuild:StartBuild         → Trigger build
codedeploy:CreateDeployment  → Trigger deployment
codedeploy:GetDeployment     → Monitor deployment
s3:GetObject                 → Read artifacts
s3:PutObject                 → Write artifacts
```

---

### 4. ec2-codedeploy-role (Instance Profile)

**Trust policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
```

**Permissions:**
```
AmazonSSMManagedInstanceCore → Session Manager access (no SSH needed)
AmazonS3ReadOnlyAccess       → Download deployment artifacts from S3
```

**Why S3 read is needed on EC2:**
```
CodeDeploy agent on EC2:
  1. Receives deployment notification from CodeDeploy service
  2. Gets S3 URL of BuildOutput.zip
  3. Downloads artifact directly from S3
  4. Extracts and runs hooks
  → Needs S3 read permission on its own IAM role
```

---

## S3 Artifact Bucket Security

```powershell
# Bucket created with:
aws s3api put-public-access-block `
  --bucket $ARTIFACT_BUCKET `
  --public-access-block-configuration `
  "BlockPublicAcls=true,IgnorePublicAcls=true,
   BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

**Security controls applied:**
- ✅ Block all public access — no public URLs
- ✅ Versioning enabled — artifact history preserved
- ✅ Server-side encryption (SSE-S3) — default for S3
- ✅ Access via IAM roles only — no access keys

**Who can access the artifact bucket:**
| Role | Access Level |
|---|---|
| codebuild-service-role | Read + Write |
| codepipeline-service-role | Read + Write |
| ec2-codedeploy-role | Read only |
| Your IAM user (admin) | Full access |
| Public internet | ❌ Blocked |

---

## CodeCommit Security

```
Repository: my-web-app
Access control: IAM policies

Who can push:
  → Your admin IAM user (via credential helper)
  → No other users

Who can pull:
  → CodePipeline (via codepipeline-service-role)
  → CodeBuild (via codebuild-service-role)

Authentication method: AWS credential helper
  → Uses your IAM credentials (no separate Git password)
  → Credentials automatically rotated by AWS
  → No long-term Git passwords stored
```

**Git credential helper configuration:**
```
git config --global credential.helper "!aws codecommit credential-helper $@"
git config --global credential.UseHttpPath true
```

This uses your IAM credentials (STS tokens) instead of
a username/password — much more secure.

---

## EC2 Security

```
cicd-deploy-server security group: cicd-deploy-sg

Inbound rules:
  Port 22 (SSH)  → MY_IP/32 only
                   Only your specific public IP can SSH
                   (not 0.0.0.0/0 which would be world-open)

  Port 80 (HTTP) → 0.0.0.0/0
                   Website must be publicly accessible
                   HTTPS upgrade: use ALB + ACM (future project)

Outbound rules:
  All traffic → 0.0.0.0/0
  Needed for: yum updates, S3 artifact download, CodeDeploy polling
```

**Why no port 443 inbound?**
Our demo uses HTTP. Production should use HTTPS via ALB + ACM.
That pattern is covered in Project 10 (ASG + ALB).

---

## Security Best Practices Applied

| Practice | Implementation |
|---|---|
| No hardcoded credentials | Git credential helper uses IAM tokens |
| Least privilege roles | Each service role has only needed permissions |
| Private artifact storage | S3 bucket has all public access blocked |
| Instance profile not access keys | EC2 uses IAM role (auto-rotating temp creds) |
| SSH restricted to My IP | Port 22 not open to 0.0.0.0/0 |
| Service-specific trust policies | Each role only trusted by its own service |

---

## Security Improvements for Production

| Gap | Current | Production Fix |
|---|---|---|
| Overly broad managed policies | AWSCodeBuildAdminAccess | Custom policy scoped to specific resources |
| HTTP only | Port 80 open | Add ALB + ACM SSL certificate |
| Single deployment environment | One EC2 | Separate dev/staging/production accounts |
| No approval gate | Auto-deploys everything | Manual approval stage in CodePipeline |
| Secrets in buildspec | None in this project | Use Secrets Manager / Parameter Store |
| No code signing | Not implemented | Use CodeArtifact with signing |
| S3 encryption | SSE-S3 (AWS key) | SSE-KMS with customer-managed key |

---

## Secrets and Sensitive Values

In this project there are NO secrets in the pipeline.
Our application is a static HTML file.

For real applications that need secrets (DB passwords, API keys):

```yaml
# buildspec.yml — fetch from Parameter Store (DO NOT hardcode)
env:
  parameter-store:
    DB_PASSWORD: /myapp/production/db-password
    API_KEY: /myapp/production/api-key

phases:
  build:
    commands:
      - echo "Using DB_PASSWORD from Parameter Store"
      - # $DB_PASSWORD is now available as env variable
```

```yaml
# NEVER do this in buildspec.yml:
env:
  variables:
    DB_PASSWORD: "MyActualPassword123"  # ← VISIBLE IN LOGS
```

---

## CloudTrail Audit Trail

Every API call in this pipeline is logged in CloudTrail:

```
codepipeline:StartPipelineExecution  → pipeline triggered
codebuild:StartBuild                 → build started
s3:PutObject                         → artifact stored
codedeploy:CreateDeployment          → deployment started
ec2:DescribeInstances               → CodeDeploy finding targets
```

To query pipeline events in CloudTrail:
```powershell
aws cloudtrail lookup-events `
  --lookup-attributes AttributeKey=EventSource,AttributeValue=codepipeline.amazonaws.com `
  --start-time (Get-Date).AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ssZ") `
  --query "Events[*].{Time:EventTime,Name:EventName,User:Username}" `
  --output table
```