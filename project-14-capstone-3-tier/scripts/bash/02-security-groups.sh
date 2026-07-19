#!/bin/bash
set -e
set -u

echo "=> PART 2 - SECURITY GROUPS (3-TIER CHAINING)"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text)

echo "=> ALB Security Group (Web Tier)"
ALB_SG=$(aws ec2 create-security-group \
  --group-name capstone-alb-sg \
  --description "Web Tier: ALB accepts HTTP from internet" \
  --vpc-id "$VPC_ID" --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress --group-id "$ALB_SG" --protocol tcp --port 80 --cidr "0.0.0.0/0" > /dev/null
aws ec2 authorize-security-group-ingress --group-id "$ALB_SG" --protocol tcp --port 443 --cidr "0.0.0.0/0" > /dev/null
echo "ALB SG: $ALB_SG"

echo "=> App Server Security Group (App Tier)"
APP_SG=$(aws ec2 create-security-group \
  --group-name capstone-app-sg \
  --description "App Tier: accepts HTTP from ALB only" \
  --vpc-id "$VPC_ID" --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress --group-id "$APP_SG" --protocol tcp --port 80 --source-group "$ALB_SG" > /dev/null
echo "App SG: $APP_SG"

echo "=> RDS Security Group (DB Tier)"
DB_SG=$(aws ec2 create-security-group \
  --group-name capstone-db-sg \
  --description "DB Tier: MySQL from app tier only" \
  --vpc-id "$VPC_ID" --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress --group-id "$DB_SG" --protocol tcp --port 3306 --source-group "$APP_SG" > /dev/null
echo "DB SG: $DB_SG"

echo ""
echo "Security group chain:"
echo "Internet -> ALB SG -> App SG -> DB SG"
echo "Zero direct internet access to app or DB tiers"
