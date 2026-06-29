# Project 10 — Auto Scaling Group + Application Load Balancer

![AWS](https://img.shields.io/badge/AWS-EC2%20%7C%20ALB%20%7C%20ASG-orange?logo=amazonaws)
![Level](https://img.shields.io/badge/Level-Intermediate-blue)
![Region](https://img.shields.io/badge/Region-ap--south--1%20Mumbai-yellow)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)
![Free Tier](https://img.shields.io/badge/Cost-Free%20Tier%20Eligible-green)

Build a fault-tolerant, self-healing, elastic web infrastructure — an Application Load Balancer distributes traffic across multiple EC2 instances managed by an Auto Scaling Group that automatically adds or removes servers based on demand. This is the most common production architecture pattern for web applications on AWS.

---

## Architecture Overview

```
Internet
    │
    ▼
┌──────────────────────────────────────────────────────────────┐
│          Application Load Balancer (ALB)                     │
│          DNS: my-alb-xxxxx.ap-south-1.elb.amazonaws.com      │
│          Port 80 → Target Group → healthy instances          │
└───────────────────────┬──────────────────────────────────────┘
                        │ round-robin distribution
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
    ┌──────────┐  ┌──────────┐  ┌──────────┐
    │  EC2 #1  │  │  EC2 #2  │  │  EC2 #3  │
    │ t2.micro │  │ t2.micro │  │ t2.micro │
    │ AZ: 1a   │  │ AZ: 1b   │  │ AZ: 1a   │
    │ Apache   │  │ Apache   │  │ Apache   │
    └──────────┘  └──────────┘  └──────────┘
          │             │             │
          └─────────────┴─────────────┘
                        │
            Auto Scaling Group
            Min: 2 · Desired: 2 · Max: 4
            Launch Template: web-server-lt
            Health Check: ELB (ALB)
```

---

## AWS Services Used

| Service | Role |
|---|---|
| Application Load Balancer (ALB) | Distributes HTTP traffic across instances |
| Target Group | Pool of EC2 instances receiving traffic |
| Auto Scaling Group (ASG) | Manages EC2 fleet — scales in/out automatically |
| Launch Template | Blueprint for EC2 instances in the ASG |
| EC2 | Actual web server instances running Apache |
| CloudWatch | CPU metrics that drive scaling decisions |
| VPC | Network — public subnets across 2 AZs |

---

## Free Tier Status

| Resource | Free Tier | Region |
|---|---|---|
| EC2 t2.micro × 2 | 750 hrs/month (12 months) | ap-south-1 ✅ |
| ALB | 750 hours + 15 LCU free (12 months) | ap-south-1 ✅ |
| Auto Scaling | Always free | ap-south-1 ✅ |
| Launch Template | Always free | ap-south-1 ✅ |
| CloudWatch | 10 metrics free | ap-south-1 ✅ |

**Cost estimate: $0.00** — all within free tier.

---

## Project Structure

```
project-10-auto-scaling-alb/
├── README.md
├── docs/                    — architecture, guides, deep dives
│   ├── project-overview.md
│   ├── architecture.md
│   ├── auto-scaling-deep-dive.md
│   ├── load-balancer-deep-dive.md
│   ├── security.md
│   ├── troubleshooting.md
│   └── cleanup-guide.md
├── scripts/                 — PowerShell deployment scripts
│   ├── 01-preflight-check.ps1
│   ├── 02-setup-vpc-subnets.ps1
│   ├── 03-create-security-groups.ps1
│   ├── 04-create-launch-template.ps1
│   ├── 05-create-target-group.ps1
│   ├── 06-create-alb.ps1
│   ├── 07-create-auto-scaling-group.ps1
│   ├── 08-verify-and-test.ps1
│   ├── 09-test-auto-scaling.ps1
│   ├── 10-simulate-failure.ps1
│   └── 11-cleanup.ps1
├── architecture/            — SVG diagrams
│   ├── asg-alb-architecture.svg
│   ├── scaling-flow.svg
│   ├── security-groups.svg
│   └── health-check-flow.svg
└── images/                  — Console screenshots
    ├── 01-default-VPC.png
    ├── 02-subnets.png
    ├── 03-alb-Security-group.png
    ├── 04-asg-ec2-sg.png
    ├── 05-launch-template-created.png
    ├── 06-target-group-created.png
    ├── 07-alb-active.png
    ├── 08-alb-listener-rules.png
    ├── 09-asg-created.png
    ├── 10-asg-instances-running.png
    ├── 11-target-health-all-healthy.png
    ├── 12-web-app-instance-1.png
    ├── 13-web-app-instance-2.png
    ├── 14-stress-test-cpu.png
    ├── 15-cloudwatch-alarm-high.png
    ├── 16-scale-out-3-instances.png
    ├── 17-instance-failure-terminated.png
    ├── 18-self-healing-replacement.png
    ├── 19-scaling-activities-history.png
    └── raw-console-captures/
```

---

## Execution Order

| Script | Part | Task |
|---|---|---|
| `01-preflight-check.ps1` | Pre-flight | Verify region, identity, key pair |
| `02-setup-vpc-subnets.ps1` | 1 | Discover VPC and 2-AZ subnets |
| `03-create-security-groups.ps1` | 2 | ALB SG + EC2 SG |
| `04-create-launch-template.ps1` | 3 | EC2 blueprint with Apache user data |
| `05-create-target-group.ps1` | 4 | Health check target pool |
| `06-create-alb.ps1` | 5 | Internet-facing ALB + HTTP listener |
| `07-create-auto-scaling-group.ps1` | 6 | ASG + CPU scaling policy |
| `08-verify-and-test.ps1` | 7 | Health check + load balancing test |
| `09-test-auto-scaling.ps1` | 8 | Stress test + monitor scaling |
| `10-simulate-failure.ps1` | 9 | Terminate instance → watch self-heal |
| `11-cleanup.ps1` | 10 | Full teardown |

---

## Key Concepts Demonstrated

**Auto Scaling Group (ASG):** Manages a fleet of EC2 instances with min/max/desired capacity. Automatically launches instances when demand increases and terminates when demand decreases. Uses ELB health checks to detect and replace unhealthy instances.

**Application Load Balancer (ALB):** Layer 7 load balancer that distributes HTTP traffic across healthy instances using round-robin. Each browser refresh may show a different Instance ID and Availability Zone — proving traffic distribution.

**Target Tracking Scaling:** Works like a thermostat — set CPU target to 50%, and the ASG adjusts fleet size automatically. CPU above 50% → scale out. CPU below 35% → scale in.

**Self-Healing:** When an instance fails (terminated, crashed, or fails health checks), the ASG detects the failure and launches a replacement automatically. The ALB immediately stops sending traffic to the failed instance and routes to healthy ones. Zero downtime, zero manual intervention.

**Launch Template:** A versioned blueprint defining AMI, instance type, security groups, and user data. Change the template → ASG uses it for all new instances going forward.

**ALB vs NLB vs CLB:** ALB operates at Layer 7 (HTTP) with path/host routing. NLB operates at Layer 4 (TCP) for ultra-low latency. CLB is legacy. This project uses ALB for web application traffic.

---

*Part of the AWS Cloud Projects portfolio — hands-on infrastructure built and documented end to end.*
