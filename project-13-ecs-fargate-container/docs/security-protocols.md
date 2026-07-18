# Security Protocols

This document outlines the security mechanisms implemented in the Containerized App on ECS Fargate architecture.

## 🔐 1. Network Isolation (Security Groups)

The most critical layer of defense is at the network level. We employ a two-tier security group strategy to prevent direct internet access to the containerized workloads.

### Application Load Balancer Security Group (`ecs-alb-sg`)
- **Inbound:** Allows HTTP (Port 80) and/or HTTPS (Port 443) traffic from anywhere (`0.0.0.0/0`).
- **Purpose:** Acts as the public-facing entry point for the application.

### ECS Tasks Security Group (`ecs-tasks-sg`)
- **Inbound:** Allows TCP Port 5000 (the Flask app port) **ONLY** if the traffic originates from the `ecs-alb-sg` Security Group.
- **Purpose:** Ensures that malicious actors cannot scan or access the containers directly, even if they somehow discovered the dynamic public IPs of the Fargate instances.

## 🛡️ 2. Identity and Access Management (IAM)

We strictly adhere to the principle of least privilege by separating the execution roles.

### ECS Task Execution Role (`ecs-task-execution-role`)
- **Assumed by:** The underlying ECS agent / Fargate infrastructure.
- **Permissions:** 
  - `ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, `ecr:GetDownloadUrlForLayer`, `ecr:BatchGetImage` (Allows downloading the container image from the private ECR repo).
  - `logs:CreateLogStream`, `logs:PutLogEvents` (Allows pushing container stdout/stderr to CloudWatch Logs).
- **Purpose:** Enables AWS to launch the container and wire up its logging. It does **not** grant the application itself any AWS API permissions.

### ECS Task Role (`ecs-task-role`)
- **Assumed by:** The running container (the Flask application itself).
- **Permissions:** Empty by default in this project.
- **Purpose:** If the Flask app needed to read from an S3 bucket or query a DynamoDB table, those specific permissions would be attached here. This guarantees that if the application is compromised, the blast radius is strictly limited to the permissions explicitly granted to this role.

## 🔒 3. Image Security

- **Private Registry:** The Docker images are stored in a private Amazon ECR repository, preventing unauthorized public access to the proprietary source code and configuration.
- **Image Scanning:** ECR is configured with `scanOnPush=true`. This ensures that every time a new image is pushed, AWS automatically scans the image layers against a database of known Common Vulnerabilities and Exposures (CVEs).

## 📡 4. Compute Isolation (AWS Fargate)
- **No Shared Underlying OS:** Unlike running tasks on shared EC2 instances, AWS Fargate provisions a dedicated micro-VM for every single task. 
- **Security Boundary:** Even if a container breakout were to occur within a task, the attacker would hit a hard virtualization boundary, unable to view, access, or compromise any other tasks running in the same cluster or on the same AWS infrastructure.
