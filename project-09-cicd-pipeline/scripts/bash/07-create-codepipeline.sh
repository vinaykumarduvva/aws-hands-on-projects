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