# =============================================================================
# Project 6 — Script 09: RDS Operations
# Covers describe, snapshot, stop, start, and modify operations
# =============================================================================

Write-Host "=== Project 6 — RDS Operations ===" -ForegroundColor Cyan
Write-Host ""

$DB_ID = "myapp-database"

# ── DESCRIBE INSTANCE ─────────────────────────────────────────────────────────
Write-Host "--- Instance Details ---" -ForegroundColor Yellow
aws rds describe-db-instances `
    --db-instance-identifier $DB_ID `
    --query "DBInstances[0].{
    ID:DBInstanceIdentifier,
    Class:DBInstanceClass,
    Engine:Engine,
    EngineVersion:EngineVersion,
    Status:DBInstanceStatus,
    Endpoint:Endpoint.Address,
    Port:Endpoint.Port,
    Storage_GiB:AllocatedStorage,
    StorageType:StorageType,
    PublicAccess:PubliclyAccessible,
    MultiAZ:MultiAZ,
    BackupRetentionDays:BackupRetentionPeriod,
    Encrypted:StorageEncrypted,
    AZ:AvailabilityZone
  }" `
    --output table

# ── CREATE MANUAL SNAPSHOT ────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Creating Manual Snapshot ---" -ForegroundColor Yellow

$SNAPSHOT_ID = "myapp-manual-snapshot-$(Get-Date -Format 'yyyyMMdd-HHmm')"
Write-Host "Snapshot ID: $SNAPSHOT_ID"

aws rds create-db-snapshot `
    --db-instance-identifier $DB_ID `
    --db-snapshot-identifier $SNAPSHOT_ID | Out-Null

Write-Host "Snapshot creation initiated." -ForegroundColor Green
Write-Host "(Snapshot takes a few minutes — check status in RDS console)"

# ── LIST ALL SNAPSHOTS ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- All Snapshots for $DB_ID ---" -ForegroundColor Yellow
aws rds describe-db-snapshots `
    --db-instance-identifier $DB_ID `
    --query "DBSnapshots[*].{ID:DBSnapshotIdentifier,Status:Status,Type:SnapshotType,Created:SnapshotCreateTime,Size_GiB:AllocatedStorage}" `
    --output table

# ── MODIFY BACKUP RETENTION ───────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Modifying Backup Retention to 3 days ---" -ForegroundColor Yellow

aws rds modify-db-instance `
    --db-instance-identifier $DB_ID `
    --backup-retention-period 3 `
    --apply-immediately | Out-Null

Write-Host "Backup retention updated to 3 days." -ForegroundColor Green

# ── SHOW EVENTS ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- Recent RDS Events ---" -ForegroundColor Yellow
aws rds describe-events `
    --source-identifier $DB_ID `
    --source-type db-instance `
    --duration 60 `
    --query "Events[*].{Time:Date,Message:Message}" `
    --output table

# ── STOP INSTANCE (OPTIONAL / COST SAVING) ───────────────────────────────────
Write-Host ""
Write-Host "--- Stop / Start Commands (for reference) ---" -ForegroundColor Yellow
Write-Host ""
Write-Host "To STOP RDS (saves cost — max 7 days, then auto-starts):"
Write-Host "  aws rds stop-db-instance --db-instance-identifier $DB_ID"
Write-Host ""
Write-Host "To START RDS after stopping:"
Write-Host "  aws rds start-db-instance --db-instance-identifier $DB_ID"
Write-Host ""
Write-Host "NOTE: Do not stop if you plan to keep using it today."
Write-Host "      For permanent removal, use the cleanup script instead."
Write-Host ""
Write-Host "=== RDS Operations Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next step: When done with the project, run 10-cleanup.ps1" -ForegroundColor Cyan