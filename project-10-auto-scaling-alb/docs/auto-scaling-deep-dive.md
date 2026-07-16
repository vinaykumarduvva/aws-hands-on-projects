# Auto Scaling Deep Dive

<div style="background-color: #fdfdfe; border-left: 4px solid #ff9900; padding: 15px; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
  <i>The following granular documentation is designed to provide enterprise-level clarity for deploying and managing this AWS architecture. Pay close attention to the architectural specifications and step-by-step methodologies below.</i>
</div>

## What is Auto Scaling?

Auto Scaling automatically adjusts the number of EC2 instances
in response to demand. It consists of three components:

1. **Launch Template** — defines HOW to launch instances
2. **Auto Scaling Group** — defines WHERE and HOW MANY
3. **Scaling Policy** — defines WHEN to scale

---

## Launch Template vs Launch Configuration

| Feature | Launch Template | Launch Configuration |
|---|---|---|
| Versioning | ✅ Multiple versions | ❌ Immutable |
| Inheritance | ✅ Source template | ❌ No |
| Mixed instances | ✅ Yes | ❌ No |
| Spot support | ✅ Yes | Limited |
| Recommended | ✅ Yes | ❌ Deprecated |

AWS recommends Launch Templates for all new projects.
Launch Configurations are legacy and cannot be edited.

---

## ASG Capacity Settings

```text
┌──────────────────────────────────────────────────┐
│                                                  │
│  Min ──────── Desired ────────────── Max          │
│   2              2                    4           │
│                                                  │
│  Min: Floor. ASG never goes below this.          │
│  Desired: Target count. ASG maintains this.      │
│  Max: Ceiling. ASG never exceeds this.           │
│                                                  │
│  If CPU > 50% → Desired increases (up to Max)    │
│  If CPU < 35% → Desired decreases (down to Min)  │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## Scaling Policy Types

### 1. Target Tracking (used in this project)

Works like a thermostat. Set a target metric value, and
the ASG adjusts capacity to maintain it.

```text
Metric: ASGAverageCPUUtilization
Target: 50%

CPU at 80% → ASG adds instances to bring average down
CPU at 20% → ASG removes instances to bring average up
CPU at 50% → ASG does nothing (at target)
```

### 2. Step Scaling

Define discrete steps for different alarm thresholds.

```text
CPU 50-60% → add 1 instance
CPU 60-80% → add 2 instances
CPU 80%+   → add 3 instances
```

### 3. Simple Scaling

Single alarm, single action. Has a mandatory cooldown period.

```text
CPU > 70% → add 1 instance (then wait 300s cooldown)
```

### 4. Scheduled Scaling

Scale based on time-of-day patterns.

```text
8 AM  → set desired = 4 (business hours)
8 PM  → set desired = 2 (off hours)
```

### Recommendation

Use **Target Tracking** for most workloads. It is the simplest
and handles both scale-out and scale-in automatically.

---

## Health Check Types

### EC2 Health Check (default)

- Checks if the EC2 instance is running
- Only fails if instance is stopped/terminated
- Does NOT check if your application is working

### ELB Health Check (used in this project)

- ALB sends HTTP GET to `/` every 30 seconds
- If the application returns HTTP 200, instance is healthy
- If 2 consecutive checks fail → instance marked unhealthy
- ASG terminates unhealthy instance and launches replacement

```text
ALB → HTTP GET / → EC2:80
  Response 200 → healthy
  Response 5xx or timeout → count failure
  2 failures → unhealthy → ASG replaces
```

**Always use ELB health checks** when an ASG is attached to
a load balancer. EC2 health checks alone will miss application
failures (e.g., Apache crashed but instance is still running).

---

## Health Check Grace Period

The grace period (120 seconds in this project) is the time
after an instance launches during which health checks are
ignored. This prevents premature termination while user
data scripts are still running.

```text
0s    → Instance launches
0-30s → User data: yum update
30-60s → User data: install Apache, stress
60-90s → User data: start Apache, create HTML
120s  → Grace period ends → ELB health checks begin
150s  → First health check passes → instance is healthy
```

If the grace period is too short, the ASG may terminate
instances before they finish booting, creating an infinite
launch-terminate loop.

---

## Instance Warmup

The warmup period (120 seconds) tells the scaling policy
to exclude recently launched instances from the average
CPU calculation. This prevents rapid over-scaling.

```text
Without warmup:
  CPU high → launch instance → new instance CPU is 0% →
  average drops → scaling thinks problem is solved →
  stops scaling too early

With warmup (120s):
  CPU high → launch instance → new instance excluded
  from average for 120s → scaling continues correctly
```

---

## Cooldown Period

After a scaling action, the ASG waits before responding
to additional alarms. This prevents thrashing.

```text
Target Tracking manages cooldowns automatically.
Step/Simple scaling requires manual cooldown configuration.

Default cooldown: 300 seconds (5 minutes)
```

---

## Termination Policy

When scaling in, the ASG must choose which instance to
terminate. The default policy:

1. Select the AZ with the most instances (balance AZs)
2. Select the instance with the oldest launch configuration
3. Select the instance closest to the next billing hour

Other options: OldestInstance, NewestInstance, OldestLaunchConfiguration,
ClosestToNextInstanceHour, Default.

---

## Key CLI Commands

```powershell
# View ASG details
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names web-server-asg

# Manually scale
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name web-server-asg \
  --desired-capacity 3

# Update capacity limits
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name web-server-asg \
  --min-size 1 --max-size 6

# View scaling activities (history)
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name web-server-asg

# Terminate instance (ASG replaces it)
aws autoscaling terminate-instance-in-auto-scaling-group \
  --instance-id i-xxxxx \
  --should-decrement-desired-capacity false
```

---

