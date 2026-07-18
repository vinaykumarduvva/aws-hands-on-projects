$ErrorActionPreference = "Stop"

$VPC_ID = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
$SUBNETS = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=defaultForAz,Values=true" --query "Subnets[*].SubnetId" --output text
$SUBNET_LIST = $SUBNETS -split '\s+'
$SUBNET_A = $SUBNET_LIST[0]
$SUBNET_B = $SUBNET_LIST[1]

Write-Host "VPC: $VPC_ID"
Write-Host "Subnet A: $SUBNET_A"
Write-Host "Subnet B: $SUBNET_B"

# Create ALB SG
$ALB_SG = aws ec2 create-security-group --group-name ecs-alb-sg --description "ECS ALB allow HTTP" --vpc-id $VPC_ID --query "GroupId" --output text
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr "0.0.0.0/0"
Write-Host "ALB SG: $ALB_SG"

# Create ECS SG
$ECS_SG = aws ec2 create-security-group --group-name ecs-tasks-sg --description "ECS Fargate tasks allow from ALB" --vpc-id $VPC_ID --query "GroupId" --output text
aws ec2 authorize-security-group-ingress --group-id $ECS_SG --protocol tcp --port 5000 --source-group $ALB_SG
Write-Host "ECS Tasks SG: $ECS_SG"

# Task Execution Role
aws iam create-role --role-name ecs-task-execution-role --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws iam attach-role-policy --role-name ecs-task-execution-role --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

$EXEC_ROLE_ARN = aws iam get-role --role-name ecs-task-execution-role --query "Role.Arn" --output text
Write-Host "Execution Role ARN: $EXEC_ROLE_ARN"

# Task Role
aws iam create-role --role-name ecs-task-role --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
$TASK_ROLE_ARN = aws iam get-role --role-name ecs-task-role --query "Role.Arn" --output text
Write-Host "Task Role ARN: $TASK_ROLE_ARN"

Write-Host "Waiting 10s for IAM propagation..."
Start-Sleep -Seconds 10
Write-Host "Networking and IAM setup complete."
