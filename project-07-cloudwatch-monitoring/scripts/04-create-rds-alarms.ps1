# =============================================================================
# Project 7 — Script 04: RDS CloudWatch Alarms
# Creates CPU, storage, and connection alarms for myapp-database
# Note: Alarms stay INSUFFICIENT_DATA if RDS from Project 6 was deleted — this is normal
# =============================================================================

Write-Host "=== Project 7 — RDS CloudWatch Alarms ===" -ForegroundColor Cyan
Write-Host ""

if (-not $SNS_ARN) {
    Write-Host "ERROR: SNS_ARN not set. Run 01-sns-setup.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "Target RDS instance: myapp-database"
Write-Host "SNS ARN: $SNS_ARN"
Write-Host ""
Write-Host "Note: Alarms will be INSUFFICIENT_DATA if myapp-database does not exist."
Write-Host "This is expected if Project 6 was cleaned up. Alarms are still valid."
Write-Host ""

# ── ALARM 4: RDS HIGH CPU ─────────────────────────────────────────────────────
Write-Host "[1/3] Creating RDS-CPU-High alarm..." -ForegroundColor Yellow

aws cloudwatch put-metric-alarm `
  --alarm-name "RDS-CPU-High" `
  --alarm-description "RDS CPU utilization exceeded 80% for 10 minutes" `
  --namespace "AWS/RDS" `
  --metric-name "CPUUtilization" `
  --dimensions Name=DBInstanceIdentifier,Value=myapp-database `
  --statistic Average `
  --period 300 `
  --evaluation-periods 2 `
  --threshold 80 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --ok-actions $SNS_ARN `
  --treat-missing-data notBreaching

Write-Host "  RDS-CPU-High created (Average CPU > 80% for 2x5min)" -ForegroundColor Green

# ── ALARM 5: RDS LOW FREE STORAGE ─────────────────────────────────────────────
Write-Host "[2/3] Creating RDS-Storage-Low alarm..." -ForegroundColor Yellow

# Threshold: 2,000,000,000 bytes = ~2GB
aws cloudwatch put-metric-alarm `
  --alarm-name "RDS-Storage-Low" `
  --alarm-description "RDS free storage space below 2GB — action required before write failures" `
  --namespace "AWS/RDS" `
  --metric-name "FreeStorageSpace" `
  --dimensions Name=DBInstanceIdentifier,Value=myapp-database `
  --statistic Average `
  --period 300 `
  --evaluation-periods 1 `
  --threshold 2000000000 `
  --comparison-operator LessThanThreshold `
  --alarm-actions $SNS_ARN `
  --ok-actions $SNS_ARN `
  --treat-missing-data notBreaching

Write-Host "  RDS-Storage-Low created (FreeStorage < 2GB)" -ForegroundColor Green

# ── ALARM 6: RDS HIGH CONNECTIONS ─────────────────────────────────────────────
Write-Host "[3/3] Creating RDS-Connections-High alarm..." -ForegroundColor Yellow

# db.t3.micro max connections = 66; alert at 50 (76% of max)
aws cloudwatch put-metric-alarm `
  --alarm-name "RDS-Connections-High" `
  --alarm-description "RDS connection count exceeded 50 (db.t3.micro max: 66)" `
  --namespace "AWS/RDS" `
  --metric-name "DatabaseConnections" `
  --dimensions Name=DBInstanceIdentifier,Value=myapp-database `
  --statistic Average `
  --period 300 `
  --evaluation-periods 1 `
  --threshold 50 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data notBreaching

Write-Host "  RDS-Connections-High created (DatabaseConnections > 50)" -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying RDS alarms..." -ForegroundColor Yellow

aws cloudwatch describe-alarms `
  --alarm-names "RDS-CPU-High" "RDS-Storage-Low" "RDS-Connections-High" `
  --query "MetricAlarms[*].{Name:AlarmName,State:StateValue,Metric:MetricName,Threshold:Threshold}" `
  --output table

Write-Host ""
Write-Host "=== RDS Alarms Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next step: Run 05-create-billing-alarm.ps1" -ForegroundColor Cyan