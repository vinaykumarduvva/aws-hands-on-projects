# =============================================================================
# Project 7 — Script 10: Push Test Log Events
# Simulates application logs with INFO and ERROR lines to trigger metric filter
# =============================================================================

Write-Host "=== Project 7 — Push Test Log Events ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pushing 8 log events (3 INFO + 5 ERROR) to simulate an error spike."
Write-Host "The metric filter will count the 5 ERROR lines."
Write-Host "App-Errors-High alarm threshold is > 5, so this tests near-threshold."
Write-Host ""
Write-Host "To guarantee the alarm fires: add more ERROR lines or lower threshold to >= 5."
Write-Host ""

$LOG_GROUP = "/aws/ec2/monitoring-test"
$LOG_STREAM = "app-server-1"

# Timestamps in milliseconds — each event 1 second apart
$BASE_TIME = [int64](Get-Date -UFormat %s) * 1000

# ── PUSH LOG EVENTS ───────────────────────────────────────────────────────────
Write-Host "Pushing log events to: $LOG_GROUP / $LOG_STREAM" -ForegroundColor Yellow
Write-Host ""

aws logs put-log-events `
    --log-group-name $LOG_GROUP `
    --log-stream-name $LOG_STREAM `
    --log-events `
    "timestamp=$($BASE_TIME),message=`"INFO: Application started successfully`"" `
    "timestamp=$($BASE_TIME+1000),message=`"INFO: User login successful - user_id=1042`"" `
    "timestamp=$($BASE_TIME+2000),message=`"ERROR: Database connection timeout after 30s - host=rds-endpoint`"" `
    "timestamp=$($BASE_TIME+3000),message=`"ERROR: Failed to process payment - transaction_id=TXN9981`"" `
    "timestamp=$($BASE_TIME+4000),message=`"ERROR: Null pointer exception in OrderService.processOrder()`"" `
    "timestamp=$($BASE_TIME+5000),message=`"ERROR: Authentication service unavailable - retrying`"" `
    "timestamp=$($BASE_TIME+6000),message=`"ERROR: Rate limit exceeded - IP=203.0.113.45`"" `
    "timestamp=$($BASE_TIME+7000),message=`"INFO: Retry attempt 1 of 3 - backoff 2s`""

Write-Host "Log events pushed successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Events sent:"
Write-Host "  INFO:  Application started successfully"
Write-Host "  INFO:  User login successful"
Write-Host "  ERROR: Database connection timeout"
Write-Host "  ERROR: Failed to process payment"
Write-Host "  ERROR: Null pointer exception"
Write-Host "  ERROR: Authentication service unavailable"
Write-Host "  ERROR: Rate limit exceeded"
Write-Host "  INFO:  Retry attempt 1 of 3"
Write-Host ""
Write-Host "Metric filter will count: 5 ERROR events" -ForegroundColor Yellow
Write-Host ""

# Push 2 more ERROR events to guarantee alarm fires (total = 7 > threshold of 5)
Write-Host "Pushing 2 additional ERROR events to guarantee alarm threshold breach (7 > 5)..." -ForegroundColor Yellow

$BASE_TIME2 = $BASE_TIME + 10000

aws logs put-log-events `
    --log-group-name $LOG_GROUP `
    --log-stream-name $LOG_STREAM `
    --log-events `
    "timestamp=$($BASE_TIME2),message=`"ERROR: Memory allocation failed - heap exhausted`"" `
    "timestamp=$($BASE_TIME2+1000),message=`"ERROR: Disk I/O error on /var/app/data`""

Write-Host "Additional ERROR events pushed. Total: 7 ERROR events" -ForegroundColor Green
Write-Host ""
Write-Host "=== Log Events Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Wait 5 minutes for the App-Errors-High alarm to evaluate."
Write-Host "Check alarm state:"
Write-Host "  aws cloudwatch describe-alarms --alarm-names App-Errors-High --query ""MetricAlarms[0].StateValue"" --output text"
Write-Host ""
Write-Host "Console path: CloudWatch -> Alarms -> App-Errors-High"
Write-Host ""
Write-Host "Next step: Run 11-verify-alarms.ps1" -ForegroundColor Cyan