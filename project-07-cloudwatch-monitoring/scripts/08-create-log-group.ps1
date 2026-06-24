# =============================================================================
# Project 7 — Script 08: CloudWatch Log Group
# Creates log group with 7-day retention policy
# =============================================================================

Write-Host "=== Project 7 — CloudWatch Log Group ===" -ForegroundColor Cyan
Write-Host ""

$LOG_GROUP = "/aws/ec2/monitoring-test"

Write-Host "[1/3] Creating log group: $LOG_GROUP..." -ForegroundColor Yellow

aws logs create-log-group `
  --log-group-name $LOG_GROUP

if ($LASTEXITCODE -eq 0) {
    Write-Host "Log group created." -ForegroundColor Green
} else {
    Write-Host "Log group may already exist — continuing." -ForegroundColor Yellow
}

# ── SET RETENTION ─────────────────────────────────────────────────────────────
Write-Host "[2/3] Setting 7-day retention policy..." -ForegroundColor Yellow

aws logs put-retention-policy `
  --log-group-name $LOG_GROUP `
  --retention-in-days 7

Write-Host "Retention set to 7 days." -ForegroundColor Green

# ── CREATE LOG STREAM ─────────────────────────────────────────────────────────
Write-Host "[3/3] Creating log stream: app-server-1..." -ForegroundColor Yellow

aws logs create-log-stream `
  --log-group-name $LOG_GROUP `
  --log-stream-name "app-server-1"

Write-Host "Log stream created." -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying log group..." -ForegroundColor Yellow

aws logs describe-log-groups `
  --log-group-name-prefix "/aws/ec2" `
  --query "logGroups[*].{Name:logGroupName,Retention:retentionInDays,StoredBytes:storedBytes}" `
  --output table

Write-Host ""
Write-Host "=== Log Group Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Log Group:   $LOG_GROUP"
Write-Host "  Log Stream:  app-server-1"
Write-Host "  Retention:   7 days"
Write-Host ""
Write-Host "Next step: Run 09-create-metric-filter.ps1" -ForegroundColor Cyan