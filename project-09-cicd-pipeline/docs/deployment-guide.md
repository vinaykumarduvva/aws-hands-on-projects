# Comprehensive Deployment Guide

This guide details the complete process for deploying this project's resources.

## 🏗️ PART 1 — CREATE IAM ROLES FOR CODEBUILD, CODEDEPLOY, CODEPIPELINE, EC2

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **EC2** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 9 — Script 01: Create IAM Roles
# Creates service roles for CodeBuild, CodeDeploy, CodePipeline, and EC2
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 9 — Create IAM Roles ===\e[0m"
echo ""

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo "Account ID: $ACCOUNT_ID"
echo ""

# ── HELPER: CREATE ROLE ───────────────────────────────────────────────────────
create_service_role() {
    local ROLE_NAME=$1
    local SERVICE_PRINCIPAL=$2
    echo -e "\e[33m  Creating role: $ROLE_NAME (principal: $SERVICE_PRINCIPAL)...\e[0m"
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document "{
        \"Version\":\"2012-10-17\",
        \"Statement\":[{
          \"Effect\":\"Allow\",
          \"Principal\":{\"Service\":\"$SERVICE_PRINCIPAL\"},
          \"Action\":\"sts:AssumeRole\"
        }]
      }" > /dev/null 2>&1
    echo -e "\e[32m  Role created.\e[0m"
}

# ── 1: CODEBUILD SERVICE ROLE ─────────────────────────────────────────────────
echo -e "\e[33m[1/4] CodeBuild service role...\e[0m"
create_service_role "codebuild-service-role" "codebuild.amazonaws.com"

aws iam attach-role-policy --role-name codebuild-service-role \
    --policy-arn arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess
aws iam attach-role-policy --role-name codebuild-service-role \
    --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
aws iam attach-role-policy --role-name codebuild-service-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam attach-role-policy --role-name codebuild-service-role \
    --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitReadOnly
echo -e "\e[32m  Policies attached.\e[0m"

# ── 2: CODEDEPLOY SERVICE ROLE ────────────────────────────────────────────────
echo -e "\e[33m[2/4] CodeDeploy service role...\e[0m"
create_service_role "codedeploy-service-role" "codedeploy.amazonaws.com"

aws iam attach-role-policy --role-name codedeploy-service-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole
echo -e "\e[32m  Policies attached.\e[0m"

# ── 3: CODEPIPELINE SERVICE ROLE ──────────────────────────────────────────────
echo -e "\e[33m[3/4] CodePipeline service role...\e[0m"
create_service_role "codepipeline-service-role" "codepipeline.amazonaws.com"

aws iam attach-role-policy --role-name codepipeline-service-role \
    --policy-arn arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess
aws iam attach-role-policy --role-name codepipeline-service-role \
    --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitFullAccess
aws iam attach-role-policy --role-name codepipeline-service-role \
    --policy-arn arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess
aws iam attach-role-policy --role-name codepipeline-service-role \
    --policy-arn arn:aws:iam::aws:policy/AWSCodeDeployFullAccess
aws iam attach-role-policy --role-name codepipeline-service-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
echo -e "\e[32m  Policies attached.\e[0m"

# ── 4: EC2 CODEDEPLOY ROLE ────────────────────────────────────────────────────
echo -e "\e[33m[4/4] EC2 CodeDeploy instance role...\e[0m"
create_service_role "ec2-codedeploy-role" "ec2.amazonaws.com"

aws iam attach-role-policy --role-name ec2-codedeploy-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam attach-role-policy --role-name ec2-codedeploy-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

aws iam create-instance-profile \
    --instance-profile-name ec2-codedeploy-profile > /dev/null 2>&1
aws iam add-role-to-instance-profile \
    --instance-profile-name ec2-codedeploy-profile \
    --role-name ec2-codedeploy-role
echo -e "\e[32m  Instance profile created and role attached.\e[0m"

# ── FETCH ARNS ────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mFetching role ARNs...\e[0m"

CODEBUILD_ROLE_ARN=$(aws iam get-role --role-name codebuild-service-role  --query "Role.Arn" --output text)
CODEDEPLOY_ROLE_ARN=$(aws iam get-role --role-name codedeploy-service-role --query "Role.Arn" --output text)
PIPELINE_ROLE_ARN=$(aws iam get-role --role-name codepipeline-service-role --query "Role.Arn" --output text)

echo ""
echo -e "\e[36m=== IAM Roles Complete ===\e[0m"
echo "  CODEBUILD_ROLE_ARN:  $CODEBUILD_ROLE_ARN"
echo "  CODEDEPLOY_ROLE_ARN: $CODEDEPLOY_ROLE_ARN"
echo "  PIPELINE_ROLE_ARN:   $PIPELINE_ROLE_ARN"
echo ""
echo -e "\e[33mWaiting 15 seconds for IAM propagation...\e[0m"
sleep 15
echo -e "\e[36mNext step: Run 02-create-s3-bucket.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 9 — Script 01: Create IAM Roles
# Creates service roles for CodeBuild, CodeDeploy, CodePipeline, and EC2
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 9 — Create IAM Roles ===" -ForegroundColor Cyan
Write-Host ""

$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
Write-Host "Account ID: $ACCOUNT_ID"
Write-Host ""

# ── HELPER: CREATE ROLE ───────────────────────────────────────────────────────
function New-ServiceRole {
    param([string]$RoleName, [string]$ServicePrincipal)
    Write-Host "  Creating role: $RoleName (principal: $ServicePrincipal)..." -ForegroundColor Yellow
    aws iam create-role `
        --role-name $RoleName `
        --assume-role-policy-document "{
        `"Version`":`"2012-10-17`",
        `"Statement`":[{
          `"Effect`":`"Allow`",
          `"Principal`":{`"Service`":`"$ServicePrincipal`"},
          `"Action`":`"sts:AssumeRole`"
        }]
      }" | Out-Null
    Write-Host "  Role created." -ForegroundColor Green
}

# ── 1: CODEBUILD SERVICE ROLE ─────────────────────────────────────────────────
Write-Host "[1/4] CodeBuild service role..." -ForegroundColor Yellow
New-ServiceRole -RoleName "codebuild-service-role" -ServicePrincipal "codebuild.amazonaws.com"

aws iam attach-role-policy --role-name codebuild-service-role `
    --policy-arn arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess
aws iam attach-role-policy --role-name codebuild-service-role `
    --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
aws iam attach-role-policy --role-name codebuild-service-role `
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam attach-role-policy --role-name codebuild-service-role `
    --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitReadOnly
Write-Host "  Policies attached." -ForegroundColor Green

# ── 2: CODEDEPLOY SERVICE ROLE ────────────────────────────────────────────────
Write-Host "[2/4] CodeDeploy service role..." -ForegroundColor Yellow
New-ServiceRole -RoleName "codedeploy-service-role" -ServicePrincipal "codedeploy.amazonaws.com"

aws iam attach-role-policy --role-name codedeploy-service-role `
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole
Write-Host "  Policies attached." -ForegroundColor Green

# ── 3: CODEPIPELINE SERVICE ROLE ──────────────────────────────────────────────
Write-Host "[3/4] CodePipeline service role..." -ForegroundColor Yellow
New-ServiceRole -RoleName "codepipeline-service-role" -ServicePrincipal "codepipeline.amazonaws.com"

aws iam attach-role-policy --role-name codepipeline-service-role `
    --policy-arn arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess
aws iam attach-role-policy --role-name codepipeline-service-role `
    --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitFullAccess
aws iam attach-role-policy --role-name codepipeline-service-role `
    --policy-arn arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess
aws iam attach-role-policy --role-name codepipeline-service-role `
    --policy-arn arn:aws:iam::aws:policy/AWSCodeDeployFullAccess
aws iam attach-role-policy --role-name codepipeline-service-role `
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
Write-Host "  Policies attached." -ForegroundColor Green

