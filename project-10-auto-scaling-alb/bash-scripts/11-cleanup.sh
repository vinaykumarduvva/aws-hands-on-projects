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
try {
    aws autoscaling update-auto-scaling-group \
        --auto-scaling-group-name web-server-asg \
        --min-size 0 --max-size 0 --desired-capacity 0 2>/dev/null
echo -e "\e[32m  Scaling down to 0...\e[0m"
    sleep 30
}
catch {
echo -e "\e[90m  ASG not found or already deleted.\e[0m"
}

# ── STEP 2: DELETE ASG ────────────────────────────────────────────────────────
echo ""
echo -e "\e[33m[2/6] Deleting Auto Scaling Group...\e[0m"
try {
    aws autoscaling delete-auto-scaling-group \
        --auto-scaling-group-name web-server-asg \
        --force-delete 2>/dev/null
echo -e "\e[32m  ASG deleted.\e[0m"
    sleep 15
}
catch {
echo -e "\e[90m  ASG not found or already deleted.\e[0m"
}

# ── STEP 3: DELETE ALB AND LISTENER ───────────────────────────────────────────
echo ""
echo -e "\e[33m[3/6] Deleting ALB and listener...\e[0m"
try {
    ALB_ARN=$(aws elbv2 describe-load-balancers \
        --names my-alb \
        --query "LoadBalancers[0].LoadBalancerArn" --output text 2>/dev/null)

    if ($ALB_ARN -and $ALB_ARN -ne "None") {
        # Delete listeners first
        LISTENERS=$(aws elbv2 describe-listeners \
            --load-balancer-arn $ALB_ARN \
            --query "Listeners[*].ListenerArn" --output text 2>/dev/null)

        if ($LISTENERS) {
            $LISTENERS  | ForEach-Object {
                aws elbv2 delete-listener --listener-arn $_ 2>/dev/null
echo -e "\e[32m  Listener deleted: $_\e[0m"
            }
        }

        # Delete ALB
        aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN 2>/dev/null
echo -e "\e[32m  ALB deleted.\e[0m"
echo -e "\e[33m  Waiting 30s for ALB to fully deregister...\e[0m"
        sleep 30
    }
}
catch {
echo -e "\e[90m  ALB not found or already deleted.\e[0m"
}

# ── STEP 4: DELETE TARGET GROUP ───────────────────────────────────────────────
echo ""
echo -e "\e[33m[4/6] Deleting Target Group...\e[0m"
try {
    TG_ARN=$(aws elbv2 describe-target-groups \
        --names web-server-tg \
        --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null)

    if ($TG_ARN -and $TG_ARN -ne "None") {
        aws elbv2 delete-target-group --target-group-arn $TG_ARN 2>/dev/null
echo -e "\e[32m  Target Group deleted.\e[0m"
    }
}
catch {
echo -e "\e[90m  Target Group not found or already deleted.\e[0m"
}

# ── STEP 5: DELETE LAUNCH TEMPLATE ────────────────────────────────────────────
echo ""
echo -e "\e[33m[5/6] Deleting Launch Template...\e[0m"
try {
    LT_ID=$(aws ec2 describe-launch-templates \
        --launch-template-names web-server-lt \
        --query "LaunchTemplates[0].LaunchTemplateId" --output text 2>/dev/null)

    if ($LT_ID -and $LT_ID -ne "None") {
        aws ec2 delete-launch-template --launch-template-id $LT_ID 2>/dev/null
echo -e "\e[32m  Launch Template deleted.\e[0m"
    }
}
catch {
echo -e "\e[90m  Launch Template not found or already deleted.\e[0m"
}

# ── STEP 6: DELETE SECURITY GROUPS ────────────────────────────────────────────
echo ""
echo -e "\e[33m[6/6] Deleting Security Groups...\e[0m"

# Delete EC2 SG first (it references ALB SG)
try {
    EC2_SG=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=asg-ec2-sg" \
        "Name=vpc-id,Values=$VPC_ID" \
        --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

    if ($EC2_SG -and $EC2_SG -ne "None") {
        aws ec2 delete-security-group --group-id $EC2_SG 2>/dev/null
echo -e "\e[32m  EC2 SG deleted: $EC2_SG\e[0m"
    }
}
catch {
echo -e "\e[33m  EC2 SG not found or still in use — retry in 60s.\e[0m"
}

# Then delete ALB SG
try {
    ALB_SG=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=alb-sg" \
        "Name=vpc-id,Values=$VPC_ID" \
        --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

    if ($ALB_SG -and $ALB_SG -ne "None") {
        aws ec2 delete-security-group --group-id $ALB_SG 2>/dev/null
echo -e "\e[32m  ALB SG deleted: $ALB_SG\e[0m"
    }
}
catch {
echo -e "\e[33m  ALB SG not found or still in use — retry in 60s.\e[0m"
}

# ── VERIFY ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[33mVerifying cleanup...\e[0m"

asgCheck=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names web-server-asg \
    --query "AutoScalingGroups[*].AutoScalingGroupName" \
    --output text 2>/dev/null)

if (-not $asgCheck) {
echo -e "\e[32m  ASG: deleted\e[0m"
}
else {
echo -e "\e[31m  ASG: still exists — may need manual deletion\e[0m"
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== Cleanup Complete ===\e[0m"
echo "  Deleted: ASG, ALB, Listener, Target Group, Launch Template, Security Groups"
echo ""
echo -e "\e[33m  If SG deletion failed, wait 60 seconds and re-run this script.\e[0m"
echo -e "\e[33m  SGs can take time to disassociate from deleted ALBs.\e[0m"
echo ""
echo -e "\e[32m  Project 10 teardown complete!\e[0m"
