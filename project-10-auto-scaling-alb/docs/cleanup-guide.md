# Cleanup Guide

This guide covers the systematic tear-down of the infrastructure.

## 🧹 TEARDOWN ALL RESOURCES AUTOMATICALLY

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the relevant service dashboard (e.g., EC2, VPC, S3, RDS).
2. Locate the resources you created for this project (refer to the `Resources to Delete` table above for the required deletion order).
3. Select each resource and click the primary **Delete**, **Terminate**, or **Empty** button.
4. In the confirmation dialog, type the required confirmation text (e.g., `delete`, `permanently delete`, or the resource name).
5. Click to finalize the deletion, and wait for the resource to completely disappear from the console list before moving to the next service.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# =============================================================================
# Project 10 — Script 11: Cleanup
# Tears down all resources: ASG, ALB, Target Group, Launch Template, SGs
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 10 — Full Cleanup ===\e[0m"
echo ""
echo -e "\e[31m  This will delete ALL resources created in Project 10.\e[0m"
echo ""

# ── GATHER RESOURCE IDs ──────────────────────────────────────────────────────
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --query "Vpcs[0].VpcId" --output text)

# ── STEP 1: SCALE ASG TO 0 ───────────────────────────────────────────────────
echo -e "\e[33m[1/6] Scaling ASG to 0 instances...\e[0m"
if aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name web-server-asg \
    --min-size 0 --max-size 0 --desired-capacity 0 2>/dev/null; then
    echo -e "\e[32m  Scaling down to 0...\e[0m"
    sleep 30
else
    echo -e "\e[90m  ASG not found or already deleted.\e[0m"
fi

# ── STEP 2: DELETE ASG ────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[2/6] Deleting Auto Scaling Group...\e[0m"
if aws autoscaling delete-auto-scaling-group \
    --auto-scaling-group-name web-server-asg \
    --force-delete 2>/dev/null; then
    echo -e "\e[32m  ASG deleted.\e[0m"
    sleep 15
else
    echo -e "\e[90m  ASG not found or already deleted.\e[0m"
fi

# ── STEP 3: DELETE ALB AND LISTENER ───────────────────────────────────────────
echo ""
echo -e "\e[33m[3/6] Deleting ALB and listener...\e[0m"
ALB_ARN=$(aws elbv2 describe-load-balancers \
    --names my-alb \
    --query "LoadBalancers[0].LoadBalancerArn" --output text 2>/dev/null)

if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then
    # Delete listeners first
    LISTENERS=$(aws elbv2 describe-listeners \
        --load-balancer-arn $ALB_ARN \
        --query "Listeners[*].ListenerArn" --output text 2>/dev/null)
    
    if [ -n "$LISTENERS" ]; then
        for listener in $LISTENERS; do
            aws elbv2 delete-listener --listener-arn $listener 2>/dev/null
            echo -e "\e[32m  Listener deleted: $listener\e[0m"
        done
    fi

    # Delete ALB
    aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN 2>/dev/null
    echo -e "\e[32m  ALB deleted.\e[0m"
    echo -e "\e[33m  Waiting 30s for ALB to fully deregister...\e[0m"
    sleep 30
else
    echo -e "\e[90m  ALB not found or already deleted.\e[0m"
fi

# ── STEP 4: DELETE TARGET GROUP ───────────────────────────────────────────────
echo ""
echo -e "\e[33m[4/6] Deleting Target Group...\e[0m"
TG_ARN=$(aws elbv2 describe-target-groups \
    --names web-server-tg \
    --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null)

if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
    aws elbv2 delete-target-group --target-group-arn $TG_ARN 2>/dev/null
    echo -e "\e[32m  Target Group deleted.\e[0m"
else
    echo -e "\e[90m  Target Group not found or already deleted.\e[0m"
fi

# ── STEP 5: DELETE LAUNCH TEMPLATE ────────────────────────────────────────────
echo ""
echo -e "\e[33m[5/6] Deleting Launch Template...\e[0m"
LT_ID=$(aws ec2 describe-launch-templates \
    --launch-template-names web-server-lt \
    --query "LaunchTemplates[0].LaunchTemplateId" --output text 2>/dev/null)

if [ -n "$LT_ID" ] && [ "$LT_ID" != "None" ]; then
    aws ec2 delete-launch-template --launch-template-id $LT_ID 2>/dev/null
    echo -e "\e[32m  Launch Template deleted.\e[0m"
else
    echo -e "\e[90m  Launch Template not found or already deleted.\e[0m"
fi

# ── STEP 6: DELETE SECURITY GROUPS ────────────────────────────────────────────
echo ""
echo -e "\e[33m[6/6] Deleting Security Groups...\e[0m"

# Delete EC2 SG first (it references ALB SG)
EC2_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=asg-ec2-sg" "Name=vpc-id,Values=$VPC_ID" \
    --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

if [ -n "$EC2_SG" ] && [ "$EC2_SG" != "None" ]; then
    if aws ec2 delete-security-group --group-id $EC2_SG 2>/dev/null; then
        echo -e "\e[32m  EC2 SG deleted: $EC2_SG\e[0m"
    else
        echo -e "\e[33m  EC2 SG still in use — retry in 60s.\e[0m"
    fi
else
    echo -e "\e[90m  EC2 SG not found.\e[0m"
fi

# Then delete ALB SG
ALB_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=alb-sg" "Name=vpc-id,Values=$VPC_ID" \
    --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

if [ -n "$ALB_SG" ] && [ "$ALB_SG" != "None" ]; then
    if aws ec2 delete-security-group --group-id $ALB_SG 2>/dev/null; then
        echo -e "\e[32m  ALB SG deleted: $ALB_SG\e[0m"
    else
        echo -e "\e[33m  ALB SG still in use — retry in 60s.\e[0m"
    fi
else
    echo -e "\e[90m  ALB SG not found.\e[0m"
fi

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mVerifying cleanup...\e[0m"

asgCheck=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names web-server-asg \
    --query "AutoScalingGroups[*].AutoScalingGroupName" \
    --output text 2>/dev/null)

if [ -z "$asgCheck" ]; then
    echo -e "\e[32m  ASG: deleted\e[0m"
else
    echo -e "\e[31m  ASG: still exists — may need manual deletion\e[0m"
fi

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== Cleanup Complete ===\e[0m"
echo "  Deleted: ASG, ALB, Listener, Target Group, Launch Template, Security Groups"
echo ""
echo -e "\e[33m  If SG deletion failed, wait 60 seconds and re-run this script.\e[0m"
echo -e "\e[33m  SGs can take time to disassociate from deleted ALBs.\e[0m"
echo ""
echo -e "\e[32m  Project 10 teardown complete!\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
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
```
