#!/bin/bash

# =============================================================================
# Project 9 — Script 08: Monitor Pipeline Execution
# Polls pipeline state and shows build/deploy logs
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 9 — Monitor Pipeline ===\e[0m"
echo ""

# ── PIPELINE STATE ────────────────────────────────────────────────────────────
echo -e "\e[33m--- Current Pipeline State ---\e[0m"
aws codepipeline get-pipeline-state \
    --name my-web-app-pipeline \
    --region ap-south-1 \
    --query "stageStates[*].{Stage:stageName,Status:latestExecution.status,Updated:actionStates[0].latestExecution.lastStatusChange}" \
    --output table

# ── LATEST EXECUTION ──────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m--- Latest Execution ---\e[0m"
EXEC_ID=$(aws codepipeline list-pipeline-executions \
    --pipeline-name my-web-app-pipeline \
    --max-results 1 \
    --region ap-south-1 \
    --query "pipelineExecutionSummaries[0].pipelineExecutionId" \
    --output text)

echo "Execution ID: $EXEC_ID"

aws codepipeline get-pipeline-execution \
    --pipeline-name my-web-app-pipeline \
    --pipeline-execution-id $EXEC_ID \
    --region ap-south-1 \
    --query "pipelineExecution.{Status:status,Trigger:trigger.triggerType}" \
    --output table

# ── CODEBUILD LOG TAIL ────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m--- Recent CodeBuild Log (last 20 lines) ---\e[0m"
LOG_STREAM=$(aws logs describe-log-streams \
    --log-group-name /aws/codebuild/my-web-app-build \
    --order-by LastEventTime \
    --descending \
    --max-items 1 \
    --region ap-south-1 \
    --query "logStreams[0].logStreamName" \
    --output text 2>/dev/null)

if [ -n "$LOG_STREAM" ] && [ "$LOG_STREAM" != "None" ]; then
    aws logs get-log-events \
        --log-group-name /aws/codebuild/my-web-app-build \
        --log-stream-name "$LOG_STREAM" \
        --limit 20 \
        --region ap-south-1 \
        --query "events[*].message" \
        --output text
else
    echo "  No build logs yet — build may not have started."
fi

# ── CODEDEPLOY DEPLOYMENTS ────────────────────────────────────────────────────
echo ""
echo -e "\e[33m--- CodeDeploy Deployment History ---\e[0m"
DEPLOYMENTS=$(aws deploy list-deployments \
    --application-name my-web-app \
    --deployment-group-name production \
    --region ap-south-1 \
    --query "deployments" \
    --output text)

for DEPLOYMENT_ID in $DEPLOYMENTS; do
    if [ -n "$DEPLOYMENT_ID" ] && [ "$DEPLOYMENT_ID" != "None" ]; then
        aws deploy get-deployment --deployment-id "$DEPLOYMENT_ID" --region ap-south-1 \
            --query "deploymentInfo.{ID:deploymentId,Status:status,Created:createTime}" \
            --output table
    fi
done

# ── ALL EXECUTIONS ────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m--- Pipeline Execution History ---\e[0m"
aws codepipeline list-pipeline-executions \
    --pipeline-name my-web-app-pipeline \
    --max-results 5 \
    --region ap-south-1 \
    --query "pipelineExecutionSummaries[*].{ID:pipelineExecutionId,Status:status,Trigger:trigger.triggerType,Started:startTime}" \
    --output table

echo ""
echo -e "\e[36m=== Monitor Complete ===\e[0m"
echo ""
echo "Console path: CodePipeline → my-web-app-pipeline"
echo "Re-run this script every 30s to watch progression: Source → Build → Deploy"