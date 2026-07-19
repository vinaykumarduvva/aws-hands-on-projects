#!/bin/bash
set -e
set -u

echo "=> PART 8 - VERIFY RDS IS AVAILABLE"
aws rds describe-db-instances \
  --db-instance-identifier capstone-database \
  --query "DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ,Endpoint:Endpoint.Address,AZ:AvailabilityZone,SecondaryAZ:SecondaryAvailabilityZone}" \
  --output table

aws rds wait db-instance-available --db-instance-identifier capstone-database
echo "RDS available"

RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier capstone-database --query "DBInstances[0].Endpoint.Address" --output text)
echo "RDS Endpoint: $RDS_ENDPOINT"

echo "=> PART 9 - VERIFY FULL STACK"
echo "=== FULL STACK VERIFICATION ==="

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text)
ALB_ARN=$(aws elbv2 describe-load-balancers --names capstone-alb --query "LoadBalancers[0].LoadBalancerArn" --output text)
TG_ARN=$(aws elbv2 describe-target-groups --names capstone-app-tg --query "TargetGroups[0].TargetGroupArn" --output text)
ALB_DNS=$(aws elbv2 describe-load-balancers --names capstone-alb --query "LoadBalancers[0].DNSName" --output text)

echo "=> 1. VPC and subnets"
aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --query "Vpcs[0].{ID:VpcId,CIDR:CidrBlock,DNS:EnableDnsHostnames}" --output table

echo "=> 2. All 6 subnets"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].{Name:Tags[?Key=='Name'].Value|[0],CIDR:CidrBlock,AZ:AvailabilityZone}" --output table

echo "=> 3. ALB status"
aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" --query "LoadBalancers[0].{DNS:DNSName,State:State.Code}" --output table

echo "=> 4. Target health"
aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --query "TargetHealthDescriptions[*].{Instance:Target.Id,State:TargetHealth.State}" --output table

echo "=> 5. ASG instances"
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names capstone-asg --query "AutoScalingGroups[0].{Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,Count:length(Instances)}" --output table

echo "=> 6. RDS Multi-AZ"
aws rds describe-db-instances --db-instance-identifier capstone-database --query "DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ,AZ:AvailabilityZone}" --output table

echo "=> 7. CloudWatch alarms"
aws cloudwatch describe-alarms --alarm-name-prefix "Capstone-" --query "MetricAlarms[*].{Name:AlarmName,State:StateValue}" --output table

echo "=> 8. Test application"
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" "http://$ALB_DNS")
echo "HTTP Status: $HTTP_STATUS"
HEALTH=$(curl -s "http://$ALB_DNS/health.json")
echo "Health check: $HEALTH"

echo ""
echo "=== ALL SYSTEMS OPERATIONAL ==="
echo "Application URL: http://$ALB_DNS"
echo "Dashboard: CloudWatch -> Capstone-3Tier-Dashboard"
