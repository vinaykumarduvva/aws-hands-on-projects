#!/bin/bash

# =============================================================================
# Project 10 — Script 10: Simulate Instance Failure
# Terminates an instance to demonstrate ASG self-healing
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 10 — Simulate Instance Failure ===\e[0m"
echo ""

# ── GET CURRENT INSTANCES ─────────────────────────────────────────────────────
echo -e "\e[33m[1/3] Getting current ASG instances...\e[0m"

INSTANCES=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names web-server-asg \
    --query "AutoScalingGroups[0].Instances[*].InstanceId" \
    --output text)

INSTANCE_LIST=$INSTANCES
echo -e "\e[32m  Current instances: $($INSTANCE_LIST -join ', ')\e[0m"

FAILED_INSTANCE=$INSTANCE_LIST[0]
echo -e "\e[31m  Instance to terminate (simulate failure): $FAILED_INSTANCE\e[0m"
echo ""

# ── SHOW BEFORE STATE ─────────────────────────────────────────────────────────
echo -e "\e[33m[2/3] Before failure — current state:\e[0m"
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names web-server-asg \
    --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus,AZ:AvailabilityZone}" \
    --output table

# ── TERMINATE INSTANCE ────────────────────────────────────────────────────────
echo ""
echo -e "\e[31m[3/3] Terminating instance: $FAILED_INSTANCE\e[0m"
echo -e "\e[33m  ASG will detect the failure and launch a replacement...\e[0m"

aws ec2 terminate-instances --instance-ids $FAILED_INSTANCE | Out-Null

echo -e "\e[31m  Termination initiated!\e[0m"
echo ""

# ── MONITOR SELF-HEALING ──────────────────────────────────────────────────────
echo -e "\e[33m=== Monitoring Self-Healing (Ctrl+C to stop) ===\e[0m"
echo -e "\e[33m  Expected: ASG detects failure → launches new instance → registers in ALB\e[0m"
echo ""

iterations=0
maxIterations=20  # Monitor for ~10 minutes

while ($iterations -lt $maxIterations) {
    $iterations++

    $timestamp = date +"%T"

    asg=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names web-server-asg \
        --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus}" \
        --output json | jq .)

echo -e "\e[97m$timestamp — Instance Count: $($asg.Count)\e[0m"
    $asg | ForEach-Object {
        stateColor=switch ($_.State) {
            "InService" { "Green" }
            "Pending" { "Yellow" }
            "Terminating" { "Red" }
            default { "Gray" }
        }
        isNew=if ($_.ID -ne $FAILED_INSTANCE -and $_.State -eq "Pending") { " ← NEW" } else { "" }
echo "  $($_.ID): $($_.State) ($($_.Health))$isNew"
    }
echo ""

    # Check if we have all healthy instances back
    healthyCount=($asg | Where-Object { $_.State -eq "InService" }).Count
    if ($healthyCount -ge 2 -and $iterations -gt 2) {
echo -e "\e[32m  Self-healing complete! All instances InService.\e[0m"
        break
    }

    sleep 30
}

# ── FINAL STATE ───────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== Final State After Self-Healing ===\e[0m"
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names web-server-asg \
    --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus,AZ:AvailabilityZone}" \
    --output table

echo ""
echo -e "\e[33m  Key takeaway: ASG automatically replaced the failed instance.\e[0m"
echo -e "\e[33m  The ALB routed traffic to the healthy instance during replacement.\e[0m"
echo -e "\e[33m  Zero manual intervention required!\e[0m"
echo ""
echo -e "\e[36mNext step: Run 11-cleanup.ps1\e[0m"
