# =============================================================================
# Project 10 — Script 08: Verify and Test
# Checks target health, tests load balancing, opens browser
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Verify and Test ===" -ForegroundColor Cyan
Write-Host ""

# ── PRE-REQUISITES ────────────────────────────────────────────────────────────
$TG_ARN = aws elbv2 describe-target-groups `
    --names web-server-tg `
    --query "TargetGroups[0].TargetGroupArn" --output text

$ALB_DNS = aws elbv2 describe-load-balancers `
    --names my-alb `
    --query "LoadBalancers[0].DNSName" --output text

Write-Host "  Target Group: $TG_ARN" -ForegroundColor Green
Write-Host "  ALB DNS:      $ALB_DNS" -ForegroundColor Green
Write-Host ""

# ── CHECK TARGET HEALTH ──────────────────────────────────────────────────────
Write-Host "[1/4] Checking target group health..." -ForegroundColor Yellow
Write-Host "  Waiting for targets to become healthy (polling every 15s)..." -ForegroundColor Yellow

$maxAttempts = 20
$attempt = 0
$allHealthy = $false

while (-not $allHealthy -and $attempt -lt $maxAttempts) {
    $attempt++
    $healthData = aws elbv2 describe-target-health `
        --target-group-arn $TG_ARN `
        --query "TargetHealthDescriptions[*].{Instance:Target.Id,State:TargetHealth.State}" `
        --output json | ConvertFrom-Json

    $healthyCount = ($healthData | Where-Object { $_.State -eq "healthy" }).Count
    $totalCount = $healthData.Count

    Write-Host "  Attempt $attempt`: $healthyCount/$totalCount healthy" -ForegroundColor $(if ($healthyCount -eq $totalCount -and $totalCount -gt 0) { "Green" } else { "Yellow" })

    if ($healthyCount -eq $totalCount -and $totalCount -gt 0) {
        $allHealthy = $true
    }
    else {
        Start-Sleep -Seconds 15
    }
}

if ($allHealthy) {
    Write-Host "  All targets healthy!" -ForegroundColor Green
}
else {
    Write-Host "  Timeout — some targets may still be initializing." -ForegroundColor Red
}

# ── DISPLAY TARGET HEALTH TABLE ───────────────────────────────────────────────
Write-Host ""
Write-Host "[2/4] Target health status:" -ForegroundColor Yellow
aws elbv2 describe-target-health `
    --target-group-arn $TG_ARN `
    --query "TargetHealthDescriptions[*].{Instance:Target.Id,Port:Target.Port,State:TargetHealth.State}" `
    --output table

# ── CHECK ASG INSTANCES ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/4] ASG instance status:" -ForegroundColor Yellow
aws autoscaling describe-auto-scaling-groups `
    --auto-scaling-group-names web-server-asg `
    --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,AZ:AvailabilityZone,State:LifecycleState,Health:HealthStatus}" `
    --output table

# ── TEST LOAD BALANCING ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "[4/4] Testing load balancing (5 requests)..." -ForegroundColor Yellow
Write-Host "  URL: http://$ALB_DNS" -ForegroundColor Green
Write-Host ""

1..5 | ForEach-Object {
    try {
        $response = Invoke-WebRequest -Uri "http://$ALB_DNS" -UseBasicParsing -TimeoutSec 10
        $instanceId = [regex]::Match($response.Content, 'i-[0-9a-f]{8,17}').Value
        $statusCode = $response.StatusCode
        Write-Host "  Request $_`: Status $statusCode | Instance: $instanceId" -ForegroundColor Green
    }
    catch {
        Write-Host "  Request $_`: FAILED — $($_.Exception.Message)" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 500
}

# ── OPEN BROWSER ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Opening ALB in browser..." -ForegroundColor Yellow
Start-Process "http://$ALB_DNS"

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Verification Complete ===" -ForegroundColor Cyan
Write-Host "  ALB URL: http://$ALB_DNS"
Write-Host ""
Write-Host "  Refresh the browser multiple times — you should see different" -ForegroundColor Yellow
Write-Host "  Instance IDs and Availability Zones on each refresh." -ForegroundColor Yellow
Write-Host "  This proves the ALB is distributing traffic across instances." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run 09-test-auto-scaling.ps1" -ForegroundColor Cyan
