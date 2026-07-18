#!/bin/bash
set -e

CLUSTER_NAME="flask-app-cluster"
SERVICE_NAME="flask-app-service"
TASK_FAMILY="flask-app-task"

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=defaultForAz,Values=true" --query "Subnets[*].SubnetId" --output text)
SUBNET_LIST=($SUBNETS)
SUBNET_A=${SUBNET_LIST[0]}
SUBNET_B=${SUBNET_LIST[1]}
ECS_SG=$(aws ec2 describe-security-groups --group-names ecs-tasks-sg --query "SecurityGroups[0].GroupId" --output text)
TG_ARN=$(aws elbv2 describe-target-groups --names flask-app-tg --query "TargetGroups[0].TargetGroupArn" --output text)
ALB_DNS=$(aws elbv2 describe-load-balancers --names flask-app-alb --query "LoadBalancers[0].DNSName" --output text)

echo "Creating ECS Service..."
aws ecs create-service \
  --cluster $CLUSTER_NAME \
  --service-name $SERVICE_NAME \
  --task-definition $TASK_FAMILY \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_A,$SUBNET_B],securityGroups=[$ECS_SG],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TG_ARN,containerName=flask-app,containerPort=5000" \
  --deployment-configuration "minimumHealthyPercent=100,maximumPercent=200" \
  --health-check-grace-period-seconds 60

echo "Waiting for ECS service to become stable (This usually takes 2-4 minutes)..."
aws ecs wait services-stable --cluster $CLUSTER_NAME --services $SERVICE_NAME

echo "ECS Service created and stable! You can now access the app at: http://$ALB_DNS"
