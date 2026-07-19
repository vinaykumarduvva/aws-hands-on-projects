# PART 12 - CLEANUP
Write-Host "=== Starting Full Capstone Cleanup ==="

# Retrieve required variables if not set in session
$VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text
$ALB_ARN = aws elbv2 describe-load-balancers --names capstone-alb --query "LoadBalancers[0].LoadBalancerArn" --output text
$LISTENER_ARN = aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query "Listeners[0].ListenerArn" --output text
$TG_ARN = aws elbv2 describe-target-groups --names capstone-app-tg --query "TargetGroups[0].TargetGroupArn" --output text
$LT_ID = aws ec2 describe-launch-templates --launch-template-names capstone-app-lt --query "LaunchTemplates[0].LaunchTemplateId" --output text
$NAT_GW_ID = aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" --query "NatGateways[0].NatGatewayId" --output text
$EIP_ALLOC = aws ec2 describe-addresses --filters "Name=tag:Name,Values=capstone-nat" --query "Addresses[0].AllocationId" --output text
$DB_SG = aws ec2 describe-security-groups --filters "Name=group-name,Values=capstone-db-sg" --query "SecurityGroups[0].GroupId" --output text
$APP_SG = aws ec2 describe-security-groups --filters "Name=group-name,Values=capstone-app-sg" --query "SecurityGroups[0].GroupId" --output text
$ALB_SG = aws ec2 describe-security-groups --filters "Name=group-name,Values=capstone-alb-sg" --query "SecurityGroups[0].GroupId" --output text
$PUB_A = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-a" --query "Subnets[0].SubnetId" --output text
$PUB_B = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-b" --query "Subnets[0].SubnetId" --output text
$APP_A = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-app-subnet-a" --query "Subnets[0].SubnetId" --output text
$APP_B = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-app-subnet-b" --query "Subnets[0].SubnetId" --output text
$DB_A = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-db-subnet-a" --query "Subnets[0].SubnetId" --output text
$DB_B = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-db-subnet-b" --query "Subnets[0].SubnetId" --output text
$PUB_RT = aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-rt" --query "RouteTables[0].RouteTableId" --output text
$PRI_RT = aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-rt" --query "RouteTables[0].RouteTableId" --output text
$IGW_ID = aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[0].InternetGatewayId" --output text
$SNS_ARN = aws sns list-topics --query "Topics[?contains(TopicArn, 'capstone-alerts')].TopicArn | [0]" --output text

# Step 1 - Scale ASG to 0
aws autoscaling update-auto-scaling-group --auto-scaling-group-name capstone-asg --min-size 0 --max-size 0 --desired-capacity 0
Start-Sleep -Seconds 60

# Step 2 - Delete ASG
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name capstone-asg --force-delete
Write-Host "ASG deleted"

# Step 3 - Disable deletion protection on RDS then delete
aws rds modify-db-instance --db-instance-identifier capstone-database --no-deletion-protection --apply-immediately
Start-Sleep -Seconds 10
aws rds delete-db-instance --db-instance-identifier capstone-database --skip-final-snapshot --delete-automated-backups
Write-Host "RDS deletion initiated (3-5 minutes)..."

# Step 4 - Delete ALB and listener
if ($LISTENER_ARN) { aws elbv2 delete-listener --listener-arn $LISTENER_ARN }
if ($ALB_ARN) { aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN }
Start-Sleep -Seconds 30
Write-Host "ALB deleted"

# Step 5 - Delete target group
if ($TG_ARN) { aws elbv2 delete-target-group --target-group-arn $TG_ARN }

# Step 6 - Delete Launch Template
if ($LT_ID) { aws ec2 delete-launch-template --launch-template-id $LT_ID }

# Step 7 - Wait for RDS then delete subnet group
aws rds wait db-instance-deleted --db-instance-identifier capstone-database
aws rds delete-db-subnet-group --db-subnet-group-name capstone-db-subnet-group
Write-Host "RDS and subnet group deleted"

# Step 8 - Delete Secrets Manager secret
aws secretsmanager delete-secret --secret-id "capstone/db/credentials" --force-delete-without-recovery

# Step 9 - Delete NAT Gateway (stops charges)
if ($NAT_GW_ID) { aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_ID }
Start-Sleep -Seconds 60
if ($EIP_ALLOC) { aws ec2 release-address --allocation-id $EIP_ALLOC }
Write-Host "NAT Gateway and EIP deleted"

# Step 10 - Delete security groups
if ($DB_SG) { aws ec2 delete-security-group --group-id $DB_SG }
if ($APP_SG) { aws ec2 delete-security-group --group-id $APP_SG }
if ($ALB_SG) { aws ec2 delete-security-group --group-id $ALB_SG }

# Step 11 - Delete subnets
foreach ($S in @($PUB_A,$PUB_B,$APP_A,$APP_B,$DB_A,$DB_B)) {
  if ($S) { aws ec2 delete-subnet --subnet-id $S }
}

# Step 12 - Delete route tables
if ($PUB_RT) { aws ec2 delete-route-table --route-table-id $PUB_RT }
if ($PRI_RT) { aws ec2 delete-route-table --route-table-id $PRI_RT }

# Step 13 - Detach and delete IGW
if ($IGW_ID -and $VPC_ID) {
  aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
  aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
}

# Step 14 - Delete VPC
if ($VPC_ID) { aws ec2 delete-vpc --vpc-id $VPC_ID }
Write-Host "VPC deleted"

# Step 15 - Delete CloudWatch resources
aws cloudwatch delete-alarms --alarm-names "Capstone-ALB-5XX-High" "Capstone-ASG-CPU-High" "Capstone-RDS-CPU-High" "Capstone-RDS-Storage-Low" "Capstone-ALB-Healthy-Hosts-Low"
aws cloudwatch delete-dashboards --dashboard-names "Capstone-3Tier-Dashboard"

# Step 16 - Delete SNS
if ($SNS_ARN) { aws sns delete-topic --topic-arn $SNS_ARN }

# Step 17 - Delete IAM
aws iam remove-role-from-instance-profile --instance-profile-name capstone-ec2-profile --role-name capstone-ec2-role
aws iam detach-role-policy --role-name capstone-ec2-role --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam delete-role-policy --role-name capstone-ec2-role --policy-name secrets-access
aws iam delete-instance-profile --instance-profile-name capstone-ec2-profile
aws iam delete-role --role-name capstone-ec2-role

Write-Host ""
Write-Host "=== Capstone Cleanup Complete ==="
Write-Host "All resources deleted - zero ongoing charges"
