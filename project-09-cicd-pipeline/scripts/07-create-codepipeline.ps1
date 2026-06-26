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