# ── 4: EC2 CODEDEPLOY ROLE ────────────────────────────────────────────────────
Write-Host "[4/4] EC2 CodeDeploy instance role..." -ForegroundColor Yellow
New-ServiceRole -RoleName "ec2-codedeploy-role" -ServicePrincipal "ec2.amazonaws.com"

aws iam attach-role-policy --role-name ec2-codedeploy-role `
    --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam attach-role-policy --role-name ec2-codedeploy-role `
    --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

aws iam create-instance-profile `
    --instance-profile-name ec2-codedeploy-profile | Out-Null
aws iam add-role-to-instance-profile `
    --instance-profile-name ec2-codedeploy-profile `
    --role-name ec2-codedeploy-role
Write-Host "  Instance profile created and role attached." -ForegroundColor Green

# ── FETCH ARNS ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Fetching role ARNs..." -ForegroundColor Yellow

$CODEBUILD_ROLE_ARN = aws iam get-role --role-name codebuild-service-role  --query "Role.Arn" --output text
$CODEDEPLOY_ROLE_ARN = aws iam get-role --role-name codedeploy-service-role --query "Role.Arn" --output text
$PIPELINE_ROLE_ARN = aws iam get-role --role-name codepipeline-service-role --query "Role.Arn" --output text

Write-Host ""
Write-Host "=== IAM Roles Complete ===" -ForegroundColor Cyan
Write-Host "  CODEBUILD_ROLE_ARN:  $CODEBUILD_ROLE_ARN"
Write-Host "  CODEDEPLOY_ROLE_ARN: $CODEDEPLOY_ROLE_ARN"
Write-Host "  PIPELINE_ROLE_ARN:   $PIPELINE_ROLE_ARN"
Write-Host ""
Write-Host "Waiting 15 seconds for IAM propagation..." -ForegroundColor Yellow
Start-Sleep -Seconds 15
Write-Host "Next step: Run 02-create-s3-bucket.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 2 — CREATE S3 ARTIFACT BUCKET WITH VERSIONING ENABLED

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **S3** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 9 — Script 02: Create S3 Artifact Bucket
# CodePipeline stores build artifacts between stages in this bucket
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 9 — Create S3 Artifact Bucket ===\e[0m"
echo ""

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
ARTIFACT_BUCKET="codepipeline-artifacts-$ACCOUNT_ID-ap-south-1"

echo -e "\e[33mBucket name: $ARTIFACT_BUCKET\e[0m"

# ── CREATE BUCKET ─────────────────────────────────────────────────────────────
echo -e "\e[33m[1/3] Creating bucket...\e[0m"
aws s3api create-bucket \
    --bucket $ARTIFACT_BUCKET \
    --region ap-south-1 \
    --create-bucket-configuration LocationConstraint=ap-south-1

echo -e "\e[32mBucket created.\e[0m"

# ── ENABLE VERSIONING ─────────────────────────────────────────────────────────
echo -e "\e[33m[2/3] Enabling versioning (required by CodePipeline)...\e[0m"
aws s3api put-bucket-versioning \
    --bucket $ARTIFACT_BUCKET \
    --versioning-configuration Status=Enabled
echo -e "\e[32mVersioning enabled.\e[0m"

# ── BLOCK PUBLIC ACCESS ───────────────────────────────────────────────────────
echo -e "\e[33m[3/3] Blocking all public access...\e[0m"
aws s3api put-public-access-block \
    --bucket $ARTIFACT_BUCKET \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo -e "\e[32mPublic access blocked.\e[0m"

# ── VERIFY ────────────────────────────────────────────────────────────────────
aws s3api get-bucket-versioning --bucket $ARTIFACT_BUCKET --query "Status" --output text

echo ""
echo -e "\e[36m=== S3 Bucket Complete ===\e[0m"
echo "  ARTIFACT_BUCKET = $ARTIFACT_BUCKET"
echo ""
echo -e "\e[36mNext step: Run 03-create-codecommit.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 9 — Script 02: Create S3 Artifact Bucket
# CodePipeline stores build artifacts between stages in this bucket
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 9 — Create S3 Artifact Bucket ===" -ForegroundColor Cyan
Write-Host ""

$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
$ARTIFACT_BUCKET = "codepipeline-artifacts-$ACCOUNT_ID-ap-south-1"

Write-Host "Bucket name: $ARTIFACT_BUCKET" -ForegroundColor Yellow

# ── CREATE BUCKET ─────────────────────────────────────────────────────────────
Write-Host "[1/3] Creating bucket..." -ForegroundColor Yellow
aws s3api create-bucket `
    --bucket $ARTIFACT_BUCKET `
    --region ap-south-1 `
    --create-bucket-configuration LocationConstraint=ap-south-1

Write-Host "Bucket created." -ForegroundColor Green

# ── ENABLE VERSIONING ─────────────────────────────────────────────────────────
Write-Host "[2/3] Enabling versioning (required by CodePipeline)..." -ForegroundColor Yellow
aws s3api put-bucket-versioning `
    --bucket $ARTIFACT_BUCKET `
    --versioning-configuration Status=Enabled
Write-Host "Versioning enabled." -ForegroundColor Green

# ── BLOCK PUBLIC ACCESS ───────────────────────────────────────────────────────
Write-Host "[3/3] Blocking all public access..." -ForegroundColor Yellow
aws s3api put-public-access-block `
    --bucket $ARTIFACT_BUCKET `
    --public-access-block-configuration `
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
Write-Host "Public access blocked." -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
aws s3api get-bucket-versioning --bucket $ARTIFACT_BUCKET --query "Status" --output text

Write-Host ""
Write-Host "=== S3 Bucket Complete ===" -ForegroundColor Cyan
Write-Host "  ARTIFACT_BUCKET = $ARTIFACT_BUCKET"
Write-Host ""
Write-Host "Next step: Run 03-create-codecommit.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 3 — CREATE CODECOMMIT REPOSITORY AND PUSH APPLICATION CODE

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **Developer Tools** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 9 — Script 03: Create CodeCommit Repository and Push Code
# Creates managed Git repo and configures local git to push to it
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 9 — Create CodeCommit Repository ===\e[0m"
echo ""

# ── CREATE REPOSITORY ─────────────────────────────────────────────────────────
echo -e "\e[33m[1/3] Creating CodeCommit repository: my-web-app...\e[0m"

aws codecommit create-repository \
    --repository-name my-web-app \
    --repository-description "CI/CD demo app for Project 9" \
    --tags Project=project-09-cicd \
    --region ap-south-1 > /dev/null 2>&1

echo -e "\e[32mRepository created.\e[0m"

# ── GET CLONE URL ─────────────────────────────────────────────────────────────
CLONE_URL=$(aws codecommit get-repository \
    --repository-name my-web-app \
    --query "repositoryMetadata.cloneUrlHttp" \
    --output text \
    --region ap-south-1)

echo -e "\e[32mClone URL: $CLONE_URL\e[0m"

# ── GIT CONFIGURATION ─────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[2/3] Configuring Git credential helper for CodeCommit...\e[0m"

git config --global credential.helper "!aws codecommit credential-helper \$@"
git config --global credential.UseHttpPath true

echo -e "\e[32mGit credential helper configured.\e[0m"

# ── INSTRUCTIONS FOR CODE PUSH ────────────────────────────────────────────────
echo ""
echo -e "\e[33m[3/3] Ready to push application code.\e[0m"
echo ""
echo -e "\e[36mRun these commands from your application directory:\e[0m"
echo ""
echo "  cd ~/my-web-app"
echo "  git init"
echo "  git checkout -b main"
echo "  # Copy application/ folder contents here"
echo "  git add ."
echo "  git commit -m 'feat: initial CI/CD demo app'"
echo "  git remote add origin $CLONE_URL"
echo "  git push -u origin main"
echo ""
echo "Or if using the application/ folder from this repo:"
echo "  cd application"
echo "  git init && git checkout -b main"
echo "  git add ."
echo "  git commit -m 'feat: initial CI/CD demo app'"
echo "  git remote add origin $CLONE_URL"
echo "  git push -u origin main"

# ── VERIFY AFTER PUSH ─────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mAfter pushing, verify with:\e[0m"
echo "  aws codecommit get-branch --repository-name my-web-app --branch-name main --region ap-south-1"

echo ""
echo -e "\e[36m=== CodeCommit Setup Complete ===\e[0m"
echo "  CLONE_URL = $CLONE_URL"
echo ""
echo -e "\e[36mNext step: Push your code, then run 04-launch-ec2.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 9 — Script 03: Create CodeCommit Repository and Push Code
# Creates managed Git repo and configures local git to push to it
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 9 — Create CodeCommit Repository ===" -ForegroundColor Cyan
Write-Host ""

# ── CREATE REPOSITORY ─────────────────────────────────────────────────────────
Write-Host "[1/3] Creating CodeCommit repository: my-web-app..." -ForegroundColor Yellow

aws codecommit create-repository `
    --repository-name my-web-app `
    --repository-description "CI/CD demo app for Project 9" `
    --tags Project=project-09-cicd `
    --region ap-south-1 | Out-Null

Write-Host "Repository created." -ForegroundColor Green

# ── GET CLONE URL ─────────────────────────────────────────────────────────────
$CLONE_URL = aws codecommit get-repository `
    --repository-name my-web-app `
    --query "repositoryMetadata.cloneUrlHttp" `
    --output text `
    --region ap-south-1

Write-Host "Clone URL: $CLONE_URL" -ForegroundColor Green

# ── GIT CONFIGURATION ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/3] Configuring Git credential helper for CodeCommit..." -ForegroundColor Yellow

git config --global credential.helper "!aws codecommit credential-helper `$@"
git config --global credential.UseHttpPath true

