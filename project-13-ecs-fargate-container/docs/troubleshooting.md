# Troubleshooting Guide

This guide provides deep-dive solutions for the most common errors encountered when deploying containers to ECS Fargate.

## 🔴 Issue: Tasks stuck in PENDING state
**Symptoms:** When viewing the ECS Service, tasks remain in `PENDING` indefinitely, and eventually fail to launch, restarting in a loop.
**Common Causes & Fixes:**
1. **CannotPullContainerError:** The Fargate infrastructure cannot pull the Docker image from ECR.
   - *Fix:* Ensure that the `ecs-task-execution-role` has the `AmazonECSTaskExecutionRolePolicy` attached. Without this, ECS cannot authenticate with ECR to download the image.
2. **Invalid Subnets/VPC:** The ECS Service is attempting to launch tasks into private subnets without a NAT Gateway, or public subnets without `assignPublicIp=ENABLED`.
   - *Fix:* If launching into default VPC subnets (which are public), ensure that Auto-assign public IP is set to `ENABLED` in the service network configuration so the task can reach ECR to pull the image.

## 🔴 Issue: Tasks launching but failing health checks (Unhealthy)
**Symptoms:** Tasks transition to `RUNNING` for a few minutes, but the ALB marks them as `unhealthy`, and ECS ultimately kills and replaces them.
**Common Causes & Fixes:**
1. **Application Crash:** The container is starting, but the Flask app is throwing a Python exception immediately.
   - *Fix:* Navigate to **CloudWatch Logs** > `/ecs/flask-app-task` and read the error logs. It could be a missing dependency in `requirements.txt` or a syntax error in `app.py`.
2. **Incorrect Port Mapping:** The ALB is sending health check pings to port 5000, but the container is listening on port 80 (or vice versa).
   - *Fix:* Verify that the `Dockerfile` exposes port 5000, the Flask/Gunicorn app binds to `0.0.0.0:5000`, and the Target Group is configured for port 5000.
3. **Security Group Blocking:** The task is running fine, but the ALB cannot reach it.
   - *Fix:* Check `ecs-tasks-sg`. It MUST allow inbound TCP traffic on port 5000 sourced from `ecs-alb-sg`.

## 🔴 Issue: ALB shows 502 Bad Gateway
**Symptoms:** You navigate to the ALB DNS name in your browser, but receive a "502 Bad Gateway" error instead of the Flask UI.
**Common Causes & Fixes:**
1. **No Healthy Targets:** The ALB has no healthy containers to route traffic to.
   - *Fix:* Check the Target Group health status. If targets are draining or unhealthy, refer to the health check troubleshooting steps above.
2. **Health Check Grace Period:** The containers just started, and the application needs time to boot.
   - *Fix:* The ECS service is configured with a `health-check-grace-period-seconds`. Wait 60 seconds and refresh the browser.

## 🔴 Issue: docker login fails with authorization token expired
**Symptoms:** Running `docker push` results in an authentication denied error.
**Common Causes & Fixes:**
- *Cause:* The ECR authentication token retrieved via `aws ecr get-login-password` is only valid for 12 hours.
- *Fix:* Re-authenticate by running the login command again:
  ```bash
  aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com
  ```

## 🔴 Issue: Zero-Downtime Deployment Not Progressing
**Symptoms:** You forced a new deployment, but the old tasks remain `RUNNING` and the new tasks are stuck in `PROVISIONING` or `PENDING`.
**Common Causes & Fixes:**
- *Cause:* If your service's `maximumPercent` is set to 100% and `minimumHealthyPercent` is 100%, ECS cannot start new tasks (because that would exceed 100% capacity) and cannot kill old tasks (because that would drop below 100% capacity).
- *Fix:* Ensure the service's deployment configuration allows headroom. Set `minimumHealthyPercent` to 100% and `maximumPercent` to 200%. This allows ECS to spin up 2 new tasks (reaching 200% capacity temporarily) before draining the 2 old tasks.
