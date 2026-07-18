# Deployment Guide: Containerized App on ECS Fargate

This guide details the complete process for building a Docker container, pushing it to Amazon ECR, and deploying it on ECS Fargate behind an Application Load Balancer.

---

## 🏗️ PART 1 — PRE-FLIGHT CHECKS

### 🖥️ Method 1: AWS Management Console
1. Navigate to the top right corner of the AWS Management Console.
2. Verify that you are operating in the **ap-south-1 (Mumbai)** region.
3. Note your AWS Account ID (the 12-digit number).
4. Ensure Docker Desktop is installed and running on your local machine.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# 00-pre-flight.sh

export REGION=$(aws configure get region)
export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

echo "Region: $REGION"
echo "Account ID: $ACCOUNT_ID"

export ECR_REPO="flask-app"
export CLUSTER_NAME="flask-app-cluster"
export SERVICE_NAME="flask-app-service"
export TASK_FAMILY="flask-app-task"
export ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo "ECR URI: $ECR_URI"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Confirm region ap-south-1
aws configure get region

# Get account ID
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
Write-Host "Account ID: $ACCOUNT_ID"

# Set variables
$ECR_REPO     = "flask-app"
$CLUSTER_NAME = "flask-app-cluster"
$SERVICE_NAME = "flask-app-service"
$TASK_FAMILY  = "flask-app-task"
$ECR_URI      = "$ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com"

Write-Host "ECR URI: $ECR_URI"
```

---

## 🏗️ PART 2 — ECR REPOSITORY & DOCKER BUILD

### 🖥️ Method 1: AWS Management Console & Local Docker
1. **Create ECR Repo**: Open the **ECR Console**, click **Create repository**. Name it `flask-app`. Enable **Scan on push**. Click **Create repository**.
2. **Authenticate**: Click on the new repository, click **View push commands**. Run the provided `aws ecr get-login-password` command in your terminal.
3. **Build & Push**: From the `flask-app` directory in your terminal, run:
   ```bash
   docker build -t flask-app:v1.0 .
   docker tag flask-app:v1.0 [ACCOUNT_ID].dkr.ecr.ap-south-1.amazonaws.com/flask-app:latest
   docker push [ACCOUNT_ID].dkr.ecr.ap-south-1.amazonaws.com/flask-app:latest
   ```

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# 01-build-push.sh
source ./00-pre-flight.sh

aws ecr create-repository \
  --repository-name $ECR_REPO \
  --region $REGION \
  --image-scanning-configuration scanOnPush=true

export ECR_REPO_URI=$(aws ecr describe-repositories --repository-names $ECR_REPO --query "repositories[0].repositoryUri" --output text)

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URI

docker build -t flask-app:v1.0 ../../flask-app
docker tag flask-app:v1.0 "${ECR_REPO_URI}:latest"
docker tag flask-app:v1.0 "${ECR_REPO_URI}:v1.0"

docker push "${ECR_REPO_URI}:latest"
docker push "${ECR_REPO_URI}:v1.0"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
. .\00-pre-flight.ps1

aws ecr create-repository `
  --repository-name $ECR_REPO `
  --region ap-south-1 `
  --image-scanning-configuration scanOnPush=true

$ECR_REPO_URI = aws ecr describe-repositories `
  --repository-names $ECR_REPO `
  --query "repositories[0].repositoryUri" `
  --output text

aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $ECR_URI

docker build -t flask-app:v1.0 ../../flask-app
docker tag flask-app:v1.0 "${ECR_REPO_URI}:latest"
docker tag flask-app:v1.0 "${ECR_REPO_URI}:v1.0"

docker push "${ECR_REPO_URI}:latest"
docker push "${ECR_REPO_URI}:v1.0"
```

---

## 🏗️ PART 3 — NETWORKING & IAM ROLES

### 🖥️ Method 1: AWS Management Console
1. **Security Groups**: 
   - Go to **EC2 Console > Security Groups**. Create `ecs-alb-sg` in Default VPC. Add Inbound HTTP (Port 80) from `0.0.0.0/0`.
   - Create `ecs-tasks-sg`. Add Inbound TCP Port 5000 from `ecs-alb-sg`.
2. **IAM Roles**: 
   - Go to **IAM > Roles**. Create `ecs-task-execution-role`. Select Elastic Container Service Task. Attach `AmazonECSTaskExecutionRolePolicy`.
   - Create `ecs-task-role` with similar trust relationships for the app to use.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# 02-networking-iam.sh
source ./00-pre-flight.sh

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)

ALB_SG=$(aws ec2 create-security-group --group-name ecs-alb-sg --description "ECS ALB allow HTTP" --vpc-id $VPC_ID --query "GroupId" --output text)
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr "0.0.0.0/0"

ECS_SG=$(aws ec2 create-security-group --group-name ecs-tasks-sg --description "ECS Fargate tasks allow from ALB" --vpc-id $VPC_ID --query "GroupId" --output text)
aws ec2 authorize-security-group-ingress --group-id $ECS_SG --protocol tcp --port 5000 --source-group $ALB_SG

