# =============================================================================
# Project 10 — Script 10: Simulate Instance Failure
# Terminates an instance to demonstrate ASG self-healing
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Simulate Instance Failure ===" -ForegroundColor Cyan
Write-Host ""

# ── GET CURRENT INSTANCES ─────────────────────────────────────────────────────
Write-Host "[1/3] Getting current ASG instances..." -ForegroundColor Yellow

$INSTANCES = aws autoscaling describe-auto-scaling-groups `
    --auto-scaling-group-names web-server-asg `
    --query "AutoScalingGroups[0].Instances[*].InstanceId" `
    --output text

$INSTANCE_LIST = $INSTANCES -split '\s+'
Write-Host "  Current instances: $($INSTANCE_LIST -join ', ')" -ForegroundColor Green

$FAILED_INSTANCE = $INSTANCE_LIST[0]
Write-Host "  Instance to terminate (simulate failure): $FAILED_INSTANCE" -ForegroundColor Red
Write-Host ""

# ── SHOW BEFORE STATE ─────────────────────────────────────────────────────────
Write-Host "[2/3] Before failure — current state:" -ForegroundColor Yellow
aws autoscaling describe-auto-scaling-groups `
    --auto-scaling-group-names web-server-asg `
    --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus,AZ:AvailabilityZone}" `
    --output table

# ── TERMINATE INSTANCE ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Terminating instance: $FAILED_INSTANCE" -ForegroundColor Red
Write-Host "  ASG will detect the failure and launch a replacement..." -ForegroundColor Yellow

aws ec2 terminate-instances --instance-ids $FAILED_INSTANCE | Out-Null

Write-Host "  Termination initiated!" -ForegroundColor Red
Write-Host ""

# ── MONITOR SELF-HEALING ──────────────────────────────────────────────────────
Write-Host "=== Monitoring Self-Healing (Ctrl+C to stop) ===" -ForegroundColor Yellow
Write-Host "  Expected: ASG detects failure → launches new instance → registers in ALB" -ForegroundColor Yellow
Write-Host ""

$iterations = 0
$maxIterations = 20  # Monitor for ~10 minutes

while ($iterations -lt $maxIterations) {
    $iterations++

    $timestamp = Get-Date -Format 'HH:mm:ss'

    $asg = aws autoscaling describe-auto-scaling-groups `
        --auto-scaling-group-names web-server-asg `
        --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus}" `
        --output json | ConvertFrom-Json

    Write-Host "$timestamp — Instance Count: $($asg.Count)" -ForegroundColor White
    $asg | ForEach-Object {
        $stateColor = switch ($_.State) {
            "InService" { "Green" }
            "Pending" { "Yellow" }
            "Terminating" { "Red" }
            default { "Gray" }
        }
        $isNew = if ($_.ID -ne $FAILED_INSTANCE -and $_.State -eq "Pending") { " ← NEW" } else { "" }
        Write-Host "  $($_.ID): $($_.State) ($($_.Health))$isNew" -ForegroundColor $stateColor
    }
    Write-Host ""

    # Check if we have all healthy instances back
    $healthyCount = ($asg | Where-Object { $_.State -eq "InService" }).Count
    if ($healthyCount -ge 2 -and $iterations -gt 2) {
        Write-Host "  Self-healing complete! All instances InService." -ForegroundColor Green
        break
    }

    Start-Sleep -Seconds 30
}

# ── FINAL STATE ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Final State After Self-Healing ===" -ForegroundColor Cyan
aws autoscaling describe-auto-scaling-groups `
    --auto-scaling-group-names web-server-asg `
    --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus,AZ:AvailabilityZone}" `
    --output table

Write-Host ""
Write-Host "  Key takeaway: ASG automatically replaced the failed instance." -ForegroundColor Yellow
Write-Host "  The ALB routed traffic to the healthy instance during replacement." -ForegroundColor Yellow
Write-Host "  Zero manual intervention required!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run 11-cleanup.ps1" -ForegroundColor Cyan
