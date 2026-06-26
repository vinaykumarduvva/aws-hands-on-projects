# =============================================================================
# Project 9 — Script 03: Create CodeCommit Repository and Push Code
# Creates managed Git repo and configures local git to push to it
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 9 — Create CodeCommit Repository ===" -ForegroundColor Cyan
Write-Host ""

# ── CREATE REPOSITORY ─────────────────────────────────────────────────────────
Write-Host "[1/3] Creating CodeCommit repository: my-web-app..." -ForegroundColor Yellow

aws codecommit create-repository `
    --repository-name my-web-app `
    --repository-description "CI/CD demo app for Project 9" `
    --tags Project=project-09-cicd `
    --region ap-south-1 | Out-Null

Write-Host "Repository created." -ForegroundColor Green

# ── GET CLONE URL ─────────────────────────────────────────────────────────────
$CLONE_URL = aws codecommit get-repository `
    --repository-name my-web-app `
    --query "repositoryMetadata.cloneUrlHttp" `
    --output text `
    --region ap-south-1

Write-Host "Clone URL: $CLONE_URL" -ForegroundColor Green

# ── GIT CONFIGURATION ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/3] Configuring Git credential helper for CodeCommit..." -ForegroundColor Yellow

git config --global credential.helper "!aws codecommit credential-helper `$@"
git config --global credential.UseHttpPath true

Write-Host "Git credential helper configured." -ForegroundColor Green

# ── INSTRUCTIONS FOR CODE PUSH ────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Ready to push application code." -ForegroundColor Yellow
Write-Host ""
Write-Host "Run these commands from your application directory:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  cd C:\Users\`$env:USERNAME\my-web-app"
Write-Host "  git init"
Write-Host "  git checkout -b main"
Write-Host "  # Copy application/ folder contents here"
Write-Host "  git add ."
Write-Host "  git commit -m `"feat: initial CI/CD demo app`""
Write-Host "  git remote add origin $CLONE_URL"
Write-Host "  git push -u origin main"
Write-Host ""
Write-Host "Or if using the application/ folder from this repo:"
Write-Host "  cd application"
Write-Host "  git init && git checkout -b main"
Write-Host "  git add ."
Write-Host "  git commit -m `"feat: initial CI/CD demo app`""
Write-Host "  git remote add origin $CLONE_URL"
Write-Host "  git push -u origin main"

# ── VERIFY AFTER PUSH ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "After pushing, verify with:" -ForegroundColor Yellow
Write-Host "  aws codecommit get-branch --repository-name my-web-app --branch-name main --region ap-south-1"

Write-Host ""
Write-Host "=== CodeCommit Setup Complete ===" -ForegroundColor Cyan
Write-Host "  CLONE_URL = $CLONE_URL"
Write-Host ""
Write-Host "Next step: Push your code, then run 04-launch-ec2.ps1" -ForegroundColor Cyan