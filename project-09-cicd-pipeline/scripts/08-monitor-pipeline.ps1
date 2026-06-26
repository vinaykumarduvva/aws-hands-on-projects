# =============================================================================
# Project 9 — Script 08: Monitor Pipeline Execution
# Polls pipeline state and shows build/deploy logs
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 9 — Monitor Pipeline ===" -ForegroundColor Cyan
Write-Host ""

# ── PIPELINE STATE ────────────────────────────────────────────────────────────
Write-Host "--- Current Pipeline State ---" -ForegroundColor Yellow
aws codepipeline get-pipeline-state `
    --name my-web-app-pipeline `
    --region ap-south-1 `
    --query "stageStates[*].{Stage:stageName,Status:latestExecution.status,Updated:actionStates[0].latestExecution.lastStatusChange}" `
    --output table

# ── LATEST EXECUTION ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Latest Execution ---" -ForegroundColor Yellow
$EXEC_ID = aws codepipeline list-pipeline-executions `
    --pipeline-name my-web-app-pipeline `
    --max-results 1 `
    --region ap-south-1 `
    --query "pipelineExecutionSummaries[0].pipelineExecutionId" `
    --output text

Write-Host "Execution ID: $EXEC_ID"

aws codepipeline get-pipeline-execution `
    --pipeline-name my-web-app-pipeline `
    --pipeline-execution-id $EXEC_ID `
    --region ap-south-1 `
    --query "pipelineExecution.{Status:status,Trigger:trigger.triggerType}" `
    --output table

# ── CODEBUILD LOG TAIL ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Recent CodeBuild Log (last 20 lines) ---" -ForegroundColor Yellow
$LOG_STREAM = aws logs describe-log-streams `
    --log-group-name /aws/codebuild/my-web-app-build `
    --order-by LastEventTime `
    --descending `
    --max-items 1 `
    --region ap-south-1 `
    --query "logStreams[0].logStreamName" `
    --output text 2>$null

if ($LOG_STREAM -and $LOG_STREAM -ne "None") {
    aws logs get-log-events `
        --log-group-name /aws/codebuild/my-web-app-build `
        --log-stream-name $LOG_STREAM `
        --limit 20 `
        --region ap-south-1 `
        --query "events[*].message" `
        --output text
}
else {
    Write-Host "  No build logs yet — build may not have started."
}

# ── CODEDEPLOY DEPLOYMENTS ────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- CodeDeploy Deployment History ---" -ForegroundColor Yellow
aws deploy list-deployments `
    --application-name my-web-app `
    --deployment-group-name production `
    --region ap-south-1 `
    --query "deployments" `
    --output text | ForEach-Object {
    if ($_) {
        aws deploy get-deployment --deployment-id $_ --region ap-south-1 `
            --query "deploymentInfo.{ID:deploymentId,Status:status,Created:createTime}" `
            --output table
    }
}

# ── ALL EXECUTIONS ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Pipeline Execution History ---" -ForegroundColor Yellow
aws codepipeline list-pipeline-executions `
    --pipeline-name my-web-app-pipeline `
    --max-results 5 `
    --region ap-south-1 `
    --query "pipelineExecutionSummaries[*].{ID:pipelineExecutionId,Status:status,Trigger:trigger.triggerType,Started:startTime}" `
    --output table

Write-Host ""
Write-Host "=== Monitor Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Console path: CodePipeline → my-web-app-pipeline"
Write-Host "Re-run this script every 30s to watch progression: Source → Build → Deploy"