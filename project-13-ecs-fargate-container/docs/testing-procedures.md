# Testing Procedures

This document outlines the testing protocols for validating the ECS Fargate deployment, zero-downtime updates, and Application Load Balancer routing.

## 🧪 1. Local Container Validation

Before pushing the container image to ECR, it is crucial to validate the container's functionality locally on Docker Desktop.

1. **Build the Image:**
   ```bash
   docker build -t flask-app:v1.0 .
   ```
2. **Run the Image Locally:**
   ```bash
   docker run -d --name flask-test -p 8080:5000 flask-app:v1.0
   ```
3. **Verify the Health Check:**
   Navigate to `http://localhost:8080/health` or use `curl`:
   ```bash
   curl http://localhost:8080/health
   # Expected Output: {"status": "healthy", "version": "1.0", ...}
   ```
4. **Clean up Local Container:**
   ```bash
   docker stop flask-test && docker rm flask-test
   ```

## 🧪 2. ECS Deployment & ALB Routing Validation

After the stack is deployed, you must verify that the Application Load Balancer successfully routes traffic to the healthy Fargate tasks.

1. **Obtain the ALB DNS Name:**
   Find the DNS Name in the EC2 Load Balancers console (e.g., `flask-app-alb-xxx.ap-south-1.elb.amazonaws.com`).
2. **Hit the Health Endpoint:**
   Navigate to `http://<ALB-DNS-NAME>/health`. You should receive a healthy response.
3. **Verify Load Balancing (Round Robin):**
   Refresh the page multiple times or run a `curl` loop:
   ```bash
   for i in {1..4}; do curl -s http://<ALB-DNS-NAME>/health | grep hostname; done
   ```
   *Success Condition:* You should see two different hostnames returned alternately, proving that the ALB is distributing traffic between the two Fargate tasks running in different Availability Zones.

## 🧪 3. Zero-Downtime Rolling Update Validation

One of the primary benefits of ECS is its ability to perform zero-downtime deployments. To test this:

1. **Monitor Current Traffic:**
   Open a terminal and run a continuous loop hitting the ALB:
   ```bash
   while true; do curl -s http://<ALB-DNS-NAME>/api/info | grep version; sleep 1; done
   ```
   *You will see `"version": "1.0"` repeatedly.*
2. **Trigger the Update:**
   Update the application code (e.g., change version to `2.0`), build the new Docker image, push it to ECR, and update the ECS Service with `--force-new-deployment`.
3. **Observe the Transition:**
   Watch your terminal running the continuous `curl` loop.
   - First, you will continue to see only `1.0`.
   - Then, as new tasks pass their health checks and register with the Target Group, you will see a mix of `1.0` and `2.0`.
   - Finally, once the old tasks are drained and deregistered, you will solely see `2.0`.
   *Success Condition:* At no point should the `curl` command fail or return a 502/503 HTTP error code. The application remains fully available during the rollout.
