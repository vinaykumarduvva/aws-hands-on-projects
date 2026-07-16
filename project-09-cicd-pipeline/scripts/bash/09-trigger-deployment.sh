#!/bin/bash

# =============================================================================
# Project 9 — Script 09: Trigger New Deployment (Version 2.0)
# Edits index.html, commits, pushes — watches pipeline auto-trigger
# =============================================================================

echo -e "\e[36m=== Project 9 — Trigger Version 2.0 Deployment ===\e[0m"
echo ""
echo -e "\e[33mThis script demonstrates the full CI/CD loop:\e[0m"
echo "  1. Edit source code (Version 1.0 → Version 2.0)"
echo "  2. git push to CodeCommit"
echo "  3. Pipeline auto-triggers (CloudWatch Events)"
echo "  4. CodeBuild validates and packages"
echo "  5. CodeDeploy pushes to EC2"
echo "  6. Web app shows Version 2.0"
echo ""

# ── SET APPLICATION DIRECTORY ─────────────────────────────────────────────────
# Point this at wherever you cloned the CodeCommit repo locally
APP_DIR="$HOME/my-web-app"

if [ ! -d "$APP_DIR" ]; then
    echo -e "\e[31mERROR: Application directory not found: $APP_DIR\e[0m"
    echo "Adjust the APP_DIR variable to your local CodeCommit clone path."
    exit 1
fi

cd "$APP_DIR"

# ── EDIT index.html ───────────────────────────────────────────────────────────
echo -e "\e[33m[1/3] Updating Version 1.0 → Version 2.0 in index.html...\e[0m"

if grep -q "Version 1\.0" index.html; then
    sed -i 's/Version 1\.0/Version 2.0/g' index.html
    echo -e "\e[32mindex.html updated to Version 2.0.\e[0m"
elif grep -q "Version 2\.0" index.html; then
    echo "Already on Version 2.0 — bumping to Version 3.0 for this push..."
    sed -i 's/Version 2\.0/Version 3.0/g' index.html
else
    echo "WARNING: Version string not found. Check index.html manually."
fi

# ── GIT COMMIT AND PUSH ───────────────────────────────────────────────────────
echo -e "\e[33m[2/3] Committing and pushing to CodeCommit...\e[0m"

git add index.html
git commit -m "feat: update to version 2.0 — triggers pipeline"
git push origin main

echo -e "\e[32mPush complete.\e[0m"

# ── WATCH PIPELINE ────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[3/3] Pipeline should auto-trigger within 30 seconds.\e[0m"
echo -e "\e[33mWaiting 30 seconds, then polling status...\e[0m"

sleep 30

# Poll until completion or 10 minutes
MAX_CHECKS=20
CHECK=0
PIPELINE_DONE=false

while [ "$CHECK" -lt "$MAX_CHECKS" ] && [ "$PIPELINE_DONE" = "false" ]; do
    CHECK=$((CHECK + 1))

    echo -e "\e[36m--- Check $CHECK / $MAX_CHECKS ---\e[0m"
    aws codepipeline get-pipeline-state \
        --name my-web-app-pipeline \
        --region ap-south-1 \
        --query "stageStates[*].{Stage:stageName,Status:latestExecution.status}" \
        --output table

    # Check for failure
    FAILED=$(aws codepipeline get-pipeline-state \
        --name my-web-app-pipeline \
        --region ap-south-1 \
        --query "stageStates[?latestExecution.status=='Failed'].stageName" \
        --output text)

    IN_PROGRESS=$(aws codepipeline get-pipeline-state \
        --name my-web-app-pipeline \
        --region ap-south-1 \
        --query "stageStates[?latestExecution.status=='InProgress'].stageName" \
        --output text)

    if [ -n "$FAILED" ]; then
        echo ""
        echo -e "\e[31mPIPELINE FAILED — check CodePipeline console for details.\e[0m"
        PIPELINE_DONE=true
    elif [ -z "$IN_PROGRESS" ]; then
        echo ""
        echo -e "\e[32mPIPELINE SUCCEEDED — deployment complete!\e[0m"
        PIPELINE_DONE=true
    else
        echo -e "\e[90m  (still running — waiting 30s...)\e[0m"
        sleep 30
    fi
done

# ── VERIFY APP ────────────────────────────────────────────────────────────────
if [ -n "$DEPLOY_PUBLIC_IP" ]; then
    echo ""
    echo -e "\e[33mVerify deployment at:\e[0m"
    echo "  http://$DEPLOY_PUBLIC_IP"
else
    echo ""
    echo "Set DEPLOY_PUBLIC_IP to verify the deployed app."
fi

echo ""
echo -e "\e[36m=== Version 2.0 Deployment Triggered ===\e[0m"