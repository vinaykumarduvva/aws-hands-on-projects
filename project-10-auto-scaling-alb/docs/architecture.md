# Architecture — Project 10 Auto Scaling Group + ALB

## High-Level Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                        Internet                                  │
│                        Users / Browsers                          │
└──────────────────────────────┬──────────────────────────────────┘
                               │ HTTP (port 80)
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│              Application Load Balancer (ALB)                     │
│              Name: my-alb                                        │
│              Scheme: internet-facing                             │
│              DNS: my-alb-xxxxx.ap-south-1.elb.amazonaws.com      │
│              Security Group: alb-sg (HTTP:80, HTTPS:443)         │
│                                                                  │
│              Listener: HTTP:80 → Forward to web-server-tg        │
└──────────────────────────────┬──────────────────────────────────┘
                               │ round-robin distribution
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│   EC2 Instance   │ │   EC2 Instance   │ │   EC2 Instance   │
│   t2.micro       │ │   t2.micro       │ │   t2.micro       │
│   AZ: 1a         │ │   AZ: 1b         │ │   AZ: 1a         │
│   Apache httpd   │ │   Apache httpd   │ │   Apache httpd   │
│   SG: asg-ec2-sg │ │   SG: asg-ec2-sg │ │   SG: asg-ec2-sg │
└──────────────────┘ └──────────────────┘ └──────────────────┘
         │                    │                    │
         └────────────────────┴────────────────────┘
                              │
              ┌───────────────────────────────┐
              │     Auto Scaling Group        │
              │     Name: web-server-asg      │
              │     Min: 2 | Desired: 2       │
              │     Max: 4                    │
              │     Launch Template: web-     │
              │       server-lt               │
              │     Health Check: ELB (ALB)   │
              │     Scaling: CPU > 50%        │
              └───────────────────────────────┘
```

---

## Component Architecture

### Application Load Balancer (ALB)

```text
ALB: my-alb
├── Scheme: internet-facing
├── IP Type: IPv4
├── AZs: ap-south-1a, ap-south-1b
├── Security Group: alb-sg
│   ├── Inbound: TCP 80 from 0.0.0.0/0  (HTTP)
│   └── Inbound: TCP 443 from 0.0.0.0/0 (HTTPS — future)
│
└── Listener: HTTP:80
    └── Default Action: Forward to web-server-tg
```

### Target Group

```text
Target Group: web-server-tg
├── Protocol: HTTP
├── Port: 80
├── Target Type: instance
├── VPC: Default VPC
│
├── Health Check:
│   ├── Protocol: HTTP
│   ├── Path: /
│   ├── Interval: 30 seconds
│   ├── Timeout: 5 seconds
│   ├── Healthy threshold: 2 consecutive checks
│   ├── Unhealthy threshold: 2 consecutive failures
│   └── Success codes: 200
│
└── Targets: (registered by ASG automatically)
    ├── i-001 (ap-south-1a) → healthy
    └── i-002 (ap-south-1b) → healthy
```

### Auto Scaling Group

```text
ASG: web-server-asg
├── Launch Template: web-server-lt ($Latest)
├── VPC Zone Identifier: subnet-a, subnet-b
├── Target Group ARN: web-server-tg
│
├── Capacity:
│   ├── Minimum: 2
│   ├── Desired: 2
│   └── Maximum: 4
│
├── Health Check:
│   ├── Type: ELB (ALB health check via Target Group)
│   └── Grace Period: 120 seconds
│
├── Scaling Policy: cpu-target-tracking
│   ├── Type: TargetTrackingScaling
│   ├── Metric: ASGAverageCPUUtilization
│   ├── Target: 50%
│   └── Instance Warmup: 120 seconds
│
└── Tags (propagated to instances):
    ├── Name: asg-web-server
    └── Project: project-10-asg-alb
```

### Launch Template

```text
Launch Template: web-server-lt
├── Version: v1 — Apache web server
├── AMI: Amazon Linux 2023 (al2023-ami-*-x86_64)
├── Instance Type: t2.micro
├── Key Pair: aws-ec2-keypair
├── Security Group: asg-ec2-sg
│   ├── Inbound: TCP 80 from alb-sg (HTTP from ALB only)
│   └── Inbound: TCP 22 from MY_IP/32 (SSH for debugging)
│
└── User Data (runs on boot):
    ├── yum update -y
    ├── yum install httpd stress
    ├── systemctl start httpd
    ├── systemctl enable httpd
    ├── Fetch instance metadata (ID, AZ, IP)
    └── Generate custom HTML page per instance
