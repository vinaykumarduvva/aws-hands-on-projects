# Cleanup Guide: Destroying ECS & Fargate Resources

To avoid ongoing charges for AWS Fargate compute usage and Application Load Balancer running hours, you must aggressively delete these resources when you are finished testing. 

Follow ONE of the three methods below to tear down the entire stack.

---

### 🖥️ Method 1: AWS Management Console

1. **Scale Down & Delete ECS Service:**
   - Navigate to **Amazon ECS** > **Clusters** > `flask-app-cluster`.
   - Select `flask-app-service`, click **Update**.
   - Change **Desired tasks** to `0`. Wait for the running tasks to terminate (status changes to draining/stopped).
   - Once task count is 0, select the service and click **Delete**.

2. **Delete Application Load Balancer:**
   - Navigate to **EC2 Console** > **Load Balancers**.
   - Select `flask-app-alb`, click **Actions** > **Delete**.
   - Navigate to **Target Groups**. Select `flask-app-tg` and delete it.

3. **Delete ECS Cluster:**
   - Go back to the **ECS Console** > **Clusters**.
   - Select `flask-app-cluster` and click **Delete cluster**.

4. **Delete ECR Repository:**
   - Navigate to **Amazon ECR** > **Repositories**.
   - Select `flask-app`. Because it contains images, click **Delete** and type `delete` to confirm force deletion.

5. **Deregister Task Definitions:**
   - In the **ECS Console**, go to **Task definitions**.
   - Select all active revisions of `flask-app-task` and click **Deregister**.

6. **Delete Security Groups:**
   - In the **EC2 Console** > **Security Groups**.
   - Delete `ecs-tasks-sg` first (since it depends on the ALB SG).
   - Delete `ecs-alb-sg`.

7. **Delete IAM Roles & CloudWatch Logs:**
   - In the **IAM Console** > **Roles**, delete `ecs-task-execution-role` and `ecs-task-role`.
   - In **CloudWatch Logs**, delete the `/ecs/flask-app-task` log group.

---

### 🐧 Method 2: AWS CLI (Bash)

Use the provided bash script to destroy the stack programmatically.

```bash
#!/bin/bash
# scripts/bash/05-cleanup.sh
set -e

CLUSTER_NAME="flask-app-cluster"
SERVICE_NAME="flask-app-service"
TASK_FAMILY="flask-app-task"
ECR_REPO="flask-app"

echo "Scaling down service to 0 tasks..."
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count 0 >/dev/null 2>&1 || true
sleep 30

echo "Deleting ECS service..."
aws ecs delete-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force >/dev/null 2>&1 || true

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
if [ "$ECS_SG" != "None" ]; then aws ec2 delete-security-group --group-id $ECS_SG || true; fi
ALB_SG=$(aws ec2 describe-security-groups --group-names ecs-alb-sg --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "None")
if [ "$ALB_SG" != "None" ]; then aws ec2 delete-security-group --group-id $ALB_SG || true; fi

echo "Cleanup complete."
```

---

### 🪟 Method 3: AWS CLI (PowerShell)

Use the provided PowerShell script to destroy the stack programmatically.

```powershell
# scripts/powershell/05-cleanup.ps1
$ErrorActionPreference = "Continue"

$CLUSTER_NAME = "flask-app-cluster"
$SERVICE_NAME = "flask-app-service"
$TASK_FAMILY = "flask-app-task"
$ECR_REPO = "flask-app"

Write-Host "Scaling down service to 0 tasks..."
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count 0 | Out-Null
Start-Sleep -Seconds 30

Write-Host "Deleting ECS service..."
aws ecs delete-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force | Out-Null

Write-Host "Deleting ALB and Target Group..."
$ALB_ARN = aws elbv2 describe-load-balancers --names flask-app-alb --query "LoadBalancers[0].LoadBalancerArn" --output text 2>$null
if ($ALB_ARN) {
  $LISTENER_ARN = aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query "Listeners[0].ListenerArn" --output text 2>$null
  if ($LISTENER_ARN) { aws elbv2 delete-listener --listener-arn $LISTENER_ARN }
  aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN
  Start-Sleep -Seconds 30
}
$TG_ARN = aws elbv2 describe-target-groups --names flask-app-tg --query "TargetGroups[0].TargetGroupArn" --output text 2>$null
if ($TG_ARN) { aws elbv2 delete-target-group --target-group-arn $TG_ARN }

Write-Host "Deleting ECS cluster & ECR repository..."
aws ecs delete-cluster --cluster $CLUSTER_NAME | Out-Null
aws ecr delete-repository --repository-name $ECR_REPO --force | Out-Null

Write-Host "Deregistering task definitions..."
$TASK_REVS = aws ecs list-task-definitions --family-prefix $TASK_FAMILY --query "taskDefinitionArns" --output text
foreach ($TASK_REV in $TASK_REVS.Split()) { 
    if ($TASK_REV) { aws ecs deregister-task-definition --task-definition $TASK_REV | Out-Null } 
}

Write-Host "Cleanup complete."
```
