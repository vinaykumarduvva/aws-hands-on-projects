# Monitoring Strategy — CloudWatch Project

## Why These Metrics Were Chosen

Every alarm in this project reflects a real production concern. This document explains the reasoning behind each threshold and design decision.

---

## EC2 Monitoring

### CPU Utilization — 70% threshold, 2 evaluation periods

**Why 70%?** CPU at 70% signals the instance is under load but not yet saturated. At 100%, the OS scheduler is starved and response times degrade non-linearly. Alerting at 70% gives time to investigate before users notice degradation.

**Why 2 evaluation periods (10 minutes)?** CPU spikes are normal — a cron job, a health check, a package install. Requiring two consecutive periods filters out transient spikes and ensures the alert represents sustained load. This is the most common cause of false-positive alerts in production: a single-period threshold with no sustained requirement.

**Why ok-action?** When CPU returns to normal, an "OK" notification confirms the issue resolved. Without this, an on-call engineer has no automated confirmation of recovery.

### Status Check Failed — threshold ≥ 1, 2 evaluation periods

**What it detects**: AWS runs two status checks per minute:
- Instance status check: OS-level failures (kernel panic, network configuration, out of memory)
- System status check: Hardware failures on the underlying host

**Why maximum statistic?** Unlike CPU which averages gracefully, a status check is binary — it either passed or failed. Maximum ensures any failure in the period is captured.

**Practical significance**: This alarm can trigger EC2 instance recovery actions (auto-restart) in production. Not configured here, but the alarm is the prerequisite.

### NetworkIn High — 5MB per 5-minute period

**What it detects**: Unusual inbound traffic. Could indicate:
- A DDoS or port scan
- An unexpected data transfer job
- A misconfigured client hammering the endpoint

**Why 5MB?** A t2.micro serving a small web application would typically see kilobytes of inbound traffic per 5-minute window. 5MB (5,000,000 bytes) represents a significant anomaly for a test instance. Scale this threshold to match actual baseline traffic in production.

---

## RDS Monitoring

### CPU Utilization — 80% threshold

**Why 80% instead of 70% for RDS?** Database engines use CPU differently from application servers. MySQL buffers data, sorts result sets, and processes queries in ways that can legitimately push CPU higher than an app server. The higher threshold reduces noise while still catching problematic query workloads.

### Free Storage Space — 2GB threshold

**Why alert at 2GB?** RDS storage is provisioned at creation time (20GB in this project). Running out of storage causes write failures immediately — no graceful degradation. 2GB (roughly 10% of 20GB) provides a meaningful warning window to investigate before the database becomes read-only.

**Why no evaluation period buffer?** Storage consumption is monotonic (it doesn't spike and recover). A single data point below 2GB is actionable immediately.

### Database Connections — 50 threshold

**Context**: db.t3.micro supports a maximum of 66 concurrent connections. At 50, the connection pool is 76% utilised. Beyond the maximum, new connections are refused with "Too many connections" — one of the most common application errors in production.

**What causes connection exhaustion?** Connection pool misconfiguration, connection leaks in application code, or a sudden traffic spike. Alerting at 50 provides time to investigate before hard failures begin.

---

## Billing Monitoring

### Estimated Charges — $5 threshold

**Why $5?** In the context of these projects, $5 in a month means something unexpected is running. The Free Tier covers most of what this portfolio uses. A $5 alert catches:
- An RDS instance left running after a project
- A NAT Gateway accidentally left provisioned
- An Elastic IP address not associated with a running instance

**Important constraint**: Billing metrics are only available in `us-east-1`. This is an AWS limitation, not a region preference. The billing alarm must be created in us-east-1 regardless of where your other resources are.

**Update frequency**: AWS updates billing metrics once per day. Do not expect real-time billing visibility from this alarm — use it for daily anomaly detection, not second-by-second cost tracking.

---

## Log-Based Monitoring

### Application Error Count — 5 errors per 5-minute period

**Why log-based monitoring?** Infrastructure metrics (CPU, memory, network) tell you the system is under stress but not why. Log-based metrics add application context — "the error rate spiked because of database connection failures" rather than "CPU is high."

**Why 5 errors?** A handful of errors in a 5-minute window could be normal (failed logins, 404s, validation errors). More than 5 in 5 minutes suggests a systematic problem: a broken dependency, a deployment bug, or a configuration issue.

**Pattern matching**: The metric filter uses `ERROR` as the pattern. This is case-sensitive. If your application writes `Error` or `error`, the filter will not match. Align the filter pattern with your actual log format.

---

## Alarm Design Checklist

When creating production alarms, apply these checks:

| Check | Question |
|---|---|
| Actionable? | Can the on-call engineer do something about this? |
| Specific? | Does the alarm identify what failed, not just that something failed? |
| Threshold calibrated? | Based on actual baseline, not a guess? |
| Evaluation periods set? | Does it require sustained breach or just one data point? |
| Missing data handled? | What happens when the metric stops publishing? |
| Recovery notification? | Does ok-action notify when the issue clears? |
| Tested? | Has the alarm been verified to actually fire? |

All alarms in this project pass this checklist. The CPU alarm was verified live (Part 6 stress test).