# Load Balancer Deep Dive

<div style="background-color: #fdfdfe; border-left: 4px solid #ff9900; padding: 15px; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
  <i>The following granular documentation is designed to provide enterprise-level clarity for deploying and managing this AWS architecture. Pay close attention to the architectural specifications and step-by-step methodologies below.</i>
</div>

## What is an Application Load Balancer?

An ALB operates at Layer 7 (application layer) of the OSI
model. It inspects HTTP/HTTPS headers to make routing decisions
and distributes traffic across multiple targets.

---

## ALB Components

### Load Balancer

The entry point for all client traffic. Has a DNS name
and one or more listeners.

```text
my-alb-123456789.ap-south-1.elb.amazonaws.com
├── Scheme: internet-facing (public) or internal (private)
├── IP Type: IPv4 or dualstack (IPv4 + IPv6)
├── AZs: Requires minimum 2 Availability Zones
└── Security Group: Controls who can reach the ALB
```

### Listener

A listener checks for connection requests on a specific
protocol and port, then forwards them based on rules.

```text
Listener: HTTP:80
├── Protocol: HTTP
├── Port: 80
└── Default Action: Forward to target group
    (or: redirect to HTTPS, return fixed response)
```

### Target Group

A target group routes requests to one or more registered
targets (EC2 instances, IP addresses, or Lambda functions).

```text
Target Group: web-server-tg
├── Targets: EC2 instances (registered by ASG)
├── Protocol: HTTP
├── Port: 80
├── Health Check: HTTP GET / every 30 seconds
└── Routing Algorithm: Round Robin (default)
```

---

## ALB Listener Rules

Listeners can have multiple rules for advanced routing:

### Path-Based Routing
```text
/api/*     → API target group
/images/*  → Static content target group
/*         → Default target group
```

### Host-Based Routing
```text
api.example.com    → API target group
www.example.com    → Web target group
admin.example.com  → Admin target group
```

### Header-Based Routing
```text
X-Custom-Header: mobile  → Mobile target group
X-Custom-Header: desktop → Desktop target group
```

This project uses a single default rule: forward all
traffic to `web-server-tg`.

---

## Health Checks

The ALB performs health checks on targets to determine
if they can receive traffic.

```text
Configuration (this project):
├── Protocol: HTTP
├── Path: /
├── Port: traffic-port (80)
├── Interval: 30 seconds
├── Timeout: 5 seconds
├── Healthy threshold: 2 consecutive successes
├── Unhealthy threshold: 2 consecutive failures
└── Success codes: 200

Timeline:
  T+0s   → ALB sends HTTP GET / to instance
  T+0.1s → Instance responds 200 OK → count success
  T+30s  → ALB sends HTTP GET / again
  T+30.1s → Instance responds 200 OK → count success (2/2)
  Instance is now HEALTHY → receives traffic
```

### Health States

| State | Meaning |
|---|---|
| initial | Target registered, first health check pending |
| healthy | Passed health check threshold — receiving traffic |
| unhealthy | Failed health check threshold — no traffic |
| draining | Target deregistering — finishing in-flight requests |
| unused | Not registered in target group |

---

## Connection Draining (Deregistration Delay)

When a target is removed from the target group (e.g.,
scaling in), the ALB waits for in-flight requests to
complete before fully deregistering the target.

```text
Default: 300 seconds (5 minutes)
Range: 0 to 3600 seconds

Timeline:
  T+0s    → ASG decides to terminate instance
  T+0s    → Target enters "draining" state
  T+0-300s → ALB finishes in-flight requests
  T+300s  → Target fully deregistered
  T+300s  → Instance terminated
```

---

## Sticky Sessions

By default, the ALB distributes requests round-robin.
Sticky sessions (session affinity) route subsequent
requests from the same client to the same target.

```text
Duration-based: ALB generates a cookie (AWSALB)
Application-based: Your app generates a cookie

Use cases:
  ✅ Session state stored on the server
  ❌ Session state in a shared store (Redis, DynamoDB)
      → Use round-robin instead for better distribution
```

This project does NOT use sticky sessions — each request
can go to any instance, demonstrating pure load balancing.

---

## Cross-Zone Load Balancing

With cross-zone load balancing (enabled by default for ALB),
the load balancer distributes traffic evenly across all
registered instances in all enabled AZs.

```text
Without cross-zone:
  AZ-a (1 instance) gets 50% of traffic → overloaded
  AZ-b (3 instances) gets 50% of traffic → underutilized

With cross-zone (default):
  Each of 4 instances gets 25% of traffic → balanced
```

---

## ALB Security

### Security Group (this project)

```text
alb-sg:
  Inbound: TCP 80 from 0.0.0.0/0   (HTTP from internet)
  Inbound: TCP 443 from 0.0.0.0/0  (HTTPS — future)
  Outbound: All traffic (default)

asg-ec2-sg:
  Inbound: TCP 80 from alb-sg      (HTTP from ALB ONLY)
  Inbound: TCP 22 from MY_IP/32    (SSH for debugging)
  Outbound: All traffic (default)
```

**Critical design pattern:** EC2 instances only accept HTTP
traffic from the ALB security group. This prevents users
from bypassing the load balancer and hitting instances directly.

### HTTPS (future enhancement)

```text
1. Get an SSL certificate from AWS Certificate Manager (ACM)
2. Add HTTPS:443 listener to ALB
3. Configure HTTP:80 listener to redirect to HTTPS:443
4. ALB terminates SSL — EC2 instances still serve HTTP:80
```

---

## ALB Pricing

| Component | Cost |
|---|---|
| ALB hour | $0.0225 per hour |
| LCU (Load Balancer Capacity Unit) | $0.008 per LCU-hour |
| **Free tier** | 750 hours + 15 LCUs per month (12 months) |

An LCU measures:
- New connections per second
- Active connections per minute
- Processed bytes per hour
- Rule evaluations per second

For this project: well within free tier.

---

## Key CLI Commands

```powershell
# Describe ALB
aws elbv2 describe-load-balancers --names my-alb

# Describe listeners
aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN

# Describe target health
aws elbv2 describe-target-health --target-group-arn $TG_ARN

# Describe listener rules
aws elbv2 describe-rules --listener-arn $LISTENER_ARN

# Wait for ALB to be active
aws elbv2 wait load-balancer-available --load-balancer-arns $ALB_ARN
```

---