Write-Host "Git credential helper configured." -ForegroundColor Green

# ── INSTRUCTIONS FOR CODE PUSH ────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Ready to push application code." -ForegroundColor Yellow
Write-Host ""
Write-Host "Run these commands from your application directory:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  cd C:\Users\`$env:USERNAME\my-web-app"
Write-Host "  git init"
Write-Host "  git checkout -b main"
Write-Host "  # Copy application/ folder contents here"
Write-Host "  git add ."
Write-Host "  git commit -m `"feat: initial CI/CD demo app`""
Write-Host "  git remote add origin $CLONE_URL"
Write-Host "  git push -u origin main"
Write-Host ""
Write-Host "Or if using the application/ folder from this repo:"
Write-Host "  cd application"
Write-Host "  git init && git checkout -b main"
Write-Host "  git add ."
Write-Host "  git commit -m `"feat: initial CI/CD demo app`""
Write-Host "  git remote add origin $CLONE_URL"
Write-Host "  git push -u origin main"

# ── VERIFY AFTER PUSH ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "After pushing, verify with:" -ForegroundColor Yellow
Write-Host "  aws codecommit get-branch --repository-name my-web-app --branch-name main --region ap-south-1"

Write-Host ""
Write-Host "=== CodeCommit Setup Complete ===" -ForegroundColor Cyan
Write-Host "  CLONE_URL = $CLONE_URL"
Write-Host ""
Write-Host "Next step: Push your code, then run 04-launch-ec2.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 4 — LAUNCH EC2 WITH CODEDEPLOY AGENT AND APACHE HTTPD

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **EC2** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 9 — Script 04: Launch EC2 Deployment Target
# Launches t2.micro with CodeDeploy agent and Apache pre-installed
# Region: ap-south-1 — tagged Environment=production for CodeDeploy targeting
# =============================================================================

echo -e "\e[36m=== Project 9 — Launch EC2 Deployment Target ===\e[0m"
echo ""

# ── FIND AMI ──────────────────────────────────────────────────────────────────
echo -e "\e[33m[1/5] Finding latest Amazon Linux 2023 AMI in ap-south-1...\e[0m"
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
    --region ap-south-1 \
    --query "sort_by(Images,&CreationDate)[-1].ImageId" \
    --output text)
echo "AMI: $AMI_ID"

# ── DEFAULT VPC + SUBNET ──────────────────────────────────────────────────────
echo -e "\e[33m[2/5] Getting default VPC and subnet...\e[0m"
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --region ap-south-1 \
    --query "Vpcs[0].VpcId" --output text)

SUBNET_ID=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=defaultForAz,Values=true" \
    --region ap-south-1 \
    --query "Subnets[0].SubnetId" --output text)

echo "VPC: $VPC_ID  Subnet: $SUBNET_ID"

# ── SECURITY GROUP ────────────────────────────────────────────────────────────
echo -e "\e[33m[3/5] Creating security group...\e[0m"
MY_IP=$(curl -s https://checkip.amazonaws.com | tr -d '[:space:]')

DEPLOY_SG=$(aws ec2 create-security-group \
    --group-name cicd-deploy-sg \
    --description "CI/CD deployment target security group" \
    --vpc-id $VPC_ID \
    --region ap-south-1 \
    --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress --group-id $DEPLOY_SG \
    --protocol tcp --port 22 --cidr "$MY_IP/32" --region ap-south-1
aws ec2 authorize-security-group-ingress --group-id $DEPLOY_SG \
    --protocol tcp --port 80 --cidr "0.0.0.0/0" --region ap-south-1

echo "Security group: $DEPLOY_SG"

# ── USER DATA ─────────────────────────────────────────────────────────────────
echo -e "\e[33m[4/5] Preparing user data script...\e[0m"
cat > userdata-deploy.sh << 'USERDATA'
#!/bin/bash
yum update -y
yum install -y ruby wget httpd

# Install CodeDeploy agent for ap-south-1
cd /home/ec2-user
wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x ./install
./install auto

# Start services
systemctl start codedeploy-agent
systemctl enable codedeploy-agent
systemctl start httpd
systemctl enable httpd

# Placeholder page
echo '<html><body style="font-family:Arial;text-align:center;padding:60px;background:#f0f2f5">
<h1 style="color:#232f3e">Waiting for CI/CD deployment...</h1>
<p>CodeDeploy agent installed and ready</p>
<p style="color:#888">Region: ap-south-1</p>
</body></html>' > /var/www/html/index.html

echo "EC2 setup complete" > /tmp/setup-done.txt
USERDATA

# ── LAUNCH INSTANCE ───────────────────────────────────────────────────────────
echo -e "\e[33m[5/5] Launching EC2 instance...\e[0m"

DEPLOY_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --key-name aws-ec2-keypair \
    --subnet-id $SUBNET_ID \
    --security-group-ids $DEPLOY_SG \
    --iam-instance-profile Name=ec2-codedeploy-profile \
    --associate-public-ip-address \
    --user-data file://userdata-deploy.sh \
    --region ap-south-1 \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=cicd-deploy-server},{Key=Environment,Value=production}]" \
    --query "Instances[0].InstanceId" --output text)

echo -e "\e[32mInstance ID: $DEPLOY_INSTANCE_ID\e[0m"
echo -e "\e[33mWaiting for status checks (3-4 minutes for CodeDeploy agent install)...\e[0m"

aws ec2 wait instance-status-ok --instance-ids $DEPLOY_INSTANCE_ID --region ap-south-1
echo -e "\e[32mEC2 ready.\e[0m"

DEPLOY_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $DEPLOY_INSTANCE_ID \
    --region ap-south-1 \
    --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

echo ""
echo -e "\e[36m=== EC2 Launch Complete ===\e[0m"
echo "  DEPLOY_INSTANCE_ID = $DEPLOY_INSTANCE_ID"
echo "  DEPLOY_PUBLIC_IP   = $DEPLOY_PUBLIC_IP"
echo "  App URL:             http://$DEPLOY_PUBLIC_IP"
echo ""
echo "IMPORTANT: Tag Environment=production is set — CodeDeploy uses this to find instances"
echo ""
echo -e "\e[36mNext step: Run 05-create-codedeploy.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 9 — Script 04: Launch EC2 Deployment Target
# Launches t2.micro with CodeDeploy agent and Apache pre-installed
# Region: ap-south-1 — tagged Environment=production for CodeDeploy targeting
# =============================================================================

