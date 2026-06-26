# =============================================================================
# Project 9 — Script 09: Trigger New Deployment (Version 2.0)
# Edits index.html, commits, pushes — watches pipeline auto-trigger
# =============================================================================

Write-Host "=== Project 9 — Trigger Version 2.0 Deployment ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script demonstrates the full CI/CD loop:" -ForegroundColor Yellow
Write-Host "  1. Edit source code (Version 1.0 → Version 2.0)"
Write-Host "  2. git push to CodeCommit"
Write-Host "  3. Pipeline auto-triggers (CloudWatch Events)"
Write-Host "  4. CodeBuild validates and packages"
Write-Host "  5. CodeDeploy pushes to EC2"
Write-Host "  6. Web app shows Version 2.0"
Write-Host ""

# ── SET APPLICATION DIRECTORY ─────────────────────────────────────────────────
# Point this at wherever you cloned the CodeCommit repo locally
$APP_DIR = "C:\Users\$env:USERNAME\my-web-app"

if (-not (Test-Path $APP_DIR)) {
    Write-Host "ERROR: Application directory not found: $APP_DIR" -ForegroundColor Red
    Write-Host "Adjust the APP_DIR variable to your local CodeCommit clone path."
    exit 1
}

Set-Location $APP_DIR

# ── EDIT index.html ───────────────────────────────────────────────────────────
Write-Host "[1/3] Updating Version 1.0 → Version 2.0 in index.html..." -ForegroundColor Yellow

$CURRENT = Get-Content index.html -Raw
if ($CURRENT -match "Version 1\.0") {
    (Get-Content index.html) -replace 'Version 1\.0', 'Version 2.0' | Set-Content index.html
    Write-Host "index.html updated." -ForegroundColor Green
}
elseif ($CURRENT -match "Version 2\.0") {
    Write-Host "Already on Version 2.0 — bumping to Version 3.0 for this push..."
    (Get-Content index.html) -replace 'Version 2\.0', 'Version 3.0' | Set-Content index.html
}
else {
    Write-Host "WARNING: Version string not found. Check index.html manually."
}

# ── GIT COMMIT AND PUSH ───────────────────────────────────────────────────────
Write-Host "[2/3] Committing and pushing to CodeCommit..." -ForegroundColor Yellow

git add index.html
git commit -m "feat: update to version 2.0 — triggers pipeline"
git push origin main

Write-Host "Push complete." -ForegroundColor Green

# ── WATCH PIPELINE ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Pipeline should auto-trigger within 30 seconds." -ForegroundColor Yellow
Write-Host "Waiting 30 seconds, then polling status..." -ForegroundColor Yellow

Start-Sleep -Seconds 30

# Poll until completion or 10 minutes
$MAX_CHECKS = 20
$CHECK = 0
$PIPELINE_DONE = $false

while ($CHECK -lt $MAX_CHECKS -and -not $PIPELINE_DONE) {
    $CHECK++
    $STATE = aws codepipeline get-pipeline-state `
        --name my-web-app-pipeline `
        --region ap-south-1 `
        --query "stageStates[*].{Stage:stageName,Status:latestExecution.status}" `
        --output json | ConvertFrom-Json

    Write-Host "--- Check $CHECK / $MAX_CHECKS ---" -ForegroundColor Cyan
    $STATE | ForEach-Object {
        $COLOR = switch ($_.Status) {
            "Succeeded" { "Green" }
            "Failed" { "Red" }
            "InProgress" { "Yellow" }
            default { "Gray" }
        }
        Write-Host "  $($_.Stage): $($_.Status)" -ForegroundColor $COLOR
    }

    $STATUSES = $STATE | Select-Object -ExpandProperty Status
    if ($STATUSES -contains "Failed") {
        Write-Host ""
        Write-Host "PIPELINE FAILED — check CodePipeline console for details." -ForegroundColor Red
        $PIPELINE_DONE = $true
    }
    elseif ($STATUSES -notcontains "InProgress" -and $STATUSES -contains "Succeeded") {
        Write-Host ""
        Write-Host "PIPELINE SUCCEEDED — deployment complete!" -ForegroundColor Green
        $PIPELINE_DONE = $true
    }
    else {
        Write-Host "  (still running — waiting 30s...)" -ForegroundColor Gray
        Start-Sleep -Seconds 30
    }
}

# ── VERIFY APP ────────────────────────────────────────────────────────────────
if ($DEPLOY_PUBLIC_IP) {
    Write-Host ""
    Write-Host "Opening browser to verify deployment:" -ForegroundColor Yellow
    Write-Host "  http://$DEPLOY_PUBLIC_IP"
    Start-Process "http://$DEPLOY_PUBLIC_IP"
}
else {
    Write-Host ""
    Write-Host "Set `$DEPLOY_PUBLIC_IP to open the app in browser."
}

Write-Host ""
Write-Host "=== Version 2.0 Deployment Triggered ===" -ForegroundColor Cyan