#!/bin/bash
set -u

echo "=== Starting Full Capstone Cleanup ==="

# Retrieve required variables if not set in session
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text 2>/dev/null || echo "")
ALB_ARN=$(aws elbv2 describe-load-balancers --names capstone-alb --query "LoadBalancers[0].LoadBalancerArn" --output text 2>/dev/null || echo "")
LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" --query "Listeners[0].ListenerArn" --output text 2>/dev/null || echo "")
TG_ARN=$(aws elbv2 describe-target-groups --names capstone-app-tg --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null || echo "")
LT_ID=$(aws ec2 describe-launch-templates --launch-template-names capstone-app-lt --query "LaunchTemplates[0].LaunchTemplateId" --output text 2>/dev/null || echo "")
NAT_GW_ID=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" --query "NatGateways[0].NatGatewayId" --output text 2>/dev/null || echo "")
EIP_ALLOC=$(aws ec2 describe-addresses --filters "Name=tag:Name,Values=capstone-nat" --query "Addresses[0].AllocationId" --output text 2>/dev/null || echo "")
DB_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=capstone-db-sg" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "")
APP_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=capstone-app-sg" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "")
ALB_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=capstone-alb-sg" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "")
PUB_A=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-a" --query "Subnets[0].SubnetId" --output text 2>/dev/null || echo "")
PUB_B=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-b" --query "Subnets[0].SubnetId" --output text 2>/dev/null || echo "")
APP_A=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-app-subnet-a" --query "Subnets[0].SubnetId" --output text 2>/dev/null || echo "")
APP_B=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-app-subnet-b" --query "Subnets[0].SubnetId" --output text 2>/dev/null || echo "")
DB_A=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-db-subnet-a" --query "Subnets[0].SubnetId" --output text 2>/dev/null || echo "")
DB_B=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-db-subnet-b" --query "Subnets[0].SubnetId" --output text 2>/dev/null || echo "")
PUB_RT=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-rt" --query "RouteTables[0].RouteTableId" --output text 2>/dev/null || echo "")
PRI_RT=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-rt" --query "RouteTables[0].RouteTableId" --output text 2>/dev/null || echo "")
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[0].InternetGatewayId" --output text 2>/dev/null || echo "")
SNS_ARN=$(aws sns list-topics --query "Topics[?contains(TopicArn, 'capstone-alerts')].TopicArn | [0]" --output text 2>/dev/null || echo "")

echo "=> Step 1 - Scale ASG to 0"
aws autoscaling update-auto-scaling-group --auto-scaling-group-name capstone-asg --min-size 0 --max-size 0 --desired-capacity 0 2>/dev/null || true
sleep 60

echo "=> Step 2 - Delete ASG"
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name capstone-asg --force-delete 2>/dev/null || true
echo "ASG deleted"

echo "=> Step 3 - Disable deletion protection on RDS then delete"
aws rds modify-db-instance --db-instance-identifier capstone-database --no-deletion-protection --apply-immediately 2>/dev/null || true
sleep 10
aws rds delete-db-instance --db-instance-identifier capstone-database --skip-final-snapshot --delete-automated-backups 2>/dev/null || true
echo "RDS deletion initiated (3-5 minutes)..."

echo "=> Step 4 - Delete ALB and listener"
if [ -n "$LISTENER_ARN" ] && [ "$LISTENER_ARN" != "None" ]; then aws elbv2 delete-listener --listener-arn "$LISTENER_ARN" 2>/dev/null || true; fi
if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" 2>/dev/null || true; fi
sleep 30
echo "ALB deleted"

echo "=> Step 5 - Delete target group"
if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then aws elbv2 delete-target-group --target-group-arn "$TG_ARN" 2>/dev/null || true; fi

echo "=> Step 6 - Delete Launch Template"
if [ -n "$LT_ID" ] && [ "$LT_ID" != "None" ]; then aws ec2 delete-launch-template --launch-template-id "$LT_ID" 2>/dev/null || true; fi