aws iam create-role --role-name ecs-task-execution-role --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws iam attach-role-policy --role-name ecs-task-execution-role --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

aws iam create-role --role-name ecs-task-role --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
sleep 10
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
. .\00-pre-flight.ps1

$VPC_ID = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text

$ALB_SG = aws ec2 create-security-group --group-name ecs-alb-sg --description "ECS ALB allow HTTP" --vpc-id $VPC_ID --query "GroupId" --output text
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr "0.0.0.0/0"

$ECS_SG = aws ec2 create-security-group --group-name ecs-tasks-sg --description "ECS Fargate tasks allow from ALB" --vpc-id $VPC_ID --query "GroupId" --output text
aws ec2 authorize-security-group-ingress --group-id $ECS_SG --protocol tcp --port 5000 --source-group $ALB_SG

aws iam create-role --role-name ecs-task-execution-role --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws iam attach-role-policy --role-name ecs-task-execution-role --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

aws iam create-role --role-name ecs-task-role --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
Start-Sleep -Seconds 10
```

---

## 🏗️ PART 4 — ECS CLUSTER, TASK DEFINITION & ALB

### 🖥️ Method 1: AWS Management Console
1. **ECS Cluster**: Open **ECS Console**, create a cluster named `flask-app-cluster` using Fargate infrastructure.
2. **Task Definition**: Register a new Task Definition `flask-app-task`. Select Fargate, 0.5 vCPU, 1 GB Memory. Add a container referencing your ECR Image URI, mapped to port 5000. Set Log Configuration to `awslogs`.
3. **Load Balancer**: 
   - Open **EC2 Console > Target Groups**. Create `flask-app-tg`. Type: **IP addresses**, Port: 5000, VPC: Default. Health check path `/health`.
   - Go to **Load Balancers**. Create an **Application Load Balancer** named `flask-app-alb`. Select your subnets. Assign `ecs-alb-sg`. Add listener on Port 80 forwarding to `flask-app-tg`.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# 03-deploy-ecs.sh
source ./00-pre-flight.sh

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=defaultForAz,Values=true" --query "Subnets[*].SubnetId" --output text)
SUBNET_LIST=($SUBNETS)
ALB_SG=$(aws ec2 describe-security-groups --group-names ecs-alb-sg --query "SecurityGroups[0].GroupId" --output text)
ECS_SG=$(aws ec2 describe-security-groups --group-names ecs-tasks-sg --query "SecurityGroups[0].GroupId" --output text)
ECR_REPO_URI=$(aws ecr describe-repositories --repository-names $ECR_REPO --query "repositories[0].repositoryUri" --output text)

aws ecs create-cluster --cluster-name $CLUSTER_NAME --capacity-providers FARGATE --settings name=containerInsights,value=enabled
aws logs create-log-group --log-group-name "/ecs/flask-app-task" || true

EXEC_ROLE=$(aws iam get-role --role-name ecs-task-execution-role --query "Role.Arn" --output text)
TASK_ROLE=$(aws iam get-role --role-name ecs-task-role --query "Role.Arn" --output text)

# Write task-definition.json and register
# (Refer to scripts/bash/03-deploy-ecs.sh for JSON payload)
aws ecs register-task-definition --cli-input-json file://task-definition.json

TG_ARN=$(aws elbv2 create-target-group --name flask-app-tg --protocol HTTP --port 5000 --vpc-id $VPC_ID --target-type ip --health-check-path "/health" --query "TargetGroups[0].TargetGroupArn" --output text)
ALB_ARN=$(aws elbv2 create-load-balancer --name flask-app-alb --subnets ${SUBNET_LIST[0]} ${SUBNET_LIST[1]} --security-groups $ALB_SG --scheme internet-facing --type application --query "LoadBalancers[0].LoadBalancerArn" --output text)
aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTP --port 80 --default-actions "Type=forward,TargetGroupArn=$TG_ARN"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
. .\00-pre-flight.ps1
# Refer to scripts/powershell/03-deploy-ecs.ps1 for the equivalent detailed steps.
```

---

## 🏗️ PART 5 — DEPLOY ECS SERVICE & UPDATE

### 🖥️ Method 1: AWS Management Console
1. **ECS Service**: In `flask-app-cluster`, create service `flask-app-service`. Choose Fargate, select `flask-app-task`, desired count 2. Under Load Balancing, select ALB and attach the `flask-app-tg` Target Group.
2. **Update**: Once running, verify functionality via ALB DNS. Then update the service by registering a new Task Definition revision and checking "Force new deployment".

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# 04-update-service.sh
# Start the service
aws ecs create-service \
  --cluster $CLUSTER_NAME \
  --service-name $SERVICE_NAME \
  --task-definition $TASK_FAMILY \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_LIST[0]},${SUBNET_LIST[1]}],securityGroups=[$ECS_SG],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TG_ARN,containerName=flask-app,containerPort=5000"

aws ecs wait services-stable --cluster $CLUSTER_NAME --services $SERVICE_NAME

# Update image and push new revision, then:
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Refer to scripts/powershell/04-update-service.ps1 for the equivalent detailed steps.
```