Write-Host "=== Project 9 — Launch EC2 Deployment Target ===" -ForegroundColor Cyan
Write-Host ""

# ── FIND AMI ──────────────────────────────────────────────────────────────────
Write-Host "[1/5] Finding latest Amazon Linux 2023 AMI in ap-south-1..." -ForegroundColor Yellow
$AMI_ID = aws ec2 describe-images `
    --owners amazon `
    --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" `
    --region ap-south-1 `
    --query "sort_by(Images,&CreationDate)[-1].ImageId" `
    --output text
Write-Host "AMI: $AMI_ID"

# ── DEFAULT VPC + SUBNET ──────────────────────────────────────────────────────
Write-Host "[2/5] Getting default VPC and subnet..." -ForegroundColor Yellow
$VPC_ID = aws ec2 describe-vpcs `
    --filters "Name=isDefault,Values=true" `
    --region ap-south-1 `
    --query "Vpcs[0].VpcId" --output text

$SUBNET_ID = aws ec2 describe-subnets `
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=defaultForAz,Values=true" `
    --region ap-south-1 `
    --query "Subnets[0].SubnetId" --output text

Write-Host "VPC: $VPC_ID  Subnet: $SUBNET_ID"

# ── SECURITY GROUP ────────────────────────────────────────────────────────────
Write-Host "[3/5] Creating security group..." -ForegroundColor Yellow
$MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" -UseBasicParsing).Content.Trim()

$DEPLOY_SG = aws ec2 create-security-group `
    --group-name cicd-deploy-sg `
    --description "CI/CD deployment target security group" `
    --vpc-id $VPC_ID `
    --region ap-south-1 `
    --query "GroupId" --output text

aws ec2 authorize-security-group-ingress --group-id $DEPLOY_SG `
    --protocol tcp --port 22 --cidr "$MY_IP/32" --region ap-south-1
aws ec2 authorize-security-group-ingress --group-id $DEPLOY_SG `
    --protocol tcp --port 80 --cidr "0.0.0.0/0" --region ap-south-1

Write-Host "Security group: $DEPLOY_SG"

# ── USER DATA ─────────────────────────────────────────────────────────────────
Write-Host "[4/5] Preparing user data script..." -ForegroundColor Yellow
$USER_DATA = @"
#!/bin/bash
yum update -y
yum install -y ruby wget httpd

# Install CodeDeploy agent for ap-south-1
cd /home/ec2-user
wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x ./install
./install auto

# Start services
systemctl start codedeploy-agent
systemctl enable codedeploy-agent
systemctl start httpd
systemctl enable httpd

# Placeholder page
echo '<html><body style="font-family:Arial;text-align:center;padding:60px;background:#f0f2f5">
<h1 style="color:#232f3e">Waiting for CI/CD deployment...</h1>
<p>CodeDeploy agent installed and ready</p>
<p style="color:#888">Region: ap-south-1</p>
</body></html>' > /var/www/html/index.html

echo "EC2 setup complete" > /tmp/setup-done.txt
"@

$USER_DATA | Out-File -FilePath "userdata-deploy.sh" -Encoding ascii

# ── LAUNCH INSTANCE ───────────────────────────────────────────────────────────
Write-Host "[5/5] Launching EC2 instance..." -ForegroundColor Yellow

$DEPLOY_INSTANCE_ID = aws ec2 run-instances `
    --image-id $AMI_ID `
    --instance-type t2.micro `
    --key-name aws-ec2-keypair `
    --subnet-id $SUBNET_ID `
    --security-group-ids $DEPLOY_SG `
    --iam-instance-profile Name=ec2-codedeploy-profile `
    --associate-public-ip-address `
    --user-data file://userdata-deploy.sh `
    --region ap-south-1 `
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=cicd-deploy-server},{Key=Environment,Value=production}]" `
    --query "Instances[0].InstanceId" --output text

Write-Host "Instance ID: $DEPLOY_INSTANCE_ID" -ForegroundColor Green
Write-Host "Waiting for status checks (3-4 minutes for CodeDeploy agent install)..." -ForegroundColor Yellow

aws ec2 wait instance-status-ok --instance-ids $DEPLOY_INSTANCE_ID --region ap-south-1
Write-Host "EC2 ready." -ForegroundColor Green

$DEPLOY_PUBLIC_IP = aws ec2 describe-instances `
    --instance-ids $DEPLOY_INSTANCE_ID `
    --region ap-south-1 `
    --query "Reservations[0].Instances[0].PublicIpAddress" --output text

Write-Host ""
Write-Host "=== EC2 Launch Complete ===" -ForegroundColor Cyan
Write-Host "  DEPLOY_INSTANCE_ID = $DEPLOY_INSTANCE_ID"
Write-Host "  DEPLOY_PUBLIC_IP   = $DEPLOY_PUBLIC_IP"
Write-Host "  App URL:             http://$DEPLOY_PUBLIC_IP"
Write-Host ""
Write-Host "IMPORTANT: Tag Environment=production is set — CodeDeploy uses this to find instances"
Write-Host ""
Write-Host "Next step: Run 05-create-codedeploy.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 5 — CREATE CODEDEPLOY APPLICATION AND DEPLOYMENT GROUP

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **Developer Tools** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 9 — Script 05: Create CodeDeploy Application and Deployment Group
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 9 — Create CodeDeploy ===\e[0m"
echo ""

if [ -z "$CODEDEPLOY_ROLE_ARN" ]; then
    CODEDEPLOY_ROLE_ARN=$(aws iam get-role \
        --role-name codedeploy-service-role \
        --query "Role.Arn" --output text)
fi
echo "CodeDeploy Role ARN: $CODEDEPLOY_ROLE_ARN"
echo ""

# ── CREATE APPLICATION ────────────────────────────────────────────────────────
echo -e "\e[33m[1/2] Creating CodeDeploy application: my-web-app...\e[0m"

aws deploy create-application \
    --application-name my-web-app \
    --compute-platform Server \
    --region ap-south-1

echo -e "\e[32mApplication created.\e[0m"

# ── CREATE DEPLOYMENT GROUP ───────────────────────────────────────────────────
echo -e "\e[33m[2/2] Creating deployment group: production...\e[0m"
echo "  Target filter: EC2 tag Environment=production"
echo "  Config: CodeDeployDefault.AllAtOnce"
echo "  Auto-rollback: enabled on DEPLOYMENT_FAILURE"
echo ""

aws deploy create-deployment-group \
    --application-name my-web-app \
    --deployment-group-name production \
    --service-role-arn $CODEDEPLOY_ROLE_ARN \
    --deployment-config-name CodeDeployDefault.AllAtOnce \
    --ec2-tag-filters Key=Environment, Value=production, Type=KEY_AND_VALUE \
    --auto-rollback-configuration "enabled=true,events=DEPLOYMENT_FAILURE" \
    --region ap-south-1

echo -e "\e[32mDeployment group created.\e[0m"

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mVerifying deployment group...\e[0m"
aws deploy get-deployment-group \
    --application-name my-web-app \
    --deployment-group-name production \
    --region ap-south-1 \
    --query "deploymentGroupInfo.{Name:deploymentGroupName,Config:deploymentConfigName,AutoRollback:autoRollbackConfiguration.enabled}" \
    --output table

echo ""
echo -e "\e[36m=== CodeDeploy Complete ===\e[0m"
echo ""
echo "Application:       my-web-app"
echo "Deployment group:  production"
echo "Target tag:        Environment=production"
echo ""
echo -e "\e[36mNext step: Run 06-create-codebuild.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 9 — Script 05: Create CodeDeploy Application and Deployment Group
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 9 — Create CodeDeploy ===" -ForegroundColor Cyan
Write-Host ""

if (-not $CODEDEPLOY_ROLE_ARN) {
    $CODEDEPLOY_ROLE_ARN = aws iam get-role `
        --role-name codedeploy-service-role `
        --query "Role.Arn" --output text
}
Write-Host "CodeDeploy Role ARN: $CODEDEPLOY_ROLE_ARN"
Write-Host ""

# ── CREATE APPLICATION ────────────────────────────────────────────────────────
Write-Host "[1/2] Creating CodeDeploy application: my-web-app..." -ForegroundColor Yellow

aws deploy create-application `
    --application-name my-web-app `
    --compute-platform Server `
    --region ap-south-1

