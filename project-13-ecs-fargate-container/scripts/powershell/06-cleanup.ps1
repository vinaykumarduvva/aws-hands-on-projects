$CLUSTER_NAME = "flask-app-cluster"
$SERVICE_NAME = "flask-app-service"
$TASK_FAMILY = "flask-app-task"
$ECR_REPO = "flask-app"

Write-Host "Scaling down service to 0 tasks..."
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count 0
Start-Sleep -Seconds 30

Write-Host "Deleting ECS service..."
aws ecs delete-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force

Write-Host "Deleting ALB and listener..."
$ALB_ARN = aws elbv2 describe-load-balancers --names flask-app-alb --query "LoadBalancers[0].LoadBalancerArn" --output text
$LISTENER_ARN = aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query "Listeners[0].ListenerArn" --output text
if ($LISTENER_ARN -and $LISTENER_ARN -ne "None") { aws elbv2 delete-listener --listener-arn $LISTENER_ARN }
if ($ALB_ARN -and $ALB_ARN -ne "None") { aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN }
Start-Sleep -Seconds 30

Write-Host "Deleting target group..."
$TG_ARN = aws elbv2 describe-target-groups --names flask-app-tg --query "TargetGroups[0].TargetGroupArn" --output text
if ($TG_ARN -and $TG_ARN -ne "None") { aws elbv2 delete-target-group --target-group-arn $TG_ARN }

Write-Host "Deleting ECS cluster..."
aws ecs delete-cluster --cluster $CLUSTER_NAME

Write-Host "Deleting ECR repository..."
aws ecr delete-repository --repository-name $ECR_REPO --force

Write-Host "Deregistering task definitions..."
$TASK_REVS = aws ecs list-task-definitions --family-prefix $TASK_FAMILY --query "taskDefinitionArns" --output text
foreach ($TASK_REV in $TASK_REVS.Split()) { if ($TASK_REV) { aws ecs deregister-task-definition --task-definition $TASK_REV | Out-Null } }

Write-Host "Deleting security groups..."
$ECS_SG = aws ec2 describe-security-groups --group-names ecs-tasks-sg --query "SecurityGroups[0].GroupId" --output text
if ($ECS_SG -and $ECS_SG -ne "None") { aws ec2 delete-security-group --group-id $ECS_SG }
$ALB_SG = aws ec2 describe-security-groups --group-names ecs-alb-sg --query "SecurityGroups[0].GroupId" --output text
if ($ALB_SG -and $ALB_SG -ne "None") { aws ec2 delete-security-group --group-id $ALB_SG }

Write-Host "Deleting IAM roles..."
foreach ($ROLE in @("ecs-task-execution-role", "ecs-task-role")) {
  $POLICIES = aws iam list-attached-role-policies --role-name $ROLE --query "AttachedPolicies[*].PolicyArn" --output text
  foreach ($P in $POLICIES.Split()) { if ($P) { aws iam detach-role-policy --role-name $ROLE --policy-arn $P } }
  aws iam delete-role --role-name $ROLE 2>$null
}

Write-Host "Deleting CloudWatch log group..."
aws logs delete-log-group --log-group-name "/ecs/flask-app-task"
Write-Host "Cleanup complete."
