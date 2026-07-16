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