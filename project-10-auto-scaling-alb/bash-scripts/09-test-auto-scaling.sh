#!/bin/bash

# =============================================================================
# Project 10 — Script 09: Test Auto Scaling
# Generates CPU load to trigger scale-out, monitors instance count
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 10 — Test Auto Scaling ===\e[0m"
echo ""

# ── GET INSTANCE IDs ──────────────────────────────────────────────────────────
INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names web-server-asg \
    --query "AutoScalingGroups[0].Instances[*].InstanceId" \
    --output text)

INSTANCE1=$(INSTANCE_IDS | awk '{print $1}')
echo -e "\e[32m  Target instance for stress test: $INSTANCE1\e[0m"
echo ""

# ── OPTION 1: SSH + STRESS ────────────────────────────────────────────────────
echo -e "\e[33m=== Option 1: SSH Stress Test ===\e[0m"
echo -e "\e[33m  Connect via SSM Session Manager:\e[0m"
echo -e "\e[97m    aws ssm start-session --target $INSTANCE1\e[0m"
echo ""
echo -e "\e[33m  Then run inside the session:\e[0m"
echo -e "\e[97m    sudo stress --cpu 1 --timeout 600 &\e[0m"
echo -e "\e[97m    top  (to verify stress is running)\e[0m"
echo ""

# ── OPTION 2: MANUAL SCALE ───────────────────────────────────────────────────
echo -e "\e[33m=== Option 2: Manual Scale Test ===\e[0m"
echo -e "\e[33m  Scale up to 3 instances:\e[0m"
echo -e "\e[97m    aws autoscaling set-desired-capacity --auto-scaling-group-name web-server-asg --desired-capacity 3\e[0m"
echo ""
echo -e "\e[33m  Scale back down:\e[0m"
echo -e "\e[97m    aws autoscaling set-desired-capacity --auto-scaling-group-name web-server-asg --desired-capacity 2\e[0m"
echo ""

# ── MONITOR ASG ───────────────────────────────────────────────────────────────
echo -e "\e[33m=== Monitoring ASG (Ctrl+C to stop) ===\e[0m"
echo ""

iterations=0
maxIterations=40  # Monitor for ~20 minutes

while ($iterations -lt $maxIterations) {
    $iterations++

    asg=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names web-server-asg \
        --query "AutoScalingGroups[0].{)
          Desired:DesiredCapacity,
          Instances:Instances[*].{ID:InstanceId,State:LifecycleState}}" \
        --output json | jq .

    $timestamp = date +"%T"
    instanceCount=$(echo $asg | jq ".Instances | length")
    desired=$(echo $asg | jq -r ".Desired")

    # Color based on change
    color=if ($instanceCount -gt 2) { "Green" } else { "White" }

echo "$timestamp — Instances: $instanceCount (Desired: $desired)"
    $asg.Instances | ForEach-Object {
        stateColor=switch ($_.State) {
            "InService" { "Green" }
            "Pending" { "Yellow" }
            default { "Red" }
        }
echo "  $($_.ID): $($_.State)"
    }
echo ""

    sleep 30
}

echo ""
echo -e "\e[36m=== Monitoring Complete ===\e[0m"
echo ""
echo -e "\e[33m  Check scaling history:\e[0m"
echo -e "\e[97m    aws autoscaling describe-scaling-activities --auto-scaling-group-name web-server-asg --query \e[0m"
echo ""
echo -e "\e[36mNext step: Run 10-simulate-failure.ps1 OR 11-cleanup.ps1\e[0m"
