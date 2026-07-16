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