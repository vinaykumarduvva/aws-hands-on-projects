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