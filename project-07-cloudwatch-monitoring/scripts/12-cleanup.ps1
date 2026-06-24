# =============================================================================
# Project 7 — Script 12: Full Cleanup
# Deletes all monitoring project resources
# =============================================================================

Write-Host "=== Project 7 — Full Cleanup ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Deletes: all alarms, dashboard, log group, SNS, EC2" -ForegroundColor Red
Write-Host ""

# Re-fetch IDs in case session variables were lost
Write-Host "Re-fetching resource IDs..." -ForegroundColor Yellow

if (-not $SNS_ARN) {
    $SNS_ARN = aws sns list-topics `
      --query "Topics[?contains(TopicArn,'monitoring-alerts')].TopicArn | [0]" `
      --output text
}

if (-not $MON_INSTANCE_ID) {
    $MON_INSTANCE_ID = aws ec2 describe-instances `
      --filters "Name=tag:Name,Values=monitoring-test" `
      --query "Reservations[0].Instances[0].InstanceId" `
      --output text
}

if (-not $MON_SG) {
    $MON_SG = aws ec2 describe-security-groups `
      --filters "Name=group-name,Values=monitoring-test-sg" `
      --query "SecurityGroups[0].GroupId" `
      --output text
}

Write-Host "SNS:  $SNS_ARN"
Write-Host "EC2:  $MON_INSTANCE_ID"
Write-Host "SG:   $MON_SG"
Write-Host ""

# ── STEP 1: DELETE ALL CLOUDWATCH ALARMS ─────────────────────────────────────
Write-Host "[1/5] Deleting CloudWatch alarms..." -ForegroundColor Yellow

aws cloudwatch delete-alarms `
  --alarm-names `
    "EC2-CPU-High" `
    "EC2-StatusCheck-Failed" `
    "EC2-NetworkIn-High" `
    "RDS-CPU-High" `
    "RDS-Storage-Low" `
    "RDS-Connections-High" `
    "App-Errors-High"

# Billing alarm in us-east-1
aws cloudwatch delete-alarms `
  --alarm-names "Billing-Alert-5USD" `
  --region us-east-1

Write-Host "All alarms deleted." -ForegroundColor Green

# ── STEP 2: DELETE DASHBOARD ──────────────────────────────────────────────────
Write-Host "[2/5] Deleting CloudWatch dashboard..." -ForegroundColor Yellow

aws cloudwatch delete-dashboards `
  --dashboard-names "AWS-Bootcamp-Dashboard" 2>&1 | Out-Null

Write-Host "Dashboard deleted." -ForegroundColor Green

# ── STEP 3: DELETE LOG GROUP ──────────────────────────────────────────────────
Write-Host "[3/5] Deleting CloudWatch log group..." -ForegroundColor Yellow

aws logs delete-log-group `
  --log-group-name "/aws/ec2/monitoring-test" 2>&1 | Out-Null

Write-Host "Log group deleted." -ForegroundColor Green

# ── STEP 4: DELETE SNS ────────────────────────────────────────────────────────
Write-Host "[4/5] Deleting SNS topic and subscriptions..." -ForegroundColor Yellow

if ($SNS_ARN -and $SNS_ARN -ne "None") {
    $SUB_ARN = aws sns list-subscriptions-by-topic `
      --topic-arn $SNS_ARN `
      --query "Subscriptions[0].SubscriptionArn" `
      --output text

    if ($SUB_ARN -and $SUB_ARN -ne "PendingConfirmation" -and $SUB_ARN -ne "None") {
        aws sns unsubscribe --subscription-arn $SUB_ARN 2>&1 | Out-Null
        Write-Host "  Subscription unsubscribed."
    }

    aws sns delete-topic --topic-arn $SNS_ARN 2>&1 | Out-Null
    Write-Host "SNS topic deleted." -ForegroundColor Green
} else {
    Write-Host "SNS topic not found — skipping." -ForegroundColor Gray
}

# ── STEP 5: TERMINATE EC2 ─────────────────────────────────────────────────────
Write-Host "[5/5] Terminating EC2 instance and deleting security group..." -ForegroundColor Yellow

if ($MON_INSTANCE_ID -and $MON_INSTANCE_ID -ne "None") {
    aws ec2 terminate-instances --instance-ids $MON_INSTANCE_ID | Out-Null
    Write-Host "  Waiting for EC2 termination (~1-2 minutes)..." -ForegroundColor Yellow
    aws ec2 wait instance-terminated --instance-ids $MON_INSTANCE_ID
    Write-Host "  EC2 terminated."
}

if ($MON_SG -and $MON_SG -ne "None") {
    aws ec2 delete-security-group --group-id $MON_SG 2>&1 | Out-Null
    Write-Host "  Security group deleted."
}

Write-Host "EC2 and security group deleted." -ForegroundColor Green

# ── VERIFICATION ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Cleanup Verification ===" -ForegroundColor Cyan
Write-Host ""

$REMAINING = aws cloudwatch describe-alarms `
  --query "MetricAlarms[*].AlarmName" --output text
if (-not $REMAINING) {
    Write-Host "Alarms:    CLEARED" -ForegroundColor Green
} else {
    Write-Host "Alarms:    Still present — $REMAINING" -ForegroundColor Red
}

$DASH = aws cloudwatch list-dashboards `
  --query "DashboardEntries[*].DashboardName" --output text
if (-not $DASH) {
    Write-Host "Dashboard: CLEARED" -ForegroundColor Green
} else {
    Write-Host "Dashboard: Still present — $DASH" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Project 7 Cleanup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Cost impact: $0.00 — all resources were within free tier."