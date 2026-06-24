# =============================================================================
# Project 7 — Script 01: SNS Topic and Email Subscription
# Creates the notification hub — all alarms route through this topic
# =============================================================================

Write-Host "=== Project 7 — SNS Setup ===" -ForegroundColor Cyan
Write-Host ""

# Pre-flight
aws sts get-caller-identity | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: AWS CLI not configured." -ForegroundColor Red
    exit 1
}

$REGION = aws configure get region
Write-Host "Region: $REGION"
Write-Host ""

# ── CREATE SNS TOPIC ──────────────────────────────────────────────────────────
Write-Host "[1/3] Creating SNS topic: monitoring-alerts..." -ForegroundColor Yellow

$SNS_ARN = aws sns create-topic `
    --name monitoring-alerts `
    --attributes DisplayName="AWS Monitoring" `
    --query "TopicArn" --output text

Write-Host "SNS Topic ARN: $SNS_ARN" -ForegroundColor Green

# ── CREATE EMAIL SUBSCRIPTION ─────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/3] Creating email subscription..." -ForegroundColor Yellow
Write-Host "Update the email address below before running this script."
Write-Host ""

# ⚠️ Replace this with your actual email address
$EMAIL = "your-email@gmail.com"

aws sns subscribe `
    --topic-arn $SNS_ARN `
    --protocol email `
    --notification-endpoint $EMAIL | Out-Null

Write-Host "Subscription created for: $EMAIL" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: Check your inbox and click 'Confirm subscription'" -ForegroundColor Red
Write-Host "Check spam/junk folder if not received within 2 minutes." -ForegroundColor Yellow

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Verifying subscription status..." -ForegroundColor Yellow

aws sns list-subscriptions-by-topic `
    --topic-arn $SNS_ARN `
    --query "Subscriptions[*].{Protocol:Protocol,Endpoint:Endpoint,Status:SubscriptionArn}" `
    --output table

Write-Host ""
Write-Host "=== SNS Setup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  SNS_ARN = $SNS_ARN"
Write-Host ""
Write-Host "Status will show 'PendingConfirmation' until you click the email link."
Write-Host "Alarms cannot send email until the subscription is confirmed."
Write-Host ""
Write-Host "Next step: Run 02-launch-monitoring-ec2.ps1" -ForegroundColor Cyan