```

---

## Network Architecture

```text
VPC: Default VPC (ap-south-1)
│
├── Public Subnet A (ap-south-1a)
│   ├── ALB ENI (elastic network interface)
│   └── EC2 instances (launched by ASG)
│
└── Public Subnet B (ap-south-1b)
    ├── ALB ENI (elastic network interface)
    └── EC2 instances (launched by ASG)

Security Groups:
┌──────────────────────────────────────────────────────────┐
│  alb-sg (ALB Security Group)                             │
│  ├── Inbound: TCP 80  from 0.0.0.0/0                    │
│  └── Inbound: TCP 443 from 0.0.0.0/0                    │
│                                                          │
│  asg-ec2-sg (EC2 Security Group)                         │
│  ├── Inbound: TCP 80  from alb-sg ← KEY: ALB only       │
│  └── Inbound: TCP 22  from MY_IP/32                      │
└──────────────────────────────────────────────────────────┘

Traffic Flow:
  Internet → ALB (alb-sg) → EC2 (asg-ec2-sg)
  EC2 instances are NOT directly accessible on port 80
  from the internet — only through the ALB.
```

---

## Scaling Architecture

```text
CloudWatch Alarm: TargetTracking-web-server-asg-AlarmHigh
├── Metric: ASGAverageCPUUtilization
├── Threshold: > 50% for 3 minutes
└── Action: Scale out (add instances, up to max 4)

CloudWatch Alarm: TargetTracking-web-server-asg-AlarmLow
├── Metric: ASGAverageCPUUtilization
├── Threshold: < 35% for 15 minutes
└── Action: Scale in (remove instances, down to min 2)

Timeline:
  CPU > 50% sustained → ~5 min → alarm triggers → instance launching
  Instance launching   → ~2 min → user data runs → Apache starts
  Apache starts        → ~1 min → health check passes → traffic received
  Total scale-out time: ~8 minutes from CPU spike to serving traffic
```

---

## Self-Healing Architecture

```text
Normal State:
  Instance A: InService (healthy) ← ALB sends traffic
  Instance B: InService (healthy) ← ALB sends traffic

Instance A Fails (terminated, crashed):
  Instance A: Terminated           ← ALB stops sending traffic
  Instance B: InService (healthy)  ← ALB sends ALL traffic here
  Instance C: Pending              ← ASG launches replacement

After Recovery (~3-4 minutes):
  Instance B: InService (healthy) ← ALB sends traffic
  Instance C: InService (healthy) ← ALB sends traffic (replaced A)

Key: ALB health checks detect failure → ASG replaces → ALB registers new
     Zero downtime, zero manual intervention.
```

---

## Data Flow Summary

```text
1. User opens browser → http://my-alb-xxxxx.ap-south-1.elb.amazonaws.com

2. DNS resolves ALB DNS name to ALB's public IPs (in both AZs)

3. ALB receives HTTP request on port 80

4. ALB listener matches HTTP:80 → forwards to web-server-tg

5. Target Group selects a healthy instance (round-robin)

6. ALB forwards request to EC2 instance on port 80

7. Apache on EC2 serves index.html (shows instance ID, AZ, IP)

8. Response flows back: EC2 → ALB → User's browser

9. Next request → ALB picks a different instance (load balancing)
```

---

## ALB vs NLB vs CLB Comparison

| Feature | ALB (Layer 7) | NLB (Layer 4) | CLB (Legacy) |
|---|---|---|---|
| Protocol | HTTP/HTTPS/WebSocket | TCP/UDP/TLS | HTTP/TCP |
| Routing | Path, host, header, query | IP, port | Round robin |
| Use case | Web apps, microservices | Gaming, IoT, low latency | Legacy only |
| SSL termination | ✅ Yes | ✅ Yes | ✅ Yes |
| WebSocket | ✅ Yes | ✅ Yes | ❌ No |
| Health checks | HTTP/HTTPS | TCP | HTTP/TCP |
| **This project** | **✅ We use this** | | |

---

## Monitoring and Observability

| What to monitor | Where | Metric |
|---|---|---|
| ALB request count | CloudWatch | RequestCount per target |
| Target health | ALB console | healthy/unhealthy count |
| Instance CPU | CloudWatch | CPUUtilization per instance |
| ASG instance count | CloudWatch | GroupInServiceInstances |
| Scaling activities | ASG console | Activity history |
| HTTP errors | ALB metrics | HTTPCode_Target_5XX_Count |

---
