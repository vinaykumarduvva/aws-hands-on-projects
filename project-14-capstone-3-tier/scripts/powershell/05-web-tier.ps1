# PART 5 - WEB TIER (ALB + Target Group)

# Retrieve VPC and Subnets if needed
# $VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text
# $PUB_A = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-a" --query "Subnets[0].SubnetId" --output text
# $PUB_B = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-b" --query "Subnets[0].SubnetId" --output text
# $ALB_SG = aws ec2 describe-security-groups --filters "Name=group-name,Values=capstone-alb-sg" --query "SecurityGroups[0].GroupId" --output text

# Create Target Group
$TG_ARN = aws elbv2 create-target-group `
  --name capstone-app-tg `
  --protocol HTTP --port 80 `
  --vpc-id $VPC_ID `
  --health-check-protocol HTTP `
  --health-check-path "/health.json" `
  --health-check-interval-seconds 30 `
  --healthy-threshold-count 2 `
  --unhealthy-threshold-count 3 `
  --query "TargetGroups[0].TargetGroupArn" `
  --output text
Write-Host "Target Group: $TG_ARN"

# Create ALB in public subnets
$ALB_ARN = aws elbv2 create-load-balancer `
  --name capstone-alb `
  --subnets $PUB_A $PUB_B `
  --security-groups $ALB_SG `
  --scheme internet-facing `
  --type application `
  --query "LoadBalancers[0].LoadBalancerArn" `
  --output text

$ALB_DNS = aws elbv2 describe-load-balancers `
  --load-balancer-arns $ALB_ARN `
  --query "LoadBalancers[0].DNSName" `
  --output text
Write-Host "ALB DNS: $ALB_DNS"

# Create HTTP listener
$LISTENER_ARN = aws elbv2 create-listener `
  --load-balancer-arn $ALB_ARN `
  --protocol HTTP --port 80 `
  --default-actions "Type=forward,TargetGroupArn=$TG_ARN" `
  --query "Listeners[0].ListenerArn" `
  --output text
Write-Host "Listener: $LISTENER_ARN"

Write-Host "Waiting for ALB to be active..."
aws elbv2 wait load-balancer-available --load-balancer-arns $ALB_ARN
Write-Host "ALB active: http://$ALB_DNS"
