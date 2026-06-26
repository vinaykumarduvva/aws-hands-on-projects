# =============================================================================
# Project 9 — Script 02: Create S3 Artifact Bucket
# CodePipeline stores build artifacts between stages in this bucket
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 9 — Create S3 Artifact Bucket ===" -ForegroundColor Cyan
Write-Host ""

$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
$ARTIFACT_BUCKET = "codepipeline-artifacts-$ACCOUNT_ID-ap-south-1"

Write-Host "Bucket name: $ARTIFACT_BUCKET" -ForegroundColor Yellow

# ── CREATE BUCKET ─────────────────────────────────────────────────────────────
Write-Host "[1/3] Creating bucket..." -ForegroundColor Yellow
aws s3api create-bucket `
    --bucket $ARTIFACT_BUCKET `
    --region ap-south-1 `
    --create-bucket-configuration LocationConstraint=ap-south-1

Write-Host "Bucket created." -ForegroundColor Green

# ── ENABLE VERSIONING ─────────────────────────────────────────────────────────
Write-Host "[2/3] Enabling versioning (required by CodePipeline)..." -ForegroundColor Yellow
aws s3api put-bucket-versioning `
    --bucket $ARTIFACT_BUCKET `
    --versioning-configuration Status=Enabled
Write-Host "Versioning enabled." -ForegroundColor Green

# ── BLOCK PUBLIC ACCESS ───────────────────────────────────────────────────────
Write-Host "[3/3] Blocking all public access..." -ForegroundColor Yellow
aws s3api put-public-access-block `
    --bucket $ARTIFACT_BUCKET `
    --public-access-block-configuration `
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
Write-Host "Public access blocked." -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
aws s3api get-bucket-versioning --bucket $ARTIFACT_BUCKET --query "Status" --output text

Write-Host ""
Write-Host "=== S3 Bucket Complete ===" -ForegroundColor Cyan
Write-Host "  ARTIFACT_BUCKET = $ARTIFACT_BUCKET"
Write-Host ""
Write-Host "Next step: Run 03-create-codecommit.ps1" -ForegroundColor Cyan