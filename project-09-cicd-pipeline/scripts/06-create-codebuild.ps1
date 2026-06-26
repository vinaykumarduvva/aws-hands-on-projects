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