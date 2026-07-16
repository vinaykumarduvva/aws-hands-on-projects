#!/bin/bash

# =============================================================================
# Project 9 — Script 03: Create CodeCommit Repository and Push Code
# Creates managed Git repo and configures local git to push to it
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 9 — Create CodeCommit Repository ===\e[0m"
echo ""

# ── CREATE REPOSITORY ─────────────────────────────────────────────────────────
echo -e "\e[33m[1/3] Creating CodeCommit repository: my-web-app...\e[0m"

aws codecommit create-repository \
    --repository-name my-web-app \
    --repository-description "CI/CD demo app for Project 9" \
    --tags Project=project-09-cicd \
    --region ap-south-1 > /dev/null 2>&1

echo -e "\e[32mRepository created.\e[0m"

# ── GET CLONE URL ─────────────────────────────────────────────────────────────
CLONE_URL=$(aws codecommit get-repository \
    --repository-name my-web-app \
    --query "repositoryMetadata.cloneUrlHttp" \
    --output text \
    --region ap-south-1)

echo -e "\e[32mClone URL: $CLONE_URL\e[0m"

# ── GIT CONFIGURATION ─────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[2/3] Configuring Git credential helper for CodeCommit...\e[0m"

git config --global credential.helper "!aws codecommit credential-helper \$@"
git config --global credential.UseHttpPath true

echo -e "\e[32mGit credential helper configured.\e[0m"

# ── INSTRUCTIONS FOR CODE PUSH ────────────────────────────────────────────────
echo ""
echo -e "\e[33m[3/3] Ready to push application code.\e[0m"
echo ""
echo -e "\e[36mRun these commands from your application directory:\e[0m"
echo ""
echo "  cd ~/my-web-app"
echo "  git init"
echo "  git checkout -b main"
echo "  # Copy application/ folder contents here"
echo "  git add ."
echo "  git commit -m 'feat: initial CI/CD demo app'"
echo "  git remote add origin $CLONE_URL"
echo "  git push -u origin main"
echo ""
echo "Or if using the application/ folder from this repo:"
echo "  cd application"
echo "  git init && git checkout -b main"
echo "  git add ."
echo "  git commit -m 'feat: initial CI/CD demo app'"
echo "  git remote add origin $CLONE_URL"
echo "  git push -u origin main"

# ── VERIFY AFTER PUSH ─────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mAfter pushing, verify with:\e[0m"
echo "  aws codecommit get-branch --repository-name my-web-app --branch-name main --region ap-south-1"

echo ""
echo -e "\e[36m=== CodeCommit Setup Complete ===\e[0m"
echo "  CLONE_URL = $CLONE_URL"
echo ""
echo -e "\e[36mNext step: Push your code, then run 04-launch-ec2.sh\e[0m"