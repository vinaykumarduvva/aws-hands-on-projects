#!/bin/bash
set -e

CLUSTER_NAME="flask-app-cluster"
SERVICE_NAME="flask-app-service"
TASK_FAMILY="flask-app-task"
ECR_REPO="flask-app"

echo "Scaling down service to 0 tasks..."
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count 0 || true
sleep 30

echo "Deleting ECS service..."
aws ecs delete-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force || true

echo "Deleting ALB and listener..."
ALB_ARN=$(aws elbv2 describe-load-balancers --names flask-app-alb --query "LoadBalancers[0].LoadBalancerArn" --output text 2>/dev/null || echo "None")
if [ "$ALB_ARN" != "None" ]; then
  LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query "Listeners[0].ListenerArn" --output text 2>/dev/null || echo "None")
  if [ "$LISTENER_ARN" != "None" ]; then
    aws elbv2 delete-listener --listener-arn $LISTENER_ARN || true
  fi
  aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN || true
  sleep 30
fi

echo "Deleting target group..."
TG_ARN=$(aws elbv2 describe-target-groups --names flask-app-tg --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null || echo "None")
if [ "$TG_ARN" != "None" ]; then
  aws elbv2 delete-target-group --target-group-arn $TG_ARN || true
fi

echo "Deleting ECS cluster..."
aws ecs delete-cluster --cluster $CLUSTER_NAME || true

echo "Deleting ECR repository..."
aws ecr delete-repository --repository-name $ECR_REPO --force || true

echo "Deregistering task definitions..."
TASK_REVS=$(aws ecs list-task-definitions --family-prefix $TASK_FAMILY --query "taskDefinitionArns" --output text || echo "")
for TASK_REV in $TASK_REVS; do
  aws ecs deregister-task-definition --task-definition $TASK_REV >/dev/null || true
done

echo "Deleting security groups..."
ECS_SG=$(aws ec2 describe-security-groups --group-names ecs-tasks-sg --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "None")
if [ "$ECS_SG" != "None" ]; then
  aws ec2 delete-security-group --group-id $ECS_SG || true
fi
ALB_SG=$(aws ec2 describe-security-groups --group-names ecs-alb-sg --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "None")
if [ "$ALB_SG" != "None" ]; then
  aws ec2 delete-security-group --group-id $ALB_SG || true
fi

echo "Deleting IAM roles..."
for ROLE in ecs-task-execution-role ecs-task-role; do
  POLICIES=$(aws iam list-attached-role-policies --role-name $ROLE --query "AttachedPolicies[*].PolicyArn" --output text 2>/dev/null || echo "")
  for P in $POLICIES; do
    aws iam detach-role-policy --role-name $ROLE --policy-arn $P || true
  done
  aws iam delete-role --role-name $ROLE 2>/dev/null || true
done

echo "Deleting CloudWatch log group..."
aws logs delete-log-group --log-group-name "/ecs/flask-app-task" || true
echo "Cleanup complete."