Write-Host "Application created." -ForegroundColor Green

# ── CREATE DEPLOYMENT GROUP ───────────────────────────────────────────────────
Write-Host "[2/2] Creating deployment group: production..." -ForegroundColor Yellow
Write-Host "  Target filter: EC2 tag Environment=production"
Write-Host "  Config: CodeDeployDefault.AllAtOnce"
Write-Host "  Auto-rollback: enabled on DEPLOYMENT_FAILURE"
Write-Host ""

aws deploy create-deployment-group `
    --application-name my-web-app `
    --deployment-group-name production `
    --service-role-arn $CODEDEPLOY_ROLE_ARN `
    --deployment-config-name CodeDeployDefault.AllAtOnce `
    --ec2-tag-filters Key=Environment, Value=production, Type=KEY_AND_VALUE `
    --auto-rollback-configuration "enabled=true,events=DEPLOYMENT_FAILURE" `
    --region ap-south-1

Write-Host "Deployment group created." -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying deployment group..." -ForegroundColor Yellow
aws deploy get-deployment-group `
    --application-name my-web-app `
    --deployment-group-name production `
    --region ap-south-1 `
    --query "deploymentGroupInfo.{Name:deploymentGroupName,Config:deploymentConfigName,AutoRollback:autoRollbackConfiguration.enabled}" `
    --output table

