#!/bin/bash
set -e

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo "Account ID: $ACCOUNT_ID"

ECR_REPO="flask-app"
ECR_URI="$ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com"

# Create ECR repository
aws ecr create-repository \
  --repository-name $ECR_REPO \
  --region ap-south-1 \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256 \
  --tags Key=Project,Value=project-13-ecs-fargate

ECR_REPO_URI=$(aws ecr describe-repositories --repository-names $ECR_REPO --query "repositories[0].repositoryUri" --output text)
echo "ECR Repository URI: $ECR_REPO_URI"

# Login Docker to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $ECR_URI

# Build the Docker image
echo "Building Docker image..."
docker build -t flask-app:v1.0 ../../flask-app

# Tag image with ECR URI
docker tag flask-app:v1.0 "${ECR_REPO_URI}:v1.0"
docker tag flask-app:v1.0 "${ECR_REPO_URI}:latest"

# Push both tags to ECR
echo "Pushing to ECR..."
docker push "${ECR_REPO_URI}:v1.0"
docker push "${ECR_REPO_URI}:latest"

echo "Build and push complete."
