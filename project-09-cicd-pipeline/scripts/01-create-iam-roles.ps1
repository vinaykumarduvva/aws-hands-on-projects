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