Write-Host ""
Write-Host "=== CodeDeploy Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Application:       my-web-app"
Write-Host "Deployment group:  production"
Write-Host "Target tag:        Environment=production"
Write-Host ""
Write-Host "Next step: Run 06-create-codebuild.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 6 — CREATE CODEBUILD PROJECT LINKED TO CODECOMMIT

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **Developer Tools** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 9 — Script 06: Create CodeBuild Project
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 9 — Create CodeBuild Project ===\e[0m"
echo ""

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
ARTIFACT_BUCKET="codepipeline-artifacts-$ACCOUNT_ID-ap-south-1"

if [ -z "$CODEBUILD_ROLE_ARN" ]; then
    CODEBUILD_ROLE_ARN=$(aws iam get-role \
        --role-name codebuild-service-role \
        --query "Role.Arn" --output text)
fi

echo "CodeBuild Role ARN:  $CODEBUILD_ROLE_ARN"
echo "Artifact Bucket:     $ARTIFACT_BUCKET"
echo ""

echo -e "\e[33mCreating CodeBuild project: my-web-app-build...\e[0m"

aws codebuild create-project \
    --name my-web-app-build \
    --description "Build project for CI/CD demo — Project 9" \
    --source "type=CODECOMMIT,location=https://git-codecommit.ap-south-1.amazonaws.com/v1/repos/my-web-app,buildspec=buildspec.yml" \
    --artifacts "type=S3,location=$ARTIFACT_BUCKET,packaging=ZIP,name=my-web-app-build" \
    --environment "type=LINUX_CONTAINER,computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/standard:7.0" \
    --service-role $CODEBUILD_ROLE_ARN \
    --logs-config "cloudWatchLogs={status=ENABLED,groupName=/aws/codebuild/my-web-app-build}" \
    --region ap-south-1 > /dev/null 2>&1

echo -e "\e[32mCodeBuild project created.\e[0m"

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mVerifying project...\e[0m"
aws codebuild batch-get-projects \
    --names my-web-app-build \
    --region ap-south-1 \
    --query "projects[0].{Name:name,Environment:environment.image,Source:source.type,Artifacts:artifacts.type}" \
    --output table

echo ""
echo -e "\e[36m=== CodeBuild Complete ===\e[0m"
echo ""
echo "Project:    my-web-app-build"
echo "Source:     CodeCommit — my-web-app"
echo "Buildspec:  buildspec.yml (in repo root)"
echo "Artifacts:  S3 — $ARTIFACT_BUCKET"
echo "Logs:       /aws/codebuild/my-web-app-build"
echo ""
echo -e "\e[36mNext step: Run 07-create-codepipeline.sh\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 9 — Script 06: Create CodeBuild Project
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 9 — Create CodeBuild Project ===" -ForegroundColor Cyan
Write-Host ""

$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
$ARTIFACT_BUCKET = "codepipeline-artifacts-$ACCOUNT_ID-ap-south-1"

if (-not $CODEBUILD_ROLE_ARN) {
    $CODEBUILD_ROLE_ARN = aws iam get-role `
        --role-name codebuild-service-role `
        --query "Role.Arn" --output text
}

Write-Host "CodeBuild Role ARN:  $CODEBUILD_ROLE_ARN"
Write-Host "Artifact Bucket:     $ARTIFACT_BUCKET"
Write-Host ""

Write-Host "Creating CodeBuild project: my-web-app-build..." -ForegroundColor Yellow

aws codebuild create-project `
    --name my-web-app-build `
    --description "Build project for CI/CD demo — Project 9" `
    --source "type=CODECOMMIT,location=https://git-codecommit.ap-south-1.amazonaws.com/v1/repos/my-web-app,buildspec=buildspec.yml" `
    --artifacts "type=S3,location=$ARTIFACT_BUCKET,packaging=ZIP,name=my-web-app-build" `
    --environment "type=LINUX_CONTAINER,computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/standard:7.0" `
    --service-role $CODEBUILD_ROLE_ARN `
    --logs-config "cloudWatchLogs={status=ENABLED,groupName=/aws/codebuild/my-web-app-build}" `
    --region ap-south-1 | Out-Null

Write-Host "CodeBuild project created." -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying project..." -ForegroundColor Yellow
aws codebuild batch-get-projects `
    --names my-web-app-build `
    --region ap-south-1 `
    --query "projects[0].{Name:name,Environment:environment.image,Source:source.type,Artifacts:artifacts.type}" `
    --output table

Write-Host ""
Write-Host "=== CodeBuild Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Project:    my-web-app-build"
Write-Host "Source:     CodeCommit — my-web-app"
Write-Host "Buildspec:  buildspec.yml (in repo root)"
Write-Host "Artifacts:  S3 — $ARTIFACT_BUCKET"
Write-Host "Logs:       /aws/codebuild/my-web-app-build"
Write-Host ""
Write-Host "Next step: Run 07-create-codepipeline.ps1" -ForegroundColor Cyan
```

---

## 🏗️ PART 7 — CREATE CODEPIPELINE (SOURCE → BUILD → DEPLOY)

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **Developer Tools** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 9 — Script 07: Create CodePipeline
# Three-stage pipeline: Source (CodeCommit) → Build (CodeBuild) → Deploy (CodeDeploy)
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 9 — Create CodePipeline ===\e[0m"
echo ""

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
ARTIFACT_BUCKET="codepipeline-artifacts-$ACCOUNT_ID-ap-south-1"

if [ -z "$PIPELINE_ROLE_ARN" ]; then
    PIPELINE_ROLE_ARN=$(aws iam get-role \
        --role-name codepipeline-service-role \
        --query "Role.Arn" --output text)
fi

echo "Pipeline Role ARN: $PIPELINE_ROLE_ARN"
echo "Artifact Bucket:   $ARTIFACT_BUCKET"
echo ""
echo -e "\e[33mBuilding pipeline definition...\e[0m"

cat > pipeline-definition.json << EOF
{
  "name": "my-web-app-pipeline",
  "roleArn": "$PIPELINE_ROLE_ARN",
  "artifactStore": {
    "type": "S3",
    "location": "$ARTIFACT_BUCKET"
  },
  "stages": [
    {
      "name": "Source",
      "actions": [
        {
          "name": "Source",
          "actionTypeId": {
            "category": "Source",
            "owner": "AWS",
            "provider": "CodeCommit",
            "version": "1"
          },
          "configuration": {
            "RepositoryName": "my-web-app",
            "BranchName": "main",
            "PollForSourceChanges": "false"
          },
          "outputArtifacts": [{"name": "SourceOutput"}],
          "region": "ap-south-1"
        }
      ]
    },
    {
      "name": "Build",
      "actions": [
        {
          "name": "Build",
          "actionTypeId": {
            "category": "Build",
            "owner": "AWS",
            "provider": "CodeBuild",
            "version": "1"
          },
          "configuration": {
            "ProjectName": "my-web-app-build"
          },
          "inputArtifacts": [{"name": "SourceOutput"}],
          "outputArtifacts": [{"name": "BuildOutput"}],
          "region": "ap-south-1"
        }
      ]
    },
    {
      "name": "Deploy",
      "actions": [
        {
          "name": "Deploy",
          "actionTypeId": {
            "category": "Deploy",
            "owner": "AWS",
            "provider": "CodeDeploy",
            "version": "1"
          },
          "configuration": {
            "ApplicationName": "my-web-app",
            "DeploymentGroupName": "production"
          },
          "inputArtifacts": [{"name": "BuildOutput"}],
          "region": "ap-south-1"
        }
      ]
    }
  ]
}
EOF

echo "Pipeline definition saved to pipeline-definition.json"

echo -e "\e[33mCreating pipeline...\e[0m"
aws codepipeline create-pipeline \
    --pipeline file://pipeline-definition.json \
    --region ap-south-1 > /dev/null 2>&1

echo -e "\e[32mPipeline created!\e[0m"
echo ""
echo -e "\e[36mThe pipeline is now running its FIRST execution automatically.\e[0m"
echo "Watch it here: CodePipeline console → my-web-app-pipeline"
echo ""
echo "Expected timeline:"
echo "  0:00  — Source stage starts (pulls from CodeCommit)"
echo "  0:30  — Build stage starts (CodeBuild runs buildspec.yml)"
echo "  2:00  — Deploy stage starts (CodeDeploy runs lifecycle hooks)"
echo "  3:30  — All stages green — your app is live!"

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
sleep 5
echo -e "\e[33mCurrent pipeline state:\e[0m"
aws codepipeline get-pipeline-state \
    --name my-web-app-pipeline \
    --region ap-south-1 \
    --query "stageStates[*].{Stage:stageName,Status:latestExecution.status}" \
    --output table

echo ""
echo -e "\e[36m=== Pipeline Created ===\e[0m"
echo -e "\e[36mNext step: Run 08-monitor-pipeline.sh to watch execution\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 9 — Script 07: Create CodePipeline
# Three-stage pipeline: Source (CodeCommit) → Build (CodeBuild) → Deploy (CodeDeploy)
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 9 — Create CodePipeline ===" -ForegroundColor Cyan
Write-Host ""

$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
$ARTIFACT_BUCKET = "codepipeline-artifacts-$ACCOUNT_ID-ap-south-1"

if (-not $PIPELINE_ROLE_ARN) {
    $PIPELINE_ROLE_ARN = aws iam get-role `
        --role-name codepipeline-service-role `
        --query "Role.Arn" --output text
}

Write-Host "Pipeline Role ARN: $PIPELINE_ROLE_ARN"
Write-Host "Artifact Bucket:   $ARTIFACT_BUCKET"
Write-Host ""
Write-Host "Building pipeline definition..." -ForegroundColor Yellow

$PIPELINE_DEF = @"
{
  "name": "my-web-app-pipeline",
  "roleArn": "$PIPELINE_ROLE_ARN",
  "artifactStore": {
    "type": "S3",
    "location": "$ARTIFACT_BUCKET"
  },
  "stages": [
    {
      "name": "Source",
      "actions": [
        {
          "name": "Source",
          "actionTypeId": {
            "category": "Source",
            "owner": "AWS",
            "provider": "CodeCommit",
            "version": "1"
          },
          "configuration": {
            "RepositoryName": "my-web-app",
            "BranchName": "main",
            "PollForSourceChanges": "false"
          },
          "outputArtifacts": [{"name": "SourceOutput"}],
          "region": "ap-south-1"
        }
      ]
    },
    {
      "name": "Build",
      "actions": [
        {
          "name": "Build",
          "actionTypeId": {
            "category": "Build",
            "owner": "AWS",
            "provider": "CodeBuild",
            "version": "1"
          },
          "configuration": {
            "ProjectName": "my-web-app-build"
          },
          "inputArtifacts": [{"name": "SourceOutput"}],
          "outputArtifacts": [{"name": "BuildOutput"}],
          "region": "ap-south-1"
        }
      ]
    },
    {
      "name": "Deploy",
      "actions": [
        {
          "name": "Deploy",
          "actionTypeId": {
            "category": "Deploy",
            "owner": "AWS",
            "provider": "CodeDeploy",
            "version": "1"
          },
          "configuration": {
            "ApplicationName": "my-web-app",
            "DeploymentGroupName": "production"
          },
          "inputArtifacts": [{"name": "BuildOutput"}],
          "region": "ap-south-1"
        }
      ]
    }
  ]
}
"@

$PIPELINE_DEF | Out-File -FilePath "pipeline-definition.json" -Encoding utf8
Write-Host "Pipeline definition saved to pipeline-definition.json"

Write-Host "Creating pipeline..." -ForegroundColor Yellow
aws codepipeline create-pipeline `
    --pipeline file://pipeline-definition.json `
    --region ap-south-1 | Out-Null

Write-Host "Pipeline created!" -ForegroundColor Green
Write-Host ""
Write-Host "The pipeline is now running its FIRST execution automatically." -ForegroundColor Cyan
Write-Host "Watch it here: CodePipeline console → my-web-app-pipeline"
Write-Host ""
Write-Host "Expected timeline:"
Write-Host "  0:00  — Source stage starts (pulls from CodeCommit)"
Write-Host "  0:30  — Build stage starts (CodeBuild runs buildspec.yml)"
Write-Host "  2:00  — Deploy stage starts (CodeDeploy runs lifecycle hooks)"
Write-Host "  3:30  — All stages green — your app is live!"

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Start-Sleep -Seconds 5
Write-Host "Current pipeline state:" -ForegroundColor Yellow
aws codepipeline get-pipeline-state `
    --name my-web-app-pipeline `
    --region ap-south-1 `
    --query "stageStates[*].{Stage:stageName,Status:latestExecution.status}" `
    --output table

Write-Host ""
Write-Host "=== Pipeline Created ===" -ForegroundColor Cyan
Write-Host "Next step: Run 08-monitor-pipeline.ps1 to watch execution" -ForegroundColor Cyan
```

---

## 🏗️ PART 8 — MONITOR PIPELINE EXECUTION AND VERIFY ALL STAGES GREEN

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **AWS Console** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 9 — Script 08: Monitor Pipeline Execution
# Polls pipeline state and shows build/deploy logs
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 9 — Monitor Pipeline ===\e[0m"
echo ""

# ── PIPELINE STATE ────────────────────────────────────────────────────────────
echo -e "\e[33m--- Current Pipeline State ---\e[0m"
aws codepipeline get-pipeline-state \
    --name my-web-app-pipeline \
    --region ap-south-1 \
    --query "stageStates[*].{Stage:stageName,Status:latestExecution.status,Updated:actionStates[0].latestExecution.lastStatusChange}" \
    --output table

# ── LATEST EXECUTION ──────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m--- Latest Execution ---\e[0m"
EXEC_ID=$(aws codepipeline list-pipeline-executions \
    --pipeline-name my-web-app-pipeline \
    --max-results 1 \
    --region ap-south-1 \
    --query "pipelineExecutionSummaries[0].pipelineExecutionId" \
    --output text)

echo "Execution ID: $EXEC_ID"

aws codepipeline get-pipeline-execution \
    --pipeline-name my-web-app-pipeline \
    --pipeline-execution-id $EXEC_ID \
    --region ap-south-1 \
    --query "pipelineExecution.{Status:status,Trigger:trigger.triggerType}" \
    --output table

# ── CODEBUILD LOG TAIL ────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m--- Recent CodeBuild Log (last 20 lines) ---\e[0m"
LOG_STREAM=$(aws logs describe-log-streams \
    --log-group-name /aws/codebuild/my-web-app-build \
    --order-by LastEventTime \
    --descending \
    --max-items 1 \
    --region ap-south-1 \
    --query "logStreams[0].logStreamName" \
    --output text 2>/dev/null)

if [ -n "$LOG_STREAM" ] && [ "$LOG_STREAM" != "None" ]; then
    aws logs get-log-events \
        --log-group-name /aws/codebuild/my-web-app-build \
        --log-stream-name "$LOG_STREAM" \
        --limit 20 \
        --region ap-south-1 \
        --query "events[*].message" \
        --output text
else
    echo "  No build logs yet — build may not have started."
fi

# ── CODEDEPLOY DEPLOYMENTS ────────────────────────────────────────────────────
echo ""
echo -e "\e[33m--- CodeDeploy Deployment History ---\e[0m"
DEPLOYMENTS=$(aws deploy list-deployments \
    --application-name my-web-app \
    --deployment-group-name production \
    --region ap-south-1 \
    --query "deployments" \
    --output text)

for DEPLOYMENT_ID in $DEPLOYMENTS; do
    if [ -n "$DEPLOYMENT_ID" ] && [ "$DEPLOYMENT_ID" != "None" ]; then
        aws deploy get-deployment --deployment-id "$DEPLOYMENT_ID" --region ap-south-1 \
            --query "deploymentInfo.{ID:deploymentId,Status:status,Created:createTime}" \
            --output table
    fi
done

# ── ALL EXECUTIONS ────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m--- Pipeline Execution History ---\e[0m"
aws codepipeline list-pipeline-executions \
    --pipeline-name my-web-app-pipeline \
    --max-results 5 \
    --region ap-south-1 \
    --query "pipelineExecutionSummaries[*].{ID:pipelineExecutionId,Status:status,Trigger:trigger.triggerType,Started:startTime}" \
    --output table

echo ""
echo -e "\e[36m=== Monitor Complete ===\e[0m"
echo ""
echo "Console path: CodePipeline → my-web-app-pipeline"
echo "Re-run this script every 30s to watch progression: Source → Build → Deploy"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 9 — Script 08: Monitor Pipeline Execution
# Polls pipeline state and shows build/deploy logs
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 9 — Monitor Pipeline ===" -ForegroundColor Cyan
Write-Host ""

# ── PIPELINE STATE ────────────────────────────────────────────────────────────
Write-Host "--- Current Pipeline State ---" -ForegroundColor Yellow
aws codepipeline get-pipeline-state `
    --name my-web-app-pipeline `
    --region ap-south-1 `
    --query "stageStates[*].{Stage:stageName,Status:latestExecution.status,Updated:actionStates[0].latestExecution.lastStatusChange}" `
    --output table

# ── LATEST EXECUTION ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Latest Execution ---" -ForegroundColor Yellow
$EXEC_ID = aws codepipeline list-pipeline-executions `
    --pipeline-name my-web-app-pipeline `
    --max-results 1 `
    --region ap-south-1 `
    --query "pipelineExecutionSummaries[0].pipelineExecutionId" `
    --output text

Write-Host "Execution ID: $EXEC_ID"

aws codepipeline get-pipeline-execution `
    --pipeline-name my-web-app-pipeline `
    --pipeline-execution-id $EXEC_ID `
    --region ap-south-1 `
    --query "pipelineExecution.{Status:status,Trigger:trigger.triggerType}" `
    --output table

# ── CODEBUILD LOG TAIL ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Recent CodeBuild Log (last 20 lines) ---" -ForegroundColor Yellow
$LOG_STREAM = aws logs describe-log-streams `
    --log-group-name /aws/codebuild/my-web-app-build `
    --order-by LastEventTime `
    --descending `
    --max-items 1 `
    --region ap-south-1 `
    --query "logStreams[0].logStreamName" `
    --output text 2>$null

if ($LOG_STREAM -and $LOG_STREAM -ne "None") {
    aws logs get-log-events `
        --log-group-name /aws/codebuild/my-web-app-build `
        --log-stream-name $LOG_STREAM `
        --limit 20 `
        --region ap-south-1 `
        --query "events[*].message" `
        --output text
}
else {
    Write-Host "  No build logs yet — build may not have started."
}

# ── CODEDEPLOY DEPLOYMENTS ────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- CodeDeploy Deployment History ---" -ForegroundColor Yellow
aws deploy list-deployments `
    --application-name my-web-app `
    --deployment-group-name production `
    --region ap-south-1 `
    --query "deployments" `
    --output text | ForEach-Object {
    if ($_) {
        aws deploy get-deployment --deployment-id $_ --region ap-south-1 `
            --query "deploymentInfo.{ID:deploymentId,Status:status,Created:createTime}" `
            --output table
    }
}

# ── ALL EXECUTIONS ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Pipeline Execution History ---" -ForegroundColor Yellow
aws codepipeline list-pipeline-executions `
    --pipeline-name my-web-app-pipeline `
    --max-results 5 `
    --region ap-south-1 `
    --query "pipelineExecutionSummaries[*].{ID:pipelineExecutionId,Status:status,Trigger:trigger.triggerType,Started:startTime}" `
    --output table

Write-Host ""
Write-Host "=== Monitor Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Console path: CodePipeline → my-web-app-pipeline"
Write-Host "Re-run this script every 30s to watch progression: Source → Build → Deploy"
```

---

## 🏗️ PART 9 — UPDATE APP TO VERSION 2.0, PUSH, WATCH AUTO-DEPLOY

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **AWS Console** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 9 — Script 09: Trigger New Deployment (Version 2.0)
# Edits index.html, commits, pushes — watches pipeline auto-trigger
# =============================================================================

echo -e "\e[36m=== Project 9 — Trigger Version 2.0 Deployment ===\e[0m"
echo ""
echo -e "\e[33mThis script demonstrates the full CI/CD loop:\e[0m"
echo "  1. Edit source code (Version 1.0 → Version 2.0)"
echo "  2. git push to CodeCommit"
echo "  3. Pipeline auto-triggers (CloudWatch Events)"
echo "  4. CodeBuild validates and packages"
echo "  5. CodeDeploy pushes to EC2"
echo "  6. Web app shows Version 2.0"
echo ""

# ── SET APPLICATION DIRECTORY ─────────────────────────────────────────────────
# Point this at wherever you cloned the CodeCommit repo locally
APP_DIR="$HOME/my-web-app"

if [ ! -d "$APP_DIR" ]; then
    echo -e "\e[31mERROR: Application directory not found: $APP_DIR\e[0m"
    echo "Adjust the APP_DIR variable to your local CodeCommit clone path."
    exit 1
fi

cd "$APP_DIR"

# ── EDIT index.html ───────────────────────────────────────────────────────────
echo -e "\e[33m[1/3] Updating Version 1.0 → Version 2.0 in index.html...\e[0m"

if grep -q "Version 1\.0" index.html; then
    sed -i 's/Version 1\.0/Version 2.0/g' index.html
    echo -e "\e[32mindex.html updated to Version 2.0.\e[0m"
elif grep -q "Version 2\.0" index.html; then
    echo "Already on Version 2.0 — bumping to Version 3.0 for this push..."
    sed -i 's/Version 2\.0/Version 3.0/g' index.html
else
    echo "WARNING: Version string not found. Check index.html manually."
fi

# ── GIT COMMIT AND PUSH ───────────────────────────────────────────────────────
echo -e "\e[33m[2/3] Committing and pushing to CodeCommit...\e[0m"

git add index.html
git commit -m "feat: update to version 2.0 — triggers pipeline"
git push origin main

echo -e "\e[32mPush complete.\e[0m"

# ── WATCH PIPELINE ────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[3/3] Pipeline should auto-trigger within 30 seconds.\e[0m"
echo -e "\e[33mWaiting 30 seconds, then polling status...\e[0m"

sleep 30

# Poll until completion or 10 minutes
MAX_CHECKS=20
CHECK=0
PIPELINE_DONE=false

while [ "$CHECK" -lt "$MAX_CHECKS" ] && [ "$PIPELINE_DONE" = "false" ]; do
    CHECK=$((CHECK + 1))

    echo -e "\e[36m--- Check $CHECK / $MAX_CHECKS ---\e[0m"
    aws codepipeline get-pipeline-state \
        --name my-web-app-pipeline \
        --region ap-south-1 \
        --query "stageStates[*].{Stage:stageName,Status:latestExecution.status}" \
        --output table

    # Check for failure
    FAILED=$(aws codepipeline get-pipeline-state \
        --name my-web-app-pipeline \
        --region ap-south-1 \
        --query "stageStates[?latestExecution.status=='Failed'].stageName" \
        --output text)

    IN_PROGRESS=$(aws codepipeline get-pipeline-state \
        --name my-web-app-pipeline \
        --region ap-south-1 \
        --query "stageStates[?latestExecution.status=='InProgress'].stageName" \
        --output text)

    if [ -n "$FAILED" ]; then
        echo ""
        echo -e "\e[31mPIPELINE FAILED — check CodePipeline console for details.\e[0m"
        PIPELINE_DONE=true
    elif [ -z "$IN_PROGRESS" ]; then
        echo ""
        echo -e "\e[32mPIPELINE SUCCEEDED — deployment complete!\e[0m"
        PIPELINE_DONE=true
    else
        echo -e "\e[90m  (still running — waiting 30s...)\e[0m"
        sleep 30
    fi
done

# ── VERIFY APP ────────────────────────────────────────────────────────────────
if [ -n "$DEPLOY_PUBLIC_IP" ]; then
    echo ""
    echo -e "\e[33mVerify deployment at:\e[0m"
    echo "  http://$DEPLOY_PUBLIC_IP"
else
    echo ""
    echo "Set DEPLOY_PUBLIC_IP to verify the deployed app."
fi

echo ""
echo -e "\e[36m=== Version 2.0 Deployment Triggered ===\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 9 — Script 09: Trigger New Deployment (Version 2.0)
# Edits index.html, commits, pushes — watches pipeline auto-trigger
# =============================================================================

Write-Host "=== Project 9 — Trigger Version 2.0 Deployment ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script demonstrates the full CI/CD loop:" -ForegroundColor Yellow
Write-Host "  1. Edit source code (Version 1.0 → Version 2.0)"
Write-Host "  2. git push to CodeCommit"
Write-Host "  3. Pipeline auto-triggers (CloudWatch Events)"
Write-Host "  4. CodeBuild validates and packages"
Write-Host "  5. CodeDeploy pushes to EC2"
Write-Host "  6. Web app shows Version 2.0"
Write-Host ""

# ── SET APPLICATION DIRECTORY ─────────────────────────────────────────────────
# Point this at wherever you cloned the CodeCommit repo locally
$APP_DIR = "C:\Users\$env:USERNAME\my-web-app"

if (-not (Test-Path $APP_DIR)) {
    Write-Host "ERROR: Application directory not found: $APP_DIR" -ForegroundColor Red
    Write-Host "Adjust the APP_DIR variable to your local CodeCommit clone path."
    exit 1
}

Set-Location $APP_DIR

# ── EDIT index.html ───────────────────────────────────────────────────────────
Write-Host "[1/3] Updating Version 1.0 → Version 2.0 in index.html..." -ForegroundColor Yellow

$CURRENT = Get-Content index.html -Raw
if ($CURRENT -match "Version 1\.0") {
    (Get-Content index.html) -replace 'Version 1\.0', 'Version 2.0' | Set-Content index.html
    Write-Host "index.html updated." -ForegroundColor Green
}
elseif ($CURRENT -match "Version 2\.0") {
    Write-Host "Already on Version 2.0 — bumping to Version 3.0 for this push..."
    (Get-Content index.html) -replace 'Version 2\.0', 'Version 3.0' | Set-Content index.html
}
else {
    Write-Host "WARNING: Version string not found. Check index.html manually."
}

# ── GIT COMMIT AND PUSH ───────────────────────────────────────────────────────
Write-Host "[2/3] Committing and pushing to CodeCommit..." -ForegroundColor Yellow

git add index.html
git commit -m "feat: update to version 2.0 — triggers pipeline"
git push origin main

Write-Host "Push complete." -ForegroundColor Green

# ── WATCH PIPELINE ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Pipeline should auto-trigger within 30 seconds." -ForegroundColor Yellow
Write-Host "Waiting 30 seconds, then polling status..." -ForegroundColor Yellow

Start-Sleep -Seconds 30

# Poll until completion or 10 minutes
$MAX_CHECKS = 20
$CHECK = 0
$PIPELINE_DONE = $false

while ($CHECK -lt $MAX_CHECKS -and -not $PIPELINE_DONE) {
    $CHECK++
    $STATE = aws codepipeline get-pipeline-state `
        --name my-web-app-pipeline `
        --region ap-south-1 `
        --query "stageStates[*].{Stage:stageName,Status:latestExecution.status}" `
        --output json | ConvertFrom-Json

    Write-Host "--- Check $CHECK / $MAX_CHECKS ---" -ForegroundColor Cyan
    $STATE | ForEach-Object {
        $COLOR = switch ($_.Status) {
            "Succeeded" { "Green" }
            "Failed" { "Red" }
            "InProgress" { "Yellow" }
            default { "Gray" }
        }
        Write-Host "  $($_.Stage): $($_.Status)" -ForegroundColor $COLOR
    }

    $STATUSES = $STATE | Select-Object -ExpandProperty Status
    if ($STATUSES -contains "Failed") {
        Write-Host ""
        Write-Host "PIPELINE FAILED — check CodePipeline console for details." -ForegroundColor Red
        $PIPELINE_DONE = $true
    }
    elseif ($STATUSES -notcontains "InProgress" -and $STATUSES -contains "Succeeded") {
        Write-Host ""
        Write-Host "PIPELINE SUCCEEDED — deployment complete!" -ForegroundColor Green
        $PIPELINE_DONE = $true
    }
    else {
        Write-Host "  (still running — waiting 30s...)" -ForegroundColor Gray
        Start-Sleep -Seconds 30
    }
}

# ── VERIFY APP ────────────────────────────────────────────────────────────────
if ($DEPLOY_PUBLIC_IP) {
    Write-Host ""
    Write-Host "Opening browser to verify deployment:" -ForegroundColor Yellow
    Write-Host "  http://$DEPLOY_PUBLIC_IP"
    Start-Process "http://$DEPLOY_PUBLIC_IP"
}
else {
    Write-Host ""
    Write-Host "Set `$DEPLOY_PUBLIC_IP to open the app in browser."
}

Write-Host ""
Write-Host "=== Version 2.0 Deployment Triggered ===" -ForegroundColor Cyan
```

---

## 🧹 TEARDOWN
To prevent recurring AWS charges, proceed to the `docs/cleanup-guide.md` to run the tear-down scripts.
