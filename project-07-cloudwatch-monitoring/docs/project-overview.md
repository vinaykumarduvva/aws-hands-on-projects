# Project Overview — CloudWatch Alarms, SNS & Dashboards

## What This Project Builds

This project builds the observability layer that sits on top of your AWS infrastructure. Observability means you know what your systems are doing — not just whether they are up, but how they are performing, what errors are occurring, and whether costs are within expectations.

The stack built here has three components:

- **Alerting**: CloudWatch alarms watch metrics and publish to SNS when thresholds breach. SNS delivers email notifications within seconds.
- **Dashboards**: A custom CloudWatch dashboard consolidates EC2, RDS, and billing metrics into one operational view.
- **Log monitoring**: CloudWatch Logs ingest application logs; metric filters convert ERROR patterns into alarm-triggerable metrics.

---

## Why This Matters in Production

Every production system needs this layer. Without it:
- You find out about outages when users report them
- You discover cost overruns at the end of the month
- You investigate issues with no historical data

With it:
- Alarms notify you before users notice (CPU trending toward 100%)
- Billing alarms catch runaway resources within 24 hours
- Log metric filters detect application errors in near real time

---

## CloudWatch Concepts

### Metrics
A metric is a time-series of data points. AWS services automatically publish metrics — EC2 publishes `CPUUtilization` every minute to the `AWS/EC2` namespace. You cannot turn this off; it is always there.

### Namespaces
Namespaces group metrics by service. Key namespaces in this project:

| Namespace | What it contains |
|---|---|
| `AWS/EC2` | CPUUtilization, NetworkIn, StatusCheckFailed, DiskReadOps |
| `AWS/RDS` | CPUUtilization, DatabaseConnections, FreeStorageSpace |
| `AWS/Billing` | EstimatedCharges (us-east-1 only) |
| `CustomMetrics` | ApplicationErrors (created by our metric filter) |

### Dimensions
Dimensions are key-value pairs that identify a specific resource within a namespace. `InstanceId=i-xxxxxxxxx` distinguishes one EC2 from another. `DBInstanceIdentifier=myapp-database` identifies your RDS instance.

### Alarms
An alarm watches one metric and transitions between three states:

| State | Meaning |
|---|---|
| `OK` | Metric is within the defined threshold |
| `ALARM` | Metric has breached the threshold for the required evaluation periods |
| `INSUFFICIENT_DATA` | Not enough data points yet to evaluate |

### Evaluation Periods
An alarm only triggers after the threshold is breached for N consecutive periods. The EC2-CPU-High alarm uses 2 periods of 5 minutes — meaning CPU must stay above 70% for 10 minutes before the alarm fires. This prevents false positives from transient spikes.

### Statistics
Each alarm evaluates a statistic over each period:
- `Average` — typical use case for CPU, memory
- `Maximum` — use for status checks (any failure = alarm)
- `Sum` — use for counters (total errors in period)
- `Minimum` — use for storage (alert when storage drops below threshold)

---

## SNS Concepts

SNS (Simple Notification Service) is a pub/sub messaging service. CloudWatch alarms do not send emails directly — they publish a message to an SNS topic. The topic then fans out to all subscribers.

```
CloudWatch Alarm → SNS Topic → Email subscriber
                             → SMS subscriber (optional)
                             → Lambda function (optional)
                             → SQS queue (optional)
```

This decoupling means you can change how notifications are delivered without touching the alarms. In production, most teams route SNS → PagerDuty or SNS → OpsGenie for on-call management.

**Subscription confirmation**: Email subscriptions require the recipient to click a confirmation link. Alarms cannot deliver to unconfirmed subscriptions. This is spam prevention — AWS will not send emails to addresses that haven't opted in.

---

## What Gets Monitored

### EC2 (3 alarms)
- **CPU > 70%**: Catches runaway processes, performance degradation
- **StatusCheckFailed ≥ 1**: Detects hardware failure or OS hang
- **NetworkIn > 5MB/5min**: Detects unusual traffic (potential attack or data transfer spike)

### RDS (3 alarms)
- **CPU > 80%**: Database under heavy query load
- **FreeStorageSpace < 2GB**: Storage filling up — needs attention before it causes write failures
- **DatabaseConnections > 50**: Connection pool exhaustion approaching (db.t3.micro max: 66)

### Billing (1 alarm)
- **EstimatedCharges > $5**: Catches accidental resource creation or runaway services

### Custom / Logs (1 alarm)
- **ApplicationErrors > 5/5min**: Application error rate spike detected via log metric filter

---

## Alarm Design Principles Applied

**Low false positive rate**: Two evaluation periods for CPU alarms means transient spikes don't page. One period for storage means immediate notification — storage doesn't fluctuate.

**Both ok-actions and alarm-actions**: The EC2 and RDS CPU alarms send email on both ALARM and OK transitions. This means you get an "all clear" notification when the issue resolves, not just when it starts.

**treat-missing-data = notBreaching**: If data stops flowing (instance stopped), alarms don't fire. This prevents alert storms when you intentionally stop resources.