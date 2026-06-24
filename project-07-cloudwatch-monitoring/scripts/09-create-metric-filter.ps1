# =============================================================================
# Project 7 — Script 09: Metric Filter + Custom Alarm
# Creates a metric filter that counts ERROR log lines, then alarms on it
# =============================================================================

Write-Host "=== Project 7 — Metric Filter and Custom Alarm ===" -ForegroundColor Cyan
Write-Host ""

if (-not $SNS_ARN) {
    Write-Host "ERROR: SNS_ARN not set. Run 01-sns-setup.ps1 first." -ForegroundColor Red
    exit 1
}

$LOG_GROUP = "/aws/ec2/monitoring-test"

# ── CREATE METRIC FILTER ──────────────────────────────────────────────────────
Write-Host "[1/2] Creating metric filter 'ErrorCount'..." -ForegroundColor Yellow
Write-Host "  Pattern:          ERROR (case-sensitive)"
Write-Host "  Metric namespace: CustomMetrics"
Write-Host "  Metric name:      ApplicationErrors"
Write-Host "  On match:         increment by 1"
Write-Host "  Default value:    0 (prevents INSUFFICIENT_DATA gaps)"
Write-Host ""

aws logs put-metric-filter `
  --log-group-name $LOG_GROUP `
  --filter-name "ErrorCount" `
  --filter-pattern "ERROR" `
  --metric-transformations `
    metricName=ApplicationErrors,metricNamespace=CustomMetrics,metricValue=1,defaultValue=0

Write-Host "Metric filter created." -ForegroundColor Green

# ── CREATE ALARM ON CUSTOM METRIC ─────────────────────────────────────────────
Write-Host ""
Write-Host "[2/2] Creating App-Errors-High alarm on CustomMetrics/ApplicationErrors..." -ForegroundColor Yellow

aws cloudwatch put-metric-alarm `
  --alarm-name "App-Errors-High" `
  --alarm-description "Application error rate exceeded 5 errors in a 5-minute window" `
  --namespace "CustomMetrics" `
  --metric-name "ApplicationErrors" `
  --statistic Sum `
  --period 300 `
  --evaluation-periods 1 `
  --threshold 5 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data notBreaching

Write-Host "App-Errors-High alarm created." -ForegroundColor Green

# ── VERIFY FILTER ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying metric filter..." -ForegroundColor Yellow

aws logs describe-metric-filters `
  --log-group-name $LOG_GROUP `
  --query "metricFilters[*].{Name:filterName,Pattern:filterPattern,Metric:metricTransformations[0].metricName}" `
  --output table

Write-Host ""
Write-Host "=== Metric Filter and Alarm Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pipeline:"
Write-Host "  Log Group (/aws/ec2/monitoring-test)"
Write-Host "    -> Metric Filter (ErrorCount, pattern: 'ERROR')"
Write-Host "    -> Custom Metric (CustomMetrics/ApplicationErrors)"
Write-Host "    -> Alarm (App-Errors-High, threshold: Sum > 5 per 5min)"
Write-Host "    -> SNS -> Email"
Write-Host ""
Write-Host "Next step: Run 10-test-log-events.ps1 to push test ERROR log lines" -ForegroundColor Cyan