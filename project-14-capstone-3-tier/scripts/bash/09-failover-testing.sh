#!/bin/bash
set -e
set -u

echo "=> PART 10 - FAILOVER AND RESILIENCE TESTING"

echo "=> Test 1 - Terminate an instance (self-healing test)"
INSTANCES=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names capstone-asg \
  --query "AutoScalingGroups[0].Instances[*].InstanceId" \
  --output text)

TARGET_INSTANCE=$(echo "$INSTANCES" | awk '{print $1}')
echo "Terminating instance: $TARGET_INSTANCE"

aws ec2 terminate-instances --instance-ids "$TARGET_INSTANCE" > /dev/null

echo "While this instance terminates:"
echo "  - ALB health check detects it unhealthy -> stops routing"
echo "  - ASG detects instance count below desired -> launches replacement"
echo "  - New instance bootstraps -> passes health check -> receives traffic"
echo "  - Full recovery in approximately 3-4 minutes"

echo "=> Test 2 - RDS Multi-AZ failover test"
aws rds reboot-db-instance \
  --db-instance-identifier capstone-database \
  --force-failover > /dev/null

echo "RDS failover initiated"
echo "Primary AZ -> Standby AZ promotion (~60-120 seconds)"
echo "During failover the RDS endpoint DNS updates automatically"
echo "Application reconnects to new primary via same endpoint"

sleep 30
aws rds describe-db-instances \
  --db-instance-identifier capstone-database \
  --query "DBInstances[0].{Status:DBInstanceStatus,AZ:AvailabilityZone}" \
  --output table

echo "=> Test 3 - Load test (triggers scale-out)"
STRESS_INSTANCE=$(echo "$INSTANCES" | awk '{print $2}')
if [ -z "$STRESS_INSTANCE" ]; then
  STRESS_INSTANCE=$(echo "$INSTANCES" | awk '{print $1}')
fi

echo "Start SSM session manually for $STRESS_INSTANCE:"
echo "aws ssm start-session --target $STRESS_INSTANCE"
echo "Run: sudo yum install -y stress && sudo stress --cpu 1 --timeout 600 &"

echo "Watching scale-out (press Ctrl+C to stop)..."
while true; do
  COUNT=$(aws autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names capstone-asg \
      --query "length(AutoScalingGroups[0].Instances)" \
      --output text)
  echo "$(date +'%H:%M:%S') - Instance count: $COUNT"
  sleep 30
done
