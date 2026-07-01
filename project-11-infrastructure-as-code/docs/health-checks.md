# Health Checks Design

Robust health checking is vital for maintaining a highly available and self-healing infrastructure. In this CloudFormation stack, health checks are configured at both the Load Balancer and Auto Scaling Group levels.

## 1. Application Load Balancer (Target Group) Health Checks

The `WebServerTargetGroup` is responsible for actively monitoring the health of the EC2 instances.

- **Protocol**: `HTTP`
- **Path**: `/` (The default Apache web root serving our `index.html`)
- **Interval**: `30` seconds
- **Healthy Threshold**: `2` consecutive successes
- **Unhealthy Threshold**: `2` consecutive failures

**Behavior:**
The ALB sends an HTTP GET request to port 80 on each instance every 30 seconds. If an instance responds with an HTTP 200 OK status twice in a row, it is marked as **Healthy** and receives traffic. If it fails to respond or returns an error twice in a row, it is marked as **Unhealthy** and the ALB stops routing traffic to it.

## 2. Auto Scaling Group (ASG) Health Checks

The `WebServerASG` must know when an instance is unhealthy so it can terminate it and launch a replacement.

- **Health Check Type**: `ELB` (Elastic Load Balancer)
- **Grace Period**: `120` seconds

**Behavior:**
By default, an ASG only uses `EC2` health checks (which monitor hardware/hypervisor status). By setting this to `ELB`, the ASG relies on the Target Group's health checks. 
If the ALB marks an instance as unhealthy (e.g., Apache crashes, but the instance is still running), the ASG will automatically terminate the instance and spin up a fresh one.

The **Grace Period (120s)** is crucial. It tells the ASG to wait 2 minutes after launching a new instance before checking its health. This gives the instance enough time to boot, run the User Data script (installing Apache), and start serving web pages without being prematurely marked as unhealthy.
