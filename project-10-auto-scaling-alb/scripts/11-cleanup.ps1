# =============================================================================
# Project 10 — Script 11: Cleanup
# Tears down all resources: ASG, ALB, Target Group, Launch Template, SGs
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Full Cleanup ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  This will delete ALL resources created in Project 10." -ForegroundColor Red
Write-Host ""

# ── GATHER RESOURCE IDs ──────────────────────────────────────────────────────
$VPC_ID = aws ec2 describe-vpcs `
    --filters "Name=isDefault,Values=true" `
    --query "Vpcs[0].VpcId" --output text

# ── STEP 1: SCALE ASG TO 0 ───────────────────────────────────────────────────
Write-Host "[1/6] Scaling ASG to 0 instances..." -ForegroundColor Yellow
try {
    aws autoscaling update-auto-scaling-group `
        --auto-scaling-group-name web-server-asg `
        --min-size 0 --max-size 0 --desired-capacity 0 2>$null
    Write-Host "  Scaling down to 0..." -ForegroundColor Green
    Start-Sleep -Seconds 30
}
catch {
    Write-Host "  ASG not found or already deleted." -ForegroundColor Gray
}

# ── STEP 2: DELETE ASG ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/6] Deleting Auto Scaling Group..." -ForegroundColor Yellow
try {
    aws autoscaling delete-auto-scaling-group `
        --auto-scaling-group-name web-server-asg `
        --force-delete 2>$null
    Write-Host "  ASG deleted." -ForegroundColor Green
    Start-Sleep -Seconds 15
}
catch {
    Write-Host "  ASG not found or already deleted." -ForegroundColor Gray
}

# ── STEP 3: DELETE ALB AND LISTENER ───────────────────────────────────────────
Write-Host ""
Write-Host "[3/6] Deleting ALB and listener..." -ForegroundColor Yellow
try {
    $ALB_ARN = aws elbv2 describe-load-balancers `
        --names my-alb `
        --query "LoadBalancers[0].LoadBalancerArn" --output text 2>$null

    if ($ALB_ARN -and $ALB_ARN -ne "None") {
        # Delete listeners first
        $LISTENERS = aws elbv2 describe-listeners `
            --load-balancer-arn $ALB_ARN `
            --query "Listeners[*].ListenerArn" --output text 2>$null

        if ($LISTENERS) {
            $LISTENERS -split '\s+' | ForEach-Object {
                aws elbv2 delete-listener --listener-arn $_ 2>$null
                Write-Host "  Listener deleted: $_" -ForegroundColor Green
            }
        }

        # Delete ALB
        aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN 2>$null
        Write-Host "  ALB deleted." -ForegroundColor Green
        Write-Host "  Waiting 30s for ALB to fully deregister..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
    }
}
catch {
    Write-Host "  ALB not found or already deleted." -ForegroundColor Gray
}

# ── STEP 4: DELETE TARGET GROUP ───────────────────────────────────────────────
Write-Host ""
Write-Host "[4/6] Deleting Target Group..." -ForegroundColor Yellow
try {
    $TG_ARN = aws elbv2 describe-target-groups `
        --names web-server-tg `
        --query "TargetGroups[0].TargetGroupArn" --output text 2>$null

    if ($TG_ARN -and $TG_ARN -ne "None") {
        aws elbv2 delete-target-group --target-group-arn $TG_ARN 2>$null
        Write-Host "  Target Group deleted." -ForegroundColor Green
    }
}
catch {
    Write-Host "  Target Group not found or already deleted." -ForegroundColor Gray
}

# ── STEP 5: DELETE LAUNCH TEMPLATE ────────────────────────────────────────────
Write-Host ""
Write-Host "[5/6] Deleting Launch Template..." -ForegroundColor Yellow
try {
    $LT_ID = aws ec2 describe-launch-templates `
        --launch-template-names web-server-lt `
        --query "LaunchTemplates[0].LaunchTemplateId" --output text 2>$null

    if ($LT_ID -and $LT_ID -ne "None") {
        aws ec2 delete-launch-template --launch-template-id $LT_ID 2>$null
        Write-Host "  Launch Template deleted." -ForegroundColor Green
    }
}
catch {
    Write-Host "  Launch Template not found or already deleted." -ForegroundColor Gray
}

# ── STEP 6: DELETE SECURITY GROUPS ────────────────────────────────────────────
Write-Host ""
Write-Host "[6/6] Deleting Security Groups..." -ForegroundColor Yellow

# Delete EC2 SG first (it references ALB SG)
try {
    $EC2_SG = aws ec2 describe-security-groups `
        --filters "Name=group-name,Values=asg-ec2-sg" `
        "Name=vpc-id,Values=$VPC_ID" `
        --query "SecurityGroups[0].GroupId" --output text 2>$null

    if ($EC2_SG -and $EC2_SG -ne "None") {
        aws ec2 delete-security-group --group-id $EC2_SG 2>$null
        Write-Host "  EC2 SG deleted: $EC2_SG" -ForegroundColor Green
    }
}
catch {
    Write-Host "  EC2 SG not found or still in use — retry in 60s." -ForegroundColor Yellow
}

# Then delete ALB SG
try {
    $ALB_SG = aws ec2 describe-security-groups `
        --filters "Name=group-name,Values=alb-sg" `
        "Name=vpc-id,Values=$VPC_ID" `
        --query "SecurityGroups[0].GroupId" --output text 2>$null

    if ($ALB_SG -and $ALB_SG -ne "None") {
        aws ec2 delete-security-group --group-id $ALB_SG 2>$null
        Write-Host "  ALB SG deleted: $ALB_SG" -ForegroundColor Green
    }
}
catch {
    Write-Host "  ALB SG not found or still in use — retry in 60s." -ForegroundColor Yellow
}

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying cleanup..." -ForegroundColor Yellow

$asgCheck = aws autoscaling describe-auto-scaling-groups `
    --auto-scaling-group-names web-server-asg `
    --query "AutoScalingGroups[*].AutoScalingGroupName" `
    --output text 2>$null

if (-not $asgCheck) {
    Write-Host "  ASG: deleted" -ForegroundColor Green
}
else {
    Write-Host "  ASG: still exists — may need manual deletion" -ForegroundColor Red
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Cleanup Complete ===" -ForegroundColor Cyan
Write-Host "  Deleted: ASG, ALB, Listener, Target Group, Launch Template, Security Groups"
Write-Host ""
Write-Host "  If SG deletion failed, wait 60 seconds and re-run this script." -ForegroundColor Yellow
Write-Host "  SGs can take time to disassociate from deleted ALBs." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Project 10 teardown complete!" -ForegroundColor Green
