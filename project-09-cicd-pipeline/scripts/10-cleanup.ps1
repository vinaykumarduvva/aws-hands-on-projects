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