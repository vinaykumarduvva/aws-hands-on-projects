# Deployment Guide

This document provides the deployment steps for Project 09 in three formats: **AWS Management Console**, **Bash**, and **PowerShell**.

## Prerequisites
- AWS CLI v2 configured with `ap-south-1` as default region
- Git client installed (`git --version` ≥ 2.x)
- Python 3.x installed locally
- An existing EC2 key pair named `aws-ec2-keypair`

## PRE-FLIGHT
*(These commands are local verification steps. Choose your preferred terminal)*

### 🐧 Method 1: AWS CLI (Bash)
```bash
aws sts get-caller-identity
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo "Account ID: $ACCOUNT_ID"
aws configure get region
# Expected: ap-south-1

git --version
python --version
```

### 🪟 Method 2: AWS CLI (PowerShell)
```powershell
aws sts get-caller-identity
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
Write-Host "Account ID: $ACCOUNT_ID"
aws configure get region
# Expected: ap-south-1

git --version
python --version
```

---

## 🔑 PART 1 — CREATE IAM ROLES

We need four service roles: CodeBuild, CodeDeploy, CodePipeline, and EC2 instance profile.

### 🖥️ Method 1: AWS Management Console
1. **CodeBuild Role**
   - IAM Console → Roles → Create role
   - Trusted entity: **AWS service** → **CodeBuild**
   - Attach policies: `AWSCodeBuildAdminAccess`, `CloudWatchLogsFullAccess`, `AmazonS3FullAccess`, `AWSCodeCommitReadOnly`
   - Role name: `codebuild-service-role`

2. **CodeDeploy Role**
   - IAM Console → Roles → Create role
   - Trusted entity: **AWS service** → **CodeDeploy**
   - Attach policy: `AWSCodeDeployRole`
   - Role name: `codedeploy-service-role`

3. **CodePipeline Role**
   - IAM Console → Roles → Create role
   - Trusted entity: **AWS service** → **CodePipeline**
   - Attach policies: `AWSCodePipeline_FullAccess`, `AWSCodeCommitFullAccess`, `AWSCodeBuildAdminAccess`, `AWSCodeDeployFullAccess`, `AmazonS3FullAccess`
   - Role name: `codepipeline-service-role`

4. **EC2 Instance Role**
   - IAM Console → Roles → Create role
   - Trusted entity: **AWS service** → **EC2**
   - Attach policies: `AmazonSSMManagedInstanceCore`, `AmazonS3ReadOnlyAccess`
   - Role name: `ec2-codedeploy-role`
   - After creating the role, go to the role page → create an instance profile named `ec2-codedeploy-profile` and add this role to it.

### 🐧 Method 2: AWS CLI (Bash)
```bash
# See scripts/bash/01-create-iam-roles.sh for full script
# Creates all 4 roles with trust policies and attaches managed policies
# Also creates the ec2-codedeploy-profile instance profile
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# See scripts/powershell/01-create-iam-roles.ps1 for full script
# Creates all 4 roles with trust policies and attaches managed policies
# Also creates the ec2-codedeploy-profile instance profile
```

✅ **Checkpoint 1 complete** — all IAM roles created. Wait 15 seconds for IAM propagation.

---

## 📦 PART 2 — CREATE S3 ARTIFACT BUCKET

CodePipeline stores build artifacts in S3 between stages.

### 🖥️ Method 1: AWS Management Console
1. S3 Console → Create bucket
2. Bucket name: `codepipeline-artifacts-<ACCOUNT_ID>-ap-south-1`
3. Region: **Asia Pacific (Mumbai) ap-south-1**
4. Enable **Bucket Versioning**
5. Keep **Block all public access** enabled (default)
6. Click **Create bucket**

### 🐧 Method 2: AWS CLI (Bash)
```bash
# See scripts/bash/02-create-s3-bucket.sh for full script
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# See scripts/powershell/02-create-s3-bucket.ps1 for full script
```

✅ **Checkpoint 2 complete** — S3 artifact bucket ready with versioning enabled.

---

## 📁 PART 3 — CREATE CODECOMMIT REPOSITORY

### 🖥️ Method 1: AWS Management Console
1. CodeCommit Console → Create repository
2. Repository name: `my-web-app`
3. Description: `CI/CD demo app for Project 9`
4. Click **Create**
5. Copy the **HTTPS clone URL**

### 🐧 Method 2: AWS CLI (Bash)
```bash
# See scripts/bash/03-create-codecommit.sh for full script
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# See scripts/powershell/03-create-codecommit.ps1 for full script
```

✅ **Checkpoint 3 complete** — CodeCommit repository created.

---

## 🖥️ PART 4 — LAUNCH EC2 DEPLOYMENT TARGET

### 🖥️ Method 1: AWS Management Console
1. EC2 Console → Launch instance
2. Name: `cicd-deploy-server`
3. AMI: **Amazon Linux 2023** (latest)
4. Instance type: `t2.micro`
5. Key pair: `aws-ec2-keypair`
6. Security group: Create new → `cicd-deploy-sg`
   - SSH (22) from **My IP**
   - HTTP (80) from **Anywhere (0.0.0.0/0)**
7. IAM instance profile: `ec2-codedeploy-profile`
8. User data: paste the user data script from the project details (installs CodeDeploy agent + Apache)
9. Add tag: `Environment` = `production`
10. Launch instance

