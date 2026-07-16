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