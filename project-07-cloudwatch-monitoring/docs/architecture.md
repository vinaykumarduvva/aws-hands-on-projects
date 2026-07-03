# Architecture — CloudWatch Monitoring Stack

## Full System View

```
┌─────────────────────────────────────────────────────────────────┐
│                      AWS Account                                │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   Metric Sources                         │   │
│  │                                                          │   │
│  │  ┌────────────────┐   ┌────────────────┐   ┌─────────┐  │   │
│  │  │   EC2 Instance │   │   RDS MySQL    │   │Billing  │  │   │
│  │  │  monitoring-   │   │ myapp-database │   │ Service │  │   │
│  │  │  test          │   │                │   │         │  │   │
│  │  │                │   │                │   │         │  │   │
│  │  │ CPUUtilization │   │ CPUUtilization │   │Estimated│  │   │
│  │  │ NetworkIn/Out  │   │ DBConnections  │   │Charges  │  │   │
│  │  │ StatusCheck    │   │ FreeStorage    │   │         │  │   │
│  │  └───────┬────────┘   └───────┬────────┘   └────┬────┘  │   │
│  └──────────│────────────────────│────────────────-│───────┘   │
│             │    (auto-published) │                 │           │
│             ▼                    ▼                 ▼           │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              CloudWatch Metrics Store                    │   │
│  │  namespace: AWS/EC2  AWS/RDS  AWS/Billing  CustomMetrics │   │
│  └──────────────────────────┬───────────────────────────────┘   │
│                             │                                   │
│          ┌──────────────────┼──────────────────────┐           │
│          │                  │                      │           │
│          ▼                  ▼                      ▼           │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────────┐   │
│  │CloudWatch     │  │CloudWatch     │  │CloudWatch Logs   │   │
│  │   Alarms (8)  │  │   Dashboard   │  │                  │   │
│  │               │  │               │  │ /aws/ec2/        │   │
│  │ EC2-CPU-High  │  │ AWS-Bootcamp- │  │ monitoring-test  │   │
│  │ EC2-Status-   │  │ Dashboard     │  │                  │   │
│  │ EC2-NetworkIn │  │               │  │ Metric Filter:   │   │
│  │ RDS-CPU-High  │  │ EC2 CPU graph │  │ "ERROR" → count  │   │
│  │ RDS-Storage   │  │ EC2 Network   │  │       │          │   │
│  │ RDS-Connx     │  │ RDS CPU       │  │       ▼          │   │
│  │ Billing-$5    │  │ RDS Connx     │  │ CustomMetrics/   │   │
│  │ App-Errors    │  │ Billing $     │  │ ApplicationErrors│   │
│  └───────┬───────┘  └───────────────┘  └──────────────────┘   │
│          │                                                      │
│          │ state = ALARM                                        │
│          ▼                                                      │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │            SNS Topic: monitoring-alerts                   │  │
│  │            ARN: arn:aws:sns:us-east-1:XXXX:monitoring-..  │  │
│  └───────────────────────────────────────────────────────────┘  │
│          │                                                      │
└──────────│──────────────────────────────────────────────────────┘
           │
           ▼ (outside AWS)
  📧 vinay@example.com
     (confirmed subscription)
```

---

## Alarm State Machine

Every alarm cycles through these states:

```
                 ┌──────────────────────────────────────────┐
                 │                                          │
   Launch ──→ INSUFFICIENT_DATA                            │
                 │                                          │
                 │  first data points arrive                │
                 ▼                                          │
               ┌───┐                                        │
               │ OK│ ←─────────────────────────────────────┘
               └─┬─┘       metric returns below threshold
                 │
                 │  N consecutive periods above threshold
                 ▼
             ┌───────┐
             │ ALARM │ ──→ publishes to SNS ──→ email sent
             └───────┘
```

Key rules:
- Alarm does NOT fire on the first breach — it waits for N consecutive evaluation periods
- OK transition also triggers SNS if `ok-actions` is set (recovery notification)
- `INSUFFICIENT_DATA` occurs when an instance is stopped or the metric stops publishing

---

## SNS Fan-Out Pattern

```
CloudWatch Alarm (EC2-CPU-High)
          │
          │ publishes JSON message
          ▼
SNS Topic: monitoring-alerts
          │
    ┌─────┼──────┬─────────────────┐
    │     │      │                 │
    ▼     ▼      ▼                 ▼
 Email  Email  Lambda           SQS Queue
(you)  (team) (auto-remediate) (audit log)
              [future]         [future]
```

In this project only the email subscriber is active. The architecture supports adding more without modifying alarms.

---

## Log → Metric → Alarm Pipeline

```
Application on EC2
  │
  │ writes logs to /var/log/app.log
  ▼
CloudWatch Logs Agent (future: unified agent)
  │
  │ ingests log lines to:
  ▼
Log Group: /aws/ec2/monitoring-test
  │
  │ Metric Filter: pattern = "ERROR"
  │ on match: increment CustomMetrics/ApplicationErrors by 1
  ▼
CloudWatch Metric: CustomMetrics/ApplicationErrors
  │
  │ Alarm: App-Errors-High
  │ threshold: Sum > 5 in one 5-minute period
  ▼
SNS Topic → Email notification
```

This pipeline converts unstructured log text into structured operational signals that feed the same alarm infrastructure as hardware metrics.

---

## Resource Inventory

| Resource | Name/ID | Notes |
|---|---|---|
| SNS Topic | monitoring-alerts | Standard type |
| SNS Subscription | your-email | Must be confirmed |
| EC2 Instance | monitoring-test | t2.micro, default VPC |
| Security Group | monitoring-test-sg | SSH from your IP |
| CloudWatch Dashboard | AWS-Bootcamp-Dashboard | 5–6 widgets |
| Log Group | /aws/ec2/monitoring-test | 7-day retention |
| Log Stream | app-server-1 | Test events |
| Metric Filter | ErrorCount | Pattern: "ERROR" |
| **Alarms** | | |
| EC2-CPU-High | CPUUtilization > 70% | 2 × 5 min |
| EC2-StatusCheck-Failed | StatusCheckFailed ≥ 1 | 2 × 1 min |
| EC2-NetworkIn-High | NetworkIn > 5MB/5min | 1 × 5 min |
| RDS-CPU-High | CPUUtilization > 80% | 2 × 5 min |
| RDS-Storage-Low | FreeStorageSpace < 2GB | 1 × 5 min |
| RDS-Connections-High | DatabaseConnections > 50 | 1 × 5 min |
| Billing-Alert-5USD | EstimatedCharges > $5 | 1 × 1 day |
| App-Errors-High | ApplicationErrors > 5 | 1 × 5 min |