### 🐧 Method 2: AWS CLI (Bash)
```bash
# See scripts/bash/04-launch-ec2.sh for full script
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# See scripts/powershell/04-launch-ec2.ps1 for full script
```

✅ **Checkpoint 4 complete** — EC2 running with CodeDeploy agent installed.

---

## 🎯 PART 5 — CREATE CODEDEPLOY APPLICATION

### 🖥️ Method 1: AWS Management Console
1. CodeDeploy Console → Applications → Create application
2. Application name: `my-web-app`
3. Compute platform: **EC2/On-premises**
4. Click **Create application**
5. Click **Create deployment group**
   - Deployment group name: `production`
   - Service role: `codedeploy-service-role`
   - Deployment type: **In-place**
   - Environment configuration: **Amazon EC2 instances**
     - Key: `Environment`, Value: `production`
   - Deployment settings: `CodeDeployDefault.AllAtOnce`
   - Enable **Rollback when a deployment fails**

### 🐧 Method 2: AWS CLI (Bash)
```bash
# See scripts/bash/05-create-codedeploy.sh for full script
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# See scripts/powershell/05-create-codedeploy.ps1 for full script
```

✅ **Checkpoint 5 complete** — CodeDeploy application and deployment group configured.

---

## 🔨 PART 6 — CREATE CODEBUILD PROJECT

### 🖥️ Method 1: AWS Management Console
1. CodeBuild Console → Create build project
2. Project name: `my-web-app-build`
3. Source: **AWS CodeCommit** → Repository: `my-web-app`
4. Environment:
   - Managed image → **Amazon Linux**
   - Runtime: **Standard**
   - Image: `aws/codebuild/standard:7.0`
   - Service role: `codebuild-service-role`
5. Buildspec: **Use a buildspec file** (uses `buildspec.yml` from repo root)
6. Artifacts: **Amazon S3** → Bucket: your artifact bucket
7. Logs: Enable **CloudWatch logs** → Group: `/aws/codebuild/my-web-app-build`

### 🐧 Method 2: AWS CLI (Bash)
```bash
# See scripts/bash/06-create-codebuild.sh for full script
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# See scripts/powershell/06-create-codebuild.ps1 for full script
```

✅ **Checkpoint 6 complete** — CodeBuild project created.

---

## 🔗 PART 7 — CREATE CODEPIPELINE

### 🖥️ Method 1: AWS Management Console
1. CodePipeline Console → Create pipeline
2. Pipeline settings:
   - Pipeline name: `my-web-app-pipeline`
   - Service role: `codepipeline-service-role`
   - Artifact store: **Custom location** → select your artifact bucket
3. Source stage:
   - Source provider: **AWS CodeCommit**
   - Repository name: `my-web-app`
   - Branch name: `main`
   - Detection option: **Amazon CloudWatch Events (recommended)**
4. Build stage:
   - Build provider: **AWS CodeBuild**
   - Region: `ap-south-1`
   - Project name: `my-web-app-build`
5. Deploy stage:
   - Deploy provider: **AWS CodeDeploy**
   - Region: `ap-south-1`
   - Application name: `my-web-app`
   - Deployment group: `production`
6. Click **Create pipeline** — the pipeline immediately triggers its first run.

### 🐧 Method 2: AWS CLI (Bash)
```bash
# See scripts/bash/07-create-codepipeline.sh for full script
# Creates pipeline definition JSON and passes it to aws codepipeline create-pipeline
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# See scripts/powershell/07-create-codepipeline.ps1 for full script
# Creates pipeline definition JSON and passes it to aws codepipeline create-pipeline
```

✅ **Checkpoint 7 complete** — Pipeline created and first execution running automatically.

---

## 📊 PART 8 — MONITOR PIPELINE EXECUTION

### CLI Monitoring
```powershell
# Watch pipeline status (run every 30 seconds)
aws codepipeline get-pipeline-state `
  --name my-web-app-pipeline `
  --query "stageStates[*].{Stage:stageName,Status:latestExecution.status}" `
  --output table
```

Expected progression:
```
Source  → InProgress → Succeeded
Build   → InProgress → Succeeded  (~2 minutes)
Deploy  → InProgress → Succeeded  (~1-2 minutes)
```

### Console Monitoring
- CodePipeline → `my-web-app-pipeline`
- Watch each stage: Source → Build → Deploy turning green
- Click any stage for detailed logs

### Verify Deployment
```powershell
Start-Process "http://<EC2_PUBLIC_IP>"
# Expected: CI/CD Demo App page with Version 1.0
```

✅ **Checkpoint 8 complete** — All stages green, application deployed.

---

## 🔄 PART 9 — TRIGGER A NEW DEPLOYMENT

This is the magic moment — change code, push, watch it deploy automatically:

```powershell
# Update version in index.html
(Get-Content index.html) -replace 'Version 1.0', 'Version 2.0' | Set-Content index.html

# Commit and push
git add index.html
git commit -m "feat: update to version 2.0"
git push origin main

# Pipeline triggers automatically — watch in console
# In ~3-4 minutes: http://<EC2_PUBLIC_IP> should show Version 2.0
```

✅ **Checkpoint 9 complete** — Automated deployment proven end-to-end.

---

## 🧹 PART 10 — CLEANUP

See the [Cleanup Guide](cleanup-guide.md) for full step-by-step cleanup instructions.

Run `scripts/powershell/10-cleanup.ps1` or `scripts/bash/10-cleanup.sh` to delete all resources.

✅ **Checkpoint 10 complete** — All resources deleted, $0.00 cost.