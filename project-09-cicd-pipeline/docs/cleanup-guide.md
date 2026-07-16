# Cleanup Guide

This guide covers the systematic tear-down of the infrastructure.

## 🧹 DELETE ALL AWS RESOURCES CREATED BY THIS PROJECT

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the relevant service dashboard (e.g., EC2, VPC, S3, RDS).
2. Locate the resources you created for this project (refer to the `Resources to Delete` table above for the required deletion order).
3. Select each resource and click the primary **Delete**, **Terminate**, or **Empty** button.
4. In the confirmation dialog, type the required confirmation text (e.g., `delete`, `permanently delete`, or the resource name).
5. Click to finalize the deletion, and wait for the resource to completely disappear from the console list before moving to the next service.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash

# =============================================================================
# Project 9 — Script 10: Full Cleanup
# Deletes all CI/CD pipeline resources in the correct order
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 9 — Full Cleanup ===\e[0m"
echo ""
echo -e "\e[31mDeletes: Pipeline, CodeDeploy, CodeBuild, CodeCommit, EC2, S3, IAM\e[0m"
echo ""

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
ARTIFACT_BUCKET="codepipeline-artifacts-$ACCOUNT_ID-ap-south-1"

# Re-fetch IDs
if [ -z "$DEPLOY_INSTANCE_ID" ]; then
    DEPLOY_INSTANCE_ID=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=cicd-deploy-server" \
        --region ap-south-1 \
        --query "Reservations[0].Instances[0].InstanceId" --output text)
fi
if [ -z "$DEPLOY_SG" ]; then
    DEPLOY_SG=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=cicd-deploy-sg" \
        --region ap-south-1 \
        --query "SecurityGroups[0].GroupId" --output text)
fi

echo "EC2 Instance: $DEPLOY_INSTANCE_ID"
echo "Security Group: $DEPLOY_SG"
echo ""

# ── 1: DELETE PIPELINE ────────────────────────────────────────────────────────
echo -e "\e[33m[1/7] Deleting CodePipeline...\e[0m"
aws codepipeline delete-pipeline --name my-web-app-pipeline --region ap-south-1 2>/dev/null
echo -e "\e[32mPipeline deleted.\e[0m"

# ── 2: DELETE CODEDEPLOY ──────────────────────────────────────────────────────
echo -e "\e[33m[2/7] Deleting CodeDeploy resources...\e[0m"
aws deploy delete-deployment-group \
    --application-name my-web-app \
    --deployment-group-name production \
    --region ap-south-1 2>/dev/null
aws deploy delete-application --application-name my-web-app --region ap-south-1 2>/dev/null
echo -e "\e[32mCodeDeploy deleted.\e[0m"

# ── 3: DELETE CODEBUILD ───────────────────────────────────────────────────────
echo -e "\e[33m[3/7] Deleting CodeBuild project...\e[0m"
aws codebuild delete-project --name my-web-app-build --region ap-south-1 2>/dev/null
echo -e "\e[32mCodeBuild deleted.\e[0m"

# ── 4: DELETE CODECOMMIT ──────────────────────────────────────────────────────
echo -e "\e[33m[4/7] Deleting CodeCommit repository...\e[0m"
aws codecommit delete-repository --repository-name my-web-app --region ap-south-1 2>/dev/null
echo -e "\e[32mCodeCommit deleted.\e[0m"

# ── 5: TERMINATE EC2 ─────────────────────────────────────────────────────────
echo -e "\e[33m[5/7] Terminating EC2 instance...\e[0m"
if [ -n "$DEPLOY_INSTANCE_ID" ] && [ "$DEPLOY_INSTANCE_ID" != "None" ]; then
    aws ec2 terminate-instances --instance-ids $DEPLOY_INSTANCE_ID --region ap-south-1 > /dev/null 2>&1
    aws ec2 wait instance-terminated --instance-ids $DEPLOY_INSTANCE_ID --region ap-south-1
    echo "EC2 terminated."
fi
if [ -n "$DEPLOY_SG" ] && [ "$DEPLOY_SG" != "None" ]; then
    aws ec2 delete-security-group --group-id $DEPLOY_SG --region ap-south-1 2>/dev/null
    echo "Security group deleted."
fi
echo -e "\e[32mEC2 resources deleted.\e[0m"

# ── 6: EMPTY AND DELETE S3 ────────────────────────────────────────────────────
echo -e "\e[33m[6/7] Emptying and deleting S3 artifact bucket...\e[0m"
aws s3 rm "s3://$ARTIFACT_BUCKET" --recursive 2>/dev/null
aws s3api delete-bucket --bucket $ARTIFACT_BUCKET --region ap-south-1 2>/dev/null
echo -e "\e[32mS3 bucket deleted.\e[0m"

# ── 7: DELETE IAM ROLES ───────────────────────────────────────────────────────
echo -e "\e[33m[7/7] Deleting IAM roles...\e[0m"

ROLES=(
    "codebuild-service-role"
    "codedeploy-service-role"
    "codepipeline-service-role"
    "ec2-codedeploy-role"
)

for ROLE in "${ROLES[@]}"; do
    POLICIES=$(aws iam list-attached-role-policies \
        --role-name "$ROLE" \
        --query "AttachedPolicies[*].PolicyArn" --output text 2>/dev/null)
    for P in $POLICIES; do
        if [ -n "$P" ] && [ "$P" != "None" ]; then
            aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$P" 2>/dev/null
        fi
    done
    aws iam delete-role --role-name "$ROLE" 2>/dev/null
    echo "  Deleted role: $ROLE"
done

aws iam remove-role-from-instance-profile \
    --instance-profile-name ec2-codedeploy-profile \
    --role-name ec2-codedeploy-role 2>/dev/null
aws iam delete-instance-profile \
    --instance-profile-name ec2-codedeploy-profile 2>/dev/null
echo -e "\e[32mIAM roles deleted.\e[0m"

# ── VERIFICATION ──────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== Cleanup Verification ===\e[0m"
echo ""

PIPE=$(aws codepipeline get-pipeline --name my-web-app-pipeline --region ap-south-1 2>&1)
if echo "$PIPE" | grep -q "PipelineNotFoundException"; then
    echo -e "\e[32mPipeline:    DELETED\e[0m"
fi

REPO=$(aws codecommit get-repository --repository-name my-web-app --region ap-south-1 2>&1)
if echo "$REPO" | grep -q "RepositoryDoesNotExistException"; then
    echo -e "\e[32mCodeCommit:  DELETED\e[0m"
fi

echo ""
echo -e "\e[36m=== Project 9 Cleanup Complete ===\e[0m"
echo "Cost: \$0.00 — all within free tier"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# =============================================================================
# Project 9 — Script 10: Full Cleanup
# Deletes all CI/CD pipeline resources in the correct order
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 9 — Full Cleanup ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Deletes: Pipeline, CodeDeploy, CodeBuild, CodeCommit, EC2, S3, IAM" -ForegroundColor Red
Write-Host ""

$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
$ARTIFACT_BUCKET = "codepipeline-artifacts-$ACCOUNT_ID-ap-south-1"

# Re-fetch IDs
if (-not $DEPLOY_INSTANCE_ID) {
    $DEPLOY_INSTANCE_ID = aws ec2 describe-instances `
        --filters "Name=tag:Name,Values=cicd-deploy-server" `
        --region ap-south-1 `
        --query "Reservations[0].Instances[0].InstanceId" --output text
}
if (-not $DEPLOY_SG) {
    $DEPLOY_SG = aws ec2 describe-security-groups `
        --filters "Name=group-name,Values=cicd-deploy-sg" `
        --region ap-south-1 `
        --query "SecurityGroups[0].GroupId" --output text
}

Write-Host "EC2 Instance: $DEPLOY_INSTANCE_ID"
Write-Host "Security Group: $DEPLOY_SG"
Write-Host ""

# ── 1: DELETE PIPELINE ────────────────────────────────────────────────────────
Write-Host "[1/7] Deleting CodePipeline..." -ForegroundColor Yellow
aws codepipeline delete-pipeline --name my-web-app-pipeline --region ap-south-1 2>$null
Write-Host "Pipeline deleted." -ForegroundColor Green

# ── 2: DELETE CODEDEPLOY ──────────────────────────────────────────────────────
Write-Host "[2/7] Deleting CodeDeploy resources..." -ForegroundColor Yellow
aws deploy delete-deployment-group `
    --application-name my-web-app `
    --deployment-group-name production `
    --region ap-south-1 2>$null
aws deploy delete-application --application-name my-web-app --region ap-south-1 2>$null
Write-Host "CodeDeploy deleted." -ForegroundColor Green

# ── 3: DELETE CODEBUILD ───────────────────────────────────────────────────────
Write-Host "[3/7] Deleting CodeBuild project..." -ForegroundColor Yellow
aws codebuild delete-project --name my-web-app-build --region ap-south-1 2>$null
Write-Host "CodeBuild deleted." -ForegroundColor Green

# ── 4: DELETE CODECOMMIT ──────────────────────────────────────────────────────
Write-Host "[4/7] Deleting CodeCommit repository..." -ForegroundColor Yellow
aws codecommit delete-repository --repository-name my-web-app --region ap-south-1 2>$null
Write-Host "CodeCommit deleted." -ForegroundColor Green

# ── 5: TERMINATE EC2 ─────────────────────────────────────────────────────────
Write-Host "[5/7] Terminating EC2 instance..." -ForegroundColor Yellow
if ($DEPLOY_INSTANCE_ID -and $DEPLOY_INSTANCE_ID -ne "None") {
    aws ec2 terminate-instances --instance-ids $DEPLOY_INSTANCE_ID --region ap-south-1 | Out-Null
    aws ec2 wait instance-terminated --instance-ids $DEPLOY_INSTANCE_ID --region ap-south-1
    Write-Host "EC2 terminated."
}
if ($DEPLOY_SG -and $DEPLOY_SG -ne "None") {
    aws ec2 delete-security-group --group-id $DEPLOY_SG --region ap-south-1 2>$null
    Write-Host "Security group deleted."
}
Write-Host "EC2 resources deleted." -ForegroundColor Green

# ── 6: EMPTY AND DELETE S3 ────────────────────────────────────────────────────
Write-Host "[6/7] Emptying and deleting S3 artifact bucket..." -ForegroundColor Yellow
aws s3 rm "s3://$ARTIFACT_BUCKET" --recursive 2>$null
aws s3api delete-bucket --bucket $ARTIFACT_BUCKET --region ap-south-1 2>$null
Write-Host "S3 bucket deleted." -ForegroundColor Green

# ── 7: DELETE IAM ROLES ───────────────────────────────────────────────────────
Write-Host "[7/7] Deleting IAM roles..." -ForegroundColor Yellow

$ROLES = @(
    "codebuild-service-role",
    "codedeploy-service-role",
    "codepipeline-service-role",
    "ec2-codedeploy-role"
)

foreach ($ROLE in $ROLES) {
    $POLICIES = aws iam list-attached-role-policies `
        --role-name $ROLE `
        --query "AttachedPolicies[*].PolicyArn" --output text 2>$null
    foreach ($P in ($POLICIES -split '\s+')) {
        if ($P -and $P -ne "None") {
            aws iam detach-role-policy --role-name $ROLE --policy-arn $P 2>$null
        }
    }
    aws iam delete-role --role-name $ROLE 2>$null
    Write-Host "  Deleted role: $ROLE"
}

aws iam remove-role-from-instance-profile `
    --instance-profile-name ec2-codedeploy-profile `
    --role-name ec2-codedeploy-role 2>$null
aws iam delete-instance-profile `
    --instance-profile-name ec2-codedeploy-profile 2>$null
Write-Host "IAM roles deleted." -ForegroundColor Green

# ── VERIFICATION ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Cleanup Verification ===" -ForegroundColor Cyan
Write-Host ""

$PIPE = aws codepipeline get-pipeline --name my-web-app-pipeline --region ap-south-1 2>&1
if ($PIPE -match "PipelineNotFoundException") { Write-Host "Pipeline:    DELETED" -ForegroundColor Green }

$REPO = aws codecommit get-repository --repository-name my-web-app --region ap-south-1 2>&1
if ($REPO -match "RepositoryDoesNotExistException") { Write-Host "CodeCommit:  DELETED" -ForegroundColor Green }

Write-Host ""
Write-Host "=== Project 9 Cleanup Complete ===" -ForegroundColor Cyan
Write-Host "Cost: $0.00 — all within free tier"
```
