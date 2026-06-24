# =============================================================================
# Project 7 — Script 03: EC2 CloudWatch Alarms
# Creates CPU, StatusCheck, and NetworkIn alarms for the monitoring EC2 instance
# =============================================================================

Write-Host "=== Project 7 — EC2 CloudWatch Alarms ===" -ForegroundColor Cyan
Write-Host ""

if (-not $MON_INSTANCE_ID -or -not $SNS_ARN) {
    Write-Host "ERROR: MON_INSTANCE_ID or SNS_ARN not set." -ForegroundColor Red
    Write-Host "Run 01-sns-setup.ps1 and 02-launch-monitoring-ec2.ps1 first."
    exit 1
}

Write-Host "Instance: $MON_INSTANCE_ID"
Write-Host "SNS ARN:  $SNS_ARN"
Write-Host ""

# ── ALARM 1: EC2 HIGH CPU ─────────────────────────────────────────────────────
Write-Host "[1/3] Creating EC2-CPU-High alarm..." -ForegroundColor Yellow

aws cloudwatch put-metric-alarm `
  --alarm-name "EC2-CPU-High" `
  --alarm-description "EC2 CPU utilization exceeded 70% for 10 minutes" `
  --namespace "AWS/EC2" `
  --metric-name "CPUUtilization" `
  --dimensions Name=InstanceId,Value=$MON_INSTANCE_ID `
  --statistic Average `
  --period 300 `
  --evaluation-periods 2 `
  --threshold 70 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --ok-actions $SNS_ARN `
  --treat-missing-data notBreaching

Write-Host "  EC2-CPU-High created (Average CPU > 70% for 2x5min)" -ForegroundColor Green

# ── ALARM 2: STATUS CHECK FAILED ──────────────────────────────────────────────
Write-Host "[2/3] Creating EC2-StatusCheck-Failed alarm..." -ForegroundColor Yellow

aws cloudwatch put-metric-alarm `
  --alarm-name "EC2-StatusCheck-Failed" `
  --alarm-description "EC2 instance failed status check — hardware or OS issue" `
  --namespace "AWS/EC2" `
  --metric-name "StatusCheckFailed" `
  --dimensions Name=InstanceId,Value=$MON_INSTANCE_ID `
  --statistic Maximum `
  --period 60 `
  --evaluation-periods 2 `
  --threshold 1 `
  --comparison-operator GreaterThanOrEqualToThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data notBreaching

Write-Host "  EC2-StatusCheck-Failed created (Maximum >= 1 for 2x1min)" -ForegroundColor Green

# ── ALARM 3: HIGH NETWORK IN ──────────────────────────────────────────────────
Write-Host "[3/3] Creating EC2-NetworkIn-High alarm..." -ForegroundColor Yellow

aws cloudwatch put-metric-alarm `
  --alarm-name "EC2-NetworkIn-High" `
  --alarm-description "EC2 inbound network traffic unusually high — potential anomaly" `
  --namespace "AWS/EC2" `
  --metric-name "NetworkIn" `
  --dimensions Name=InstanceId,Value=$MON_INSTANCE_ID `
  --statistic Average `
  --period 300 `
  --evaluation-periods 1 `
  --threshold 5000000 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data notBreaching

Write-Host "  EC2-NetworkIn-High created (Average > 5MB per 5min)" -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying EC2 alarms..." -ForegroundColor Yellow

aws cloudwatch describe-alarms `
  --alarm-names "EC2-CPU-High" "EC2-StatusCheck-Failed" "EC2-NetworkIn-High" `
  --query "MetricAlarms[*].{Name:AlarmName,State:StateValue,Metric:MetricName,Threshold:Threshold}" `
  --output table

Write-Host ""
Write-Host "=== EC2 Alarms Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Expected states: INSUFFICIENT_DATA (until first metric data points arrive)"
Write-Host "States transition to OK within 5-10 minutes of instance running."
Write-Host ""
Write-Host "Next step: Run 04-create-rds-alarms.ps1" -ForegroundColor Cyan