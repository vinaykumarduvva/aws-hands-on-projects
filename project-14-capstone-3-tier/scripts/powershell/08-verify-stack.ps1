# PART 8 - VERIFY RDS IS AVAILABLE
# Check RDS status
aws rds describe-db-instances `
  --db-instance-identifier capstone-database `
  --query "DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ,Endpoint:Endpoint.Address,AZ:AvailabilityZone,SecondaryAZ:SecondaryAvailabilityZone}" `
  --output table

# If still creating - wait
aws rds wait db-instance-available --db-instance-identifier capstone-database
Write-Host "RDS available"

# Get endpoint
$RDS_ENDPOINT = aws rds describe-db-instances --db-instance-identifier capstone-database --query "DBInstances[0].Endpoint.Address" --output text
Write-Host "RDS Endpoint: $RDS_ENDPOINT"

# PART 9 - VERIFY FULL STACK
Write-Host "=== FULL STACK VERIFICATION ==="

# Needed variables
# $VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text
# $ALB_ARN = aws elbv2 describe-load-balancers --names capstone-alb --query "LoadBalancers[0].LoadBalancerArn" --output text
# $TG_ARN = aws elbv2 describe-target-groups --names capstone-app-tg --query "TargetGroups[0].TargetGroupArn" --output text
# $ALB_DNS = aws elbv2 describe-load-balancers --names capstone-alb --query "LoadBalancers[0].DNSName" --output text

# 1. VPC and subnets
Write-Host "Checking VPC..."
aws ec2 describe-vpcs --vpc-ids $VPC_ID --query "Vpcs[0].{ID:VpcId,CIDR:CidrBlock,DNS:EnableDnsHostnames}" --output table

# 2. All 6 subnets
Write-Host "Checking Subnets..."
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].{Name:Tags[?Key=='Name'].Value|[0],CIDR:CidrBlock,AZ:AvailabilityZone}" --output table

# 3. ALB status
Write-Host "Checking ALB..."
aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query "LoadBalancers[0].{DNS:DNSName,State:State.Code}" --output table

# 4. Target health
Write-Host "Checking Target Health..."
aws elbv2 describe-target-health --target-group-arn $TG_ARN --query "TargetHealthDescriptions[*].{Instance:Target.Id,State:TargetHealth.State}" --output table

# 5. ASG instances
Write-Host "Checking ASG..."
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names capstone-asg --query "AutoScalingGroups[0].{Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,Count:length(Instances)}" --output table

# 6. RDS Multi-AZ
Write-Host "Checking RDS..."
aws rds describe-db-instances --db-instance-identifier capstone-database --query "DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ,AZ:AvailabilityZone}" --output table

# 7. CloudWatch alarms
Write-Host "Checking Alarms..."
aws cloudwatch describe-alarms --alarm-name-prefix "Capstone-" --query "MetricAlarms[*].{Name:AlarmName,State:StateValue}" --output table

# 8. Test application
Write-Host "Testing Application..."
$RESPONSE = Invoke-WebRequest -Uri "http://$ALB_DNS" -UseBasicParsing
Write-Host "HTTP Status: $($RESPONSE.StatusCode)"
$HEALTH = Invoke-WebRequest -Uri "http://$ALB_DNS/health.json" -UseBasicParsing
Write-Host "Health check: $($HEALTH.Content)"

# Open in browser
Start-Process "http://$ALB_DNS"
Write-Host ""
Write-Host "=== ALL SYSTEMS OPERATIONAL ==="
Write-Host "Application URL: http://$ALB_DNS"
Write-Host "Dashboard: CloudWatch -> Capstone-3Tier-Dashboard"
