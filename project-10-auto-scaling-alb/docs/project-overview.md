# Project 10 — Auto Scaling Group + ALB: Project Overview

[![AWS](https://img.shields.io/badge/AWS-EC2%20%7C%20ALB%20%7C%20ASG-orange?style=flat&logo=amazon-aws)](https://aws.amazon.com/ec2/autoscaling/)
[![Level](https://img.shields.io/badge/Level-Intermediate-yellow?style=flat)](../README.md)
[![Region](https://img.shields.io/badge/Region-ap--south--1-blue?style=flat)](https://aws.amazon.com/about-aws/global-infrastructure/)
[![Free Tier](https://img.shields.io/badge/Cost-Free%20Tier-brightgreen?style=flat)](https://aws.amazon.com/free/)

---

## What Was Built

A fault-tolerant, self-healing, elastic web infrastructure where
an Application Load Balancer distributes HTTP traffic across
multiple EC2 instances managed by an Auto Scaling Group that
automatically adds or removes servers based on CPU demand.

This is the most common production architecture pattern for
web applications on AWS.

---

## Why This Project Matters

Every production web application needs to handle variable
traffic loads without human intervention. This project
demonstrates the core patterns:

- **Fault Tolerance:** If an instance fails, ASG replaces it automatically
- **Elasticity:** Instances scale out on high CPU, scale in when idle
- **High Availability:** Instances spread across multiple Availability Zones
- **Load Distribution:** ALB distributes requests using round-robin
- **Health Monitoring:** ALB health checks detect unhealthy instances

---

## AWS Services Used

| Service | Category | Role in This Project |
|---|---|---|
| Application Load Balancer | Networking | Distributes HTTP traffic across instances |
| Target Group | Networking | Pool of EC2 instances receiving traffic |
| Auto Scaling Group | Compute | Manages EC2 fleet — scales in/out automatically |
| Launch Template | Compute | Blueprint for EC2 instances in the ASG |
| EC2 | Compute | Actual web server instances running Apache |
| CloudWatch | Monitoring | CPU metrics that drive scaling decisions |
| VPC | Networking | Public subnets across 2 AZs |

---

## Region

**ap-south-1 (Mumbai)** — all resources deployed here.

ALB requires subnets in at least 2 Availability Zones:
- ap-south-1a
- ap-south-1b

---

## Free Tier Breakdown

| Service | Free Allowance | Usage | Cost |
|---|---|---|---|
| EC2 t2.micro × 2 | 750 hrs/month (12 mo) | ~2 hrs testing | $0.00 |
| ALB | 750 hrs + 15 LCU (12 mo) | ~2 hrs | $0.00 |
| Auto Scaling | Always free | All operations | $0.00 |
| Launch Template | Always free | 1 template | $0.00 |
| CloudWatch | 10 metrics free | CPU metrics | $0.00 |
| **Total** | | | **$0.00** |

---

## Project Outcomes

After completing this project you can:

- Create a Launch Template as a reusable EC2 blueprint
- Deploy an Application Load Balancer with Target Groups
- Configure an Auto Scaling Group with min/max/desired capacity
- Set up target tracking scaling policies (CPU-based)
- Configure ELB health checks for automatic instance replacement
- Test auto scaling by generating CPU load
- Simulate instance failure and observe self-healing
- Understand the difference between ALB, NLB, and CLB
- Execute full teardown in proper deletion order

---

## Architecture Summary

```
Internet → ALB (HTTP:80) → Target Group → EC2 Instances (2-4)
                                              ↕
                                    Auto Scaling Group
                                    Min: 2 | Desired: 2 | Max: 4
                                    Scaling: CPU > 50% → scale out
```

The ALB sits in front of the ASG instances, performing health
checks every 30 seconds. If an instance fails, the ALB stops
sending traffic to it, and the ASG launches a replacement.

---

## Key Concepts Demonstrated

### Auto Scaling Group (ASG)
Manages a fleet of EC2 instances with defined minimum, maximum,
and desired capacity. The ASG automatically launches new instances
when demand increases and terminates instances when demand decreases.

### Application Load Balancer (ALB)
Layer 7 load balancer that distributes HTTP/HTTPS traffic across
instances in the Target Group. Supports path-based routing,
host-based routing, and WebSocket connections.

### Target Tracking Scaling
A scaling policy that works like a thermostat — you set a target
CPU utilization (50%), and the ASG adjusts the fleet size to
maintain that target automatically.

### Self-Healing
When an instance fails (terminates, crashes, or fails health
checks), the ASG detects the failure and launches a replacement
instance automatically — zero manual intervention.

### Launch Template
A versioned blueprint that defines how every EC2 instance in
the ASG should be configured: AMI, instance type, security
groups, user data, tags.

---

## Real-World Context

This architecture is the foundation for most web applications
running on AWS:

**At a startup:** 2-instance ASG behind an ALB, scaling to 4
during peak hours. Cost-effective and resilient.

**At an enterprise:** Multi-AZ ASG with dozens of instances,
multiple Target Groups for microservices, HTTPS termination
at the ALB, WAF integration, and CloudWatch dashboards.

**Blue/Green deployments:** Update the Launch Template with
a new AMI, trigger an instance refresh, and the ASG gradually
replaces old instances with new ones — zero downtime.

---