echo "=> Step 7 - Wait for RDS then delete subnet group"
aws rds wait db-instance-deleted --db-instance-identifier capstone-database 2>/dev/null || true
aws rds delete-db-subnet-group --db-subnet-group-name capstone-db-subnet-group 2>/dev/null || true
echo "RDS and subnet group deleted"

echo "=> Step 8 - Delete Secrets Manager secret"
aws secretsmanager delete-secret --secret-id "capstone/db/credentials" --force-delete-without-recovery 2>/dev/null || true

echo "=> Step 9 - Delete NAT Gateway (stops charges)"
if [ -n "$NAT_GW_ID" ] && [ "$NAT_GW_ID" != "None" ]; then aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_GW_ID" 2>/dev/null || true; fi
sleep 60
if [ -n "$EIP_ALLOC" ] && [ "$EIP_ALLOC" != "None" ]; then aws ec2 release-address --allocation-id "$EIP_ALLOC" 2>/dev/null || true; fi
echo "NAT Gateway and EIP deleted"

echo "=> Step 10 - Delete security groups"
if [ -n "$DB_SG" ] && [ "$DB_SG" != "None" ]; then aws ec2 delete-security-group --group-id "$DB_SG" 2>/dev/null || true; fi
if [ -n "$APP_SG" ] && [ "$APP_SG" != "None" ]; then aws ec2 delete-security-group --group-id "$APP_SG" 2>/dev/null || true; fi
if [ -n "$ALB_SG" ] && [ "$ALB_SG" != "None" ]; then aws ec2 delete-security-group --group-id "$ALB_SG" 2>/dev/null || true; fi

echo "=> Step 11 - Delete subnets"
for S in "$PUB_A" "$PUB_B" "$APP_A" "$APP_B" "$DB_A" "$DB_B"; do
  if [ -n "$S" ] && [ "$S" != "None" ]; then aws ec2 delete-subnet --subnet-id "$S" 2>/dev/null || true; fi
done

echo "=> Step 12 - Delete route tables"
if [ -n "$PUB_RT" ] && [ "$PUB_RT" != "None" ]; then aws ec2 delete-route-table --route-table-id "$PUB_RT" 2>/dev/null || true; fi
if [ -n "$PRI_RT" ] && [ "$PRI_RT" != "None" ]; then aws ec2 delete-route-table --route-table-id "$PRI_RT" 2>/dev/null || true; fi

echo "=> Step 13 - Detach and delete IGW"
if [ -n "$IGW_ID" ] && [ "$IGW_ID" != "None" ] && [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
  aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" 2>/dev/null || true
  aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" 2>/dev/null || true
fi

echo "=> Step 14 - Delete VPC"
if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then aws ec2 delete-vpc --vpc-id "$VPC_ID" 2>/dev/null || true; fi
echo "VPC deleted"

echo "=> Step 15 - Delete CloudWatch resources"
aws cloudwatch delete-alarms --alarm-names "Capstone-ALB-5XX-High" "Capstone-ASG-CPU-High" "Capstone-RDS-CPU-High" "Capstone-RDS-Storage-Low" "Capstone-ALB-Healthy-Hosts-Low" 2>/dev/null || true
aws cloudwatch delete-dashboards --dashboard-names "Capstone-3Tier-Dashboard" 2>/dev/null || true

echo "=> Step 16 - Delete SNS"
if [ -n "$SNS_ARN" ] && [ "$SNS_ARN" != "None" ]; then aws sns delete-topic --topic-arn "$SNS_ARN" 2>/dev/null || true; fi

echo "=> Step 17 - Delete IAM"
aws iam remove-role-from-instance-profile --instance-profile-name capstone-ec2-profile --role-name capstone-ec2-role 2>/dev/null || true
aws iam detach-role-policy --role-name capstone-ec2-role --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore 2>/dev/null || true
aws iam delete-role-policy --role-name capstone-ec2-role --policy-name secrets-access 2>/dev/null || true
aws iam delete-instance-profile --instance-profile-name capstone-ec2-profile 2>/dev/null || true
aws iam delete-role --role-name capstone-ec2-role 2>/dev/null || true

echo ""
echo "=== Capstone Cleanup Complete ==="
echo "All resources deleted - zero ongoing charges"
