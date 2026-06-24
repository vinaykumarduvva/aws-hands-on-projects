# =============================================================================
# Project 7 — Script 05: Billing Alarm
# MUST run in us-east-1 — billing metrics are only in this region
# =============================================================================

Write-Host "=== Project 7 — Billing Alarm ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: Billing metrics are only available in us-east-1" -ForegroundColor Red
Write-Host "This script forces us-east-1 regardless of your configured region." -ForegroundColor Yellow
Write-Host ""

if (-not $SNS_ARN) {
    Write-Host "ERROR: SNS_ARN not set. Run 01-sns-setup.ps1 first." -ForegroundColor Red
    exit 1
}

# Force us-east-1 for billing metrics
$env:AWS_DEFAULT_REGION = "us-east-1"
Write-Host "Region forced to: us-east-1" -ForegroundColor Green
Write-Host ""

# ── BILLING ALARM ─────────────────────────────────────────────────────────────
Write-Host "Creating Billing-Alert-5USD alarm..." -ForegroundColor Yellow
Write-Host "Threshold: EstimatedCharges > USD 5.00 (daily evaluation)"
Write-Host ""

aws cloudwatch put-metric-alarm `
  --alarm-name "Billing-Alert-5USD" `
  --alarm-description "AWS monthly estimated charges exceeded USD 5 — check for unintended resources" `
  --namespace "AWS/Billing" `
  --metric-name "EstimatedCharges" `
  --dimensions Name=Currency,Value=USD `
  --statistic Maximum `
  --period 86400 `
  --evaluation-periods 1 `
  --threshold 5 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data notBreaching `
  --region us-east-1

Write-Host "Billing-Alert-5USD created." -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying billing alarm (us-east-1)..." -ForegroundColor Yellow

aws cloudwatch describe-alarms `
  --alarm-names "Billing-Alert-5USD" `
  --region us-east-1 `
  --query "MetricAlarms[0].{Name:AlarmName,State:StateValue,Threshold:Threshold,Namespace:Namespace}" `
  --output table

Write-Host ""
Write-Host "=== Billing Alarm Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Billing metrics update once per day."
Write-Host "The alarm may show INSUFFICIENT_DATA until the next daily metric update."
Write-Host ""
Write-Host "Console path: CloudWatch (us-east-1) -> Alarms -> Billing-Alert-5USD"
Write-Host ""
Write-Host "Next step: Run 06-generate-cpu-load.sh on the EC2 instance (via SSH)" -ForegroundColor Cyan