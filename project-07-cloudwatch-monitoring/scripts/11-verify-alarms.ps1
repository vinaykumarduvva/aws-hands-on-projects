# =============================================================================
# Project 7 — Script 11: Verify All Alarms and Metrics
# Lists all alarms, queries metric data, and checks alarm history
# =============================================================================

Write-Host "=== Project 7 — Alarm Verification ===" -ForegroundColor Cyan
Write-Host ""

$START_TIME = (Get-Date).AddHours(-2).ToString("yyyy-MM-ddTHH:mm:ssZ")
$END_TIME   = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

# ── ALL ALARMS OVERVIEW ───────────────────────────────────────────────────────
Write-Host "--- All Alarms (current state) ---" -ForegroundColor Yellow
aws cloudwatch describe-alarms `
  --query "MetricAlarms[*].{Name:AlarmName,State:StateValue,Metric:MetricName,Threshold:Threshold,Namespace:Namespace}" `
  --output table

# ── ALARM COUNTS BY STATE ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Alarm State Summary ---" -ForegroundColor Yellow
$ALARMS = aws cloudwatch describe-alarms `
  --query "MetricAlarms[*].StateValue" --output text

$OK_COUNT    = ($ALARMS -split '\s+' | Where-Object {$_ -eq "OK"}).Count
$ALARM_COUNT = ($ALARMS -split '\s+' | Where-Object {$_ -eq "ALARM"}).Count
$INSUFF      = ($ALARMS -split '\s+' | Where-Object {$_ -eq "INSUFFICIENT_DATA"}).Count

Write-Host "  OK:                 $OK_COUNT"
Write-Host "  ALARM:              $ALARM_COUNT"
Write-Host "  INSUFFICIENT_DATA:  $INSUFF"

# ── EC2 CPU METRIC DATA ───────────────────────────────────────────────────────
if ($MON_INSTANCE_ID) {
    Write-Host ""
    Write-Host "--- EC2 CPU Utilization (last 2 hours) ---" -ForegroundColor Yellow
    aws cloudwatch get-metric-statistics `
      --namespace AWS/EC2 `
      --metric-name CPUUtilization `
      --dimensions Name=InstanceId,Value=$MON_INSTANCE_ID `
      --start-time $START_TIME `
      --end-time $END_TIME `
      --period 300 `
      --statistics Average Maximum `
      --query "sort_by(Datapoints,&Timestamp)[*].{Time:Timestamp,Avg:Average,Max:Maximum}" `
      --output table
}

# ── EC2-CPU-HIGH ALARM HISTORY ────────────────────────────────────────────────
Write-Host ""
Write-Host "--- EC2-CPU-High Alarm History ---" -ForegroundColor Yellow
aws cloudwatch describe-alarm-history `
  --alarm-name "EC2-CPU-High" `
  --query "AlarmHistoryItems[*].{Time:Timestamp,Type:HistoryItemType,Summary:HistorySummary}" `
  --output table

# ── APP-ERRORS-HIGH ALARM HISTORY ────────────────────────────────────────────
Write-Host ""
Write-Host "--- App-Errors-High Alarm History ---" -ForegroundColor Yellow
aws cloudwatch describe-alarm-history `
  --alarm-name "App-Errors-High" `
  --query "AlarmHistoryItems[*].{Time:Timestamp,Type:HistoryItemType,Summary:HistorySummary}" `
  --output table

# ── CUSTOM METRIC DATA ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- ApplicationErrors Custom Metric (last 2 hours) ---" -ForegroundColor Yellow
aws cloudwatch get-metric-statistics `
  --namespace CustomMetrics `
  --metric-name ApplicationErrors `
  --start-time $START_TIME `
  --end-time $END_TIME `
  --period 300 `
  --statistics Sum `
  --query "sort_by(Datapoints,&Timestamp)[*].{Time:Timestamp,Errors:Sum}" `
  --output table

# ── SNS TOPIC STATUS ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- SNS Subscription Status ---" -ForegroundColor Yellow
if ($SNS_ARN) {
    aws sns list-subscriptions-by-topic `
      --topic-arn $SNS_ARN `
      --query "Subscriptions[*].{Protocol:Protocol,Endpoint:Endpoint,Status:SubscriptionArn}" `
      --output table
} else {
    Write-Host "SNS_ARN not set — skipping."
}

# ── DASHBOARD STATUS ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Dashboard Status ---" -ForegroundColor Yellow
aws cloudwatch list-dashboards `
  --query "DashboardEntries[*].{Name:DashboardName,Modified:LastModified}" `
  --output table

Write-Host ""
Write-Host "=== Verification Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Expected states after full project build:"
Write-Host "  EC2-CPU-High             OK (or ALARM if stress test ran recently)"
Write-Host "  EC2-StatusCheck-Failed   OK"
Write-Host "  EC2-NetworkIn-High       OK"
Write-Host "  RDS-CPU-High             INSUFFICIENT_DATA (no RDS)"
Write-Host "  RDS-Storage-Low          INSUFFICIENT_DATA (no RDS)"
Write-Host "  RDS-Connections-High     INSUFFICIENT_DATA (no RDS)"
Write-Host "  Billing-Alert-5USD       OK"
Write-Host "  App-Errors-High          ALARM (after test log events pushed)"