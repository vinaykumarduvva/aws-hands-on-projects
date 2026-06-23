# =============================================================================
# Project 6 — Script 08: CloudWatch Monitoring
# Queries RDS metrics for the last hour — CPU, connections, storage
# =============================================================================

Write-Host "=== Project 6 — CloudWatch RDS Monitoring ===" -ForegroundColor Cyan
Write-Host ""

$START_TIME = (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
$END_TIME = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
$DB_ID = "myapp-database"

Write-Host "Query window: $START_TIME → $END_TIME"
Write-Host "DB Instance:  $DB_ID"
Write-Host ""

# ── CPU UTILIZATION ───────────────────────────────────────────────────────────
Write-Host "--- CPU Utilization (%) ---" -ForegroundColor Yellow
aws cloudwatch get-metric-statistics `
    --namespace AWS/RDS `
    --metric-name CPUUtilization `
    --dimensions Name=DBInstanceIdentifier, Value=$DB_ID `
    --start-time $START_TIME `
    --end-time $END_TIME `
    --period 300 `
    --statistics Average `
    --query "sort_by(Datapoints,&Timestamp)[*].{Time:Timestamp,CPU_Percent:Average}" `
    --output table

# ── DATABASE CONNECTIONS ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Database Connections (count) ---" -ForegroundColor Yellow
aws cloudwatch get-metric-statistics `
    --namespace AWS/RDS `
    --metric-name DatabaseConnections `
    --dimensions Name=DBInstanceIdentifier, Value=$DB_ID `
    --start-time $START_TIME `
    --end-time $END_TIME `
    --period 300 `
    --statistics Average `
    --query "sort_by(Datapoints,&Timestamp)[*].{Time:Timestamp,Connections:Average}" `
    --output table

# ── FREE STORAGE SPACE ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Free Storage Space (bytes) ---" -ForegroundColor Yellow
aws cloudwatch get-metric-statistics `
    --namespace AWS/RDS `
    --metric-name FreeStorageSpace `
    --dimensions Name=DBInstanceIdentifier, Value=$DB_ID `
    --start-time $START_TIME `
    --end-time $END_TIME `
    --period 300 `
    --statistics Average `
    --query "sort_by(Datapoints,&Timestamp)[*].{Time:Timestamp,Free_Bytes:Average}" `
    --output table

# ── FREEABLE MEMORY ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Freeable Memory (bytes) ---" -ForegroundColor Yellow
aws cloudwatch get-metric-statistics `
    --namespace AWS/RDS `
    --metric-name FreeableMemory `
    --dimensions Name=DBInstanceIdentifier, Value=$DB_ID `
    --start-time $START_TIME `
    --end-time $END_TIME `
    --period 300 `
    --statistics Average `
    --query "sort_by(Datapoints,&Timestamp)[*].{Time:Timestamp,Free_Bytes:Average}" `
    --output table

# ── READ IOPS ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Read IOPS ---" -ForegroundColor Yellow
aws cloudwatch get-metric-statistics `
    --namespace AWS/RDS `
    --metric-name ReadIOPS `
    --dimensions Name=DBInstanceIdentifier, Value=$DB_ID `
    --start-time $START_TIME `
    --end-time $END_TIME `
    --period 300 `
    --statistics Average `
    --query "sort_by(Datapoints,&Timestamp)[*].{Time:Timestamp,Read_IOPS:Average}" `
    --output table

# ── WRITE IOPS ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Write IOPS ---" -ForegroundColor Yellow
aws cloudwatch get-metric-statistics `
    --namespace AWS/RDS `
    --metric-name WriteIOPS `
    --dimensions Name=DBInstanceIdentifier, Value=$DB_ID `
    --start-time $START_TIME `
    --end-time $END_TIME `
    --period 300 `
    --statistics Average `
    --query "sort_by(Datapoints,&Timestamp)[*].{Time:Timestamp,Write_IOPS:Average}" `
    --output table

# ── CONSOLE SHORTCUT ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Monitoring Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Console path for visual graphs:"
Write-Host "  RDS -> Databases -> myapp-database -> Monitoring tab"
Write-Host ""
Write-Host "Note: If datapoints are empty, the instance has been idle."
Write-Host "Run a few queries via MySQL client to generate metrics."