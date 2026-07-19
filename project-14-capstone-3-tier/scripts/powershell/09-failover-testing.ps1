# PART 10 - FAILOVER AND RESILIENCE TESTING

# Retrieve ALB DNS if needed
# $ALB_DNS = aws elbv2 describe-load-balancers --names capstone-alb --query "LoadBalancers[0].DNSName" --output text

# Test 1 - Terminate an instance (self-healing test)
$INSTANCES = aws autoscaling describe-auto-scaling-groups `
  --auto-scaling-group-names capstone-asg `
  --query "AutoScalingGroups[0].Instances[*].InstanceId" `
  --output text

$TARGET_INSTANCE = ($INSTANCES -split '\s+')[0]
Write-Host "Terminating instance: $TARGET_INSTANCE"

aws ec2 terminate-instances --instance-ids $TARGET_INSTANCE

Write-Host "While this instance terminates:"
Write-Host "  - ALB health check detects it unhealthy -> stops routing"
Write-Host "  - ASG detects instance count below desired -> launches replacement"
Write-Host "  - New instance bootstraps -> passes health check -> receives traffic"
Write-Host "  - Full recovery in approximately 3-4 minutes"
Start-Process "http://$ALB_DNS"

# Test 2 - RDS Multi-AZ failover test
aws rds reboot-db-instance `
  --db-instance-identifier capstone-database `
  --force-failover

Write-Host "RDS failover initiated"
Write-Host "Primary AZ -> Standby AZ promotion (~60-120 seconds)"
Write-Host "During failover the RDS endpoint DNS updates automatically"
Write-Host "Application reconnects to new primary via same endpoint"

Start-Sleep -Seconds 30
aws rds describe-db-instances `
  --db-instance-identifier capstone-database `
  --query "DBInstances[0].{Status:DBInstanceStatus,AZ:AvailabilityZone}" `
  --output table

# Test 3 - Load test (triggers scale-out)
# $INSTANCES = aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names capstone-asg --query "AutoScalingGroups[0].Instances[*].InstanceId" --output text
$STRESS_INSTANCE = ($INSTANCES -split '\s+')[1]
if (!$STRESS_INSTANCE) { $STRESS_INSTANCE = ($INSTANCES -split '\s+')[0] }

Write-Host "Start SSM session manually for $STRESS_INSTANCE"
Write-Host "aws ssm start-session --target $STRESS_INSTANCE"
Write-Host "Run: sudo yum install -y stress && sudo stress --cpu 1 --timeout 600 &"

Write-Host "Watching scale-out (press Ctrl+C to stop)..."
while ($true) {
  $count = (aws autoscaling describe-auto-scaling-groups `
      --auto-scaling-group-names capstone-asg `
      --query "length(AutoScalingGroups[0].Instances)" `
      --output text)
  Write-Host "$(Get-Date -Format 'HH:mm:ss') - Instance count: $count"
  Start-Sleep -Seconds 30
}
