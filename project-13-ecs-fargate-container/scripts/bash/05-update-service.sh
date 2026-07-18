#!/bin/bash
set -e

CLUSTER_NAME="flask-app-cluster"
SERVICE_NAME="flask-app-service"
TASK_FAMILY="flask-app-task"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
ECR_REPO_URI=$(aws ecr describe-repositories --repository-names flask-app --query "repositories[0].repositoryUri" --output text)

echo "Updating app.py..."
sed -i 's/Version 1.0/Version 2.0/g' ../../flask-app/app.py

echo "Building Docker image..."
docker build -t flask-app:v2.0 ../../flask-app
docker tag flask-app:v2.0 "${ECR_REPO_URI}:v2.0"
docker tag flask-app:v2.0 "${ECR_REPO_URI}:latest"

echo "Pushing to ECR..."
docker push "${ECR_REPO_URI}:v2.0"
docker push "${ECR_REPO_URI}:latest"

echo "Registering new task definition revision..."
aws ecs register-task-definition --cli-input-json file://task-definition.json

NEW_REV=$(aws ecs describe-task-definition --task-definition $TASK_FAMILY --query "taskDefinition.revision" --output text)
echo "New task definition revision: $NEW_REV"

aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition "${TASK_FAMILY}:${NEW_REV}" --force-new-deployment

echo "Rolling deployment started..."
aws ecs wait services-stable --cluster $CLUSTER_NAME --services $SERVICE_NAME
echo "Deployment complete."
