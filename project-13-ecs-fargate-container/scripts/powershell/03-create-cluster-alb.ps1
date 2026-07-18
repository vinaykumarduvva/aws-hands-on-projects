$ErrorActionPreference = "Stop"

$CLUSTER_NAME = "flask-app-cluster"
$TASK_FAMILY = "flask-app-task"
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
$ECR_REPO_URI = aws ecr describe-repositories --repository-names flask-app --query "repositories[0].repositoryUri" --output text
$EXEC_ROLE_ARN = aws iam get-role --role-name ecs-task-execution-role --query "Role.Arn" --output text
$TASK_ROLE_ARN = aws iam get-role --role-name ecs-task-role --query "Role.Arn" --output text

$VPC_ID = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
$SUBNETS = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=defaultForAz,Values=true" --query "Subnets[*].SubnetId" --output text
$SUBNET_LIST = $SUBNETS -split '\s+'
$SUBNET_A = $SUBNET_LIST[0]
$SUBNET_B = $SUBNET_LIST[1]
$ALB_SG = aws ec2 describe-security-groups --group-names ecs-alb-sg --query "SecurityGroups[0].GroupId" --output text

Write-Host "Creating ECS cluster..."
aws ecs create-cluster --cluster-name $CLUSTER_NAME --capacity-providers FARGATE FARGATE_SPOT --settings name=containerInsights,value=enabled | Out-Null

Write-Host "Creating CloudWatch Log Group..."
aws logs create-log-group --log-group-name "/ecs/flask-app-task" 2>$null
aws logs put-retention-policy --log-group-name "/ecs/flask-app-task" --retention-in-days 7 | Out-Null

$TASK_DEF = @"
{
  "family": "$TASK_FAMILY",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "taskRoleArn": "$TASK_ROLE_ARN",
  "executionRoleArn": "$EXEC_ROLE_ARN",
  "containerDefinitions": [{
    "name": "flask-app",
    "image": "${ECR_REPO_URI}:latest",
    "portMappings": [{"containerPort": 5000, "protocol": "tcp"}],
    "environment": [
      {"name": "AWS_REGION", "value": "ap-south-1"},
      {"name": "ENVIRONMENT", "value": "production"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/flask-app-task",
        "awslogs-region": "ap-south-1",
        "awslogs-stream-prefix": "flask-app"
      }
    },
    "healthCheck": {
      "command": ["CMD-SHELL", "curl -f http://localhost:5000/health || exit 1"],
      "interval": 30,
      "timeout": 5,
      "retries": 3,
      "startPeriod": 15
    },
    "essential": true
  }]
}
"@
$TASK_DEF | Out-File -FilePath "task-definition.json" -Encoding utf8
Write-Host "Registering Task Definition..."
aws ecs register-task-definition --cli-input-json file://task-definition.json | Out-Null

Write-Host "Creating Target Group and ALB..."
$TG_ARN = aws elbv2 create-target-group --name flask-app-tg --protocol HTTP --port 5000 --vpc-id $VPC_ID --target-type ip --health-check-protocol HTTP --health-check-path "/health" --health-check-interval-seconds 30 --healthy-threshold-count 2 --unhealthy-threshold-count 3 --query "TargetGroups[0].TargetGroupArn" --output text
$ALB_ARN = aws elbv2 create-load-balancer --name flask-app-alb --subnets $SUBNET_A $SUBNET_B --security-groups $ALB_SG --scheme internet-facing --type application --query "LoadBalancers[0].LoadBalancerArn" --output text
$ALB_DNS = aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query "LoadBalancers[0].DNSName" --output text
$LISTENER_ARN = aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTP --port 80 --default-actions "Type=forward,TargetGroupArn=$TG_ARN" --query "Listeners[0].ListenerArn" --output text

Write-Host "Waiting for ALB to become active..."
aws elbv2 wait load-balancer-available --load-balancer-arns $ALB_ARN
Write-Host "ALB is ready at: http://$ALB_DNS"
