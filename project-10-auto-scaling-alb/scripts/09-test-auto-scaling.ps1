# =============================================================================
# Project 10 — Script 09: Test Auto Scaling
# Generates CPU load to trigger scale-out, monitors instance count
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Test Auto Scaling ===" -ForegroundColor Cyan
Write-Host ""

# ── GET INSTANCE IDs ──────────────────────────────────────────────────────────
$INSTANCE_IDS = aws autoscaling describe-auto-scaling-groups `
    --auto-scaling-group-names web-server-asg `
    --query "AutoScalingGroups[0].Instances[*].InstanceId" `
    --output text

$INSTANCE1 = ($INSTANCE_IDS -split '\s+')[0]
Write-Host "  Target instance for stress test: $INSTANCE1" -ForegroundColor Green
Write-Host ""

# ── OPTION 1: SSH + STRESS ────────────────────────────────────────────────────
Write-Host "=== Option 1: SSH Stress Test ===" -ForegroundColor Yellow
Write-Host "  Connect via SSM Session Manager:" -ForegroundColor Yellow
Write-Host "    aws ssm start-session --target $INSTANCE1" -ForegroundColor White
Write-Host ""
Write-Host "  Then run inside the session:" -ForegroundColor Yellow
Write-Host "    sudo stress --cpu 1 --timeout 600 &" -ForegroundColor White
Write-Host "    top  (to verify stress is running)" -ForegroundColor White
Write-Host ""

# ── OPTION 2: MANUAL SCALE ───────────────────────────────────────────────────
Write-Host "=== Option 2: Manual Scale Test ===" -ForegroundColor Yellow
Write-Host "  Scale up to 3 instances:" -ForegroundColor Yellow
Write-Host "    aws autoscaling set-desired-capacity --auto-scaling-group-name web-server-asg --desired-capacity 3" -ForegroundColor White
Write-Host ""
Write-Host "  Scale back down:" -ForegroundColor Yellow
Write-Host "    aws autoscaling set-desired-capacity --auto-scaling-group-name web-server-asg --desired-capacity 2" -ForegroundColor White
Write-Host ""

# ── MONITOR ASG ───────────────────────────────────────────────────────────────
Write-Host "=== Monitoring ASG (Ctrl+C to stop) ===" -ForegroundColor Yellow
Write-Host ""

$iterations = 0
$maxIterations = 40  # Monitor for ~20 minutes

while ($iterations -lt $maxIterations) {
    $iterations++

    $asg = aws autoscaling describe-auto-scaling-groups `
        --auto-scaling-group-names web-server-asg `
        --query "AutoScalingGroups[0].{
          Desired:DesiredCapacity,
          Instances:Instances[*].{ID:InstanceId,State:LifecycleState}}" `
        --output json | ConvertFrom-Json

    $timestamp = Get-Date -Format 'HH:mm:ss'
    $instanceCount = $asg.Instances.Count
    $desired = $asg.Desired

    # Color based on change
    $color = if ($instanceCount -gt 2) { "Green" } else { "White" }

    Write-Host "$timestamp — Instances: $instanceCount (Desired: $desired)" -ForegroundColor $color
    $asg.Instances | ForEach-Object {
        $stateColor = switch ($_.State) {
            "InService" { "Green" }
            "Pending" { "Yellow" }
            default { "Red" }
        }
        Write-Host "  $($_.ID): $($_.State)" -ForegroundColor $stateColor
    }
    Write-Host ""

    Start-Sleep -Seconds 30
}

Write-Host ""
Write-Host "=== Monitoring Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Check scaling history:" -ForegroundColor Yellow
Write-Host "    aws autoscaling describe-scaling-activities --auto-scaling-group-name web-server-asg --query ""Activities[0:5].[StartTime,Cause,StatusCode]"" --output table" -ForegroundColor White
Write-Host ""
Write-Host "Next step: Run 10-simulate-failure.ps1 OR 11-cleanup.ps1" -ForegroundColor Cyan
