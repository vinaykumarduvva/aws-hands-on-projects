# Project 7 — CloudWatch Alarms, SNS Notifications & Dashboards

![AWS](https://img.shields.io/badge/AWS-CloudWatch%20%2B%20SNS-orange?logo=amazonaws)
![Level](https://img.shields.io/badge/Level-Beginner%20→%20Intermediate-blue)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)
![Free Tier](https://img.shields.io/badge/Cost-Free%20Tier%20Eligible-green)

Build a complete AWS monitoring and alerting system — CloudWatch alarms for EC2 and RDS metrics, SNS email notifications, a custom dashboard, and log monitoring with metric filters. This is the observability foundation every cloud engineer needs.

---

## Architecture Overview

```
EC2 Instance          RDS MySQL         Billing
├── CPUUtilization    ├── CPUUtilization ├── EstimatedCharges
├── NetworkIn/Out     ├── DBConnections  └── → SNS → Email
├── StatusCheckFailed └── FreeStorage
└── DiskReadOps             │
         │                  │
         ▼                  ▼
┌──────────────────────────────────────┐
│          CloudWatch Alarms           │
│  EC2-CPU-High   RDS-CPU-High         │
│  EC2-StatusFail RDS-Storage-Low      │
│  Billing-Alert  App-Errors-High      │
└──────────────────┬───────────────────┘
                   │ ALARM state
                   ▼
┌──────────────────────────────────────┐
│     SNS Topic: monitoring-alerts     │
│     Subscriber: your@email.com       │
└──────────────────┬───────────────────┘
                   ▼
         📧 Email Notification

┌──────────────────────────────────────┐
│   Dashboard: AWS-Bootcamp-Dashboard  │
│  EC2 CPU · Network · RDS · Billing   │
└──────────────────────────────────────┘
```

---

## AWS Services Used

| Service | Role |
|---|---|
| CloudWatch | Metrics, alarms, dashboards, logs |
| SNS | Routes alarm notifications to email |
| EC2 | Source of compute metrics |
| RDS | Source of database metrics |
| CloudWatch Logs | Log storage and metric filters |
| IAM | CloudWatch agent role for EC2 |

---

## Alarms Built

| Alarm | Metric | Threshold | Service |
|---|---|---|---|
| EC2-CPU-High | CPUUtilization | > 70% | EC2 |
| EC2-StatusCheck-Failed | StatusCheckFailed | ≥ 1 | EC2 |
| EC2-NetworkIn-High | NetworkIn | > 5 MB/5min | EC2 |
| RDS-CPU-High | CPUUtilization | > 80% | RDS |
| RDS-Storage-Low | FreeStorageSpace | < 2 GB | RDS |
| RDS-Connections-High | DatabaseConnections | > 50 | RDS |
| Billing-Alert-5USD | EstimatedCharges | > $5 | Billing |
| App-Errors-High | ApplicationErrors | > 5/5min | Custom |

---

## Free Tier Status

| Resource | Free Tier | Usage |
|---|---|---|
| CloudWatch metrics | 10 custom metrics free | ~1 custom |
| CloudWatch alarms | 10 free | 8 created |
| CloudWatch dashboards | 3 free | 1 created |
| CloudWatch Logs | 5 GB free | Minimal |
| SNS emails | 1,000/month free | <10 |

**Cost estimate: $0.00** — entirely within free tier.

---

## Project Structure

```
project-07-cloudwatch-monitoring/
├── README.md
├── LICENSE
├── .gitignore
├── docs/
│   ├── project-overview.md
│   ├── architecture.md
│   ├── monitoring-strategy.md
│   ├── cloudwatch-alarms.md
│   ├── dashboards.md
│   ├── logs-and-metric-filters.md
│   ├── troubleshooting.md
│   └── cleanup-guide.md
├── scripts/
│   ├── 01-sns-setup.ps1
│   ├── 02-launch-monitoring-ec2.ps1
│   ├── 03-create-ec2-alarms.ps1
│   ├── 04-create-rds-alarms.ps1
│   ├── 05-create-billing-alarm.ps1
│   ├── 06-generate-cpu-load.sh
│   ├── 07-create-dashboard.ps1
│   ├── 08-create-log-group.ps1
│   ├── 09-create-metric-filter.ps1
│   ├── 10-test-log-events.ps1
│   ├── 11-verify-alarms.ps1
│   └── 12-cleanup.ps1
├── architecture/
│   ├── monitoring-architecture.svg
│   ├── alarm-flow.svg
│   ├── dashboard-layout.svg
│   └── log-monitoring-flow.svg
└── images/
    └── (25 console screenshots)
```

---

## Execution Order

| Script | Part | Task |
|---|---|---|
| `01-sns-setup.ps1` | 1 | Create SNS topic + email subscription |
| `02-launch-monitoring-ec2.ps1` | 2 | Launch EC2 for metrics |
| `03-create-ec2-alarms.ps1` | 3 | EC2 CPU, status, network alarms |
| `04-create-rds-alarms.ps1` | 4 | RDS CPU, storage, connections alarms |
| `05-create-billing-alarm.ps1` | 5 | Billing threshold alarm |
| `06-generate-cpu-load.sh` | 6 | SSH into EC2 and stress CPU |
| `07-create-dashboard.ps1` | 7 | Build CloudWatch dashboard |
| `08-create-log-group.ps1` | 8 | Create log group with retention |
| `09-create-metric-filter.ps1` | 9 | ERROR log metric filter + alarm |
| `10-test-log-events.ps1` | 8 | Push test log events |
| `11-verify-alarms.ps1` | 9 | List all alarms and states |
| `12-cleanup.ps1` | 10 | Full teardown |

---

## Key Concepts Demonstrated

**Alarm states**: Every CloudWatch alarm cycles through `INSUFFICIENT_DATA → OK → ALARM`. Understanding when and why each state occurs is essential for production operations.

**Evaluation periods**: The EC2-CPU-High alarm requires 2 consecutive 5-minute periods above 70% before triggering. This prevents transient spikes from generating false alerts — a core production alarm design principle.

**Metric filters**: CloudWatch Logs can scan log lines for patterns and increment a custom metric. This bridges application-level events (ERROR logs) with the same alarm infrastructure used for infrastructure metrics.

**SNS decoupling**: Alarms do not send emails directly. They publish to an SNS topic. This means one alarm can notify email, SMS, PagerDuty, Lambda, and SQS simultaneously — by adding subscribers.

---

## Resume Bullets

- Built a complete AWS observability stack with 8 CloudWatch alarms across EC2, RDS, and Billing namespaces, routing alerts through an SNS topic to email with confirmed subscriptions
- Triggered and verified the EC2-CPU-High alarm end-to-end using a stress test, observing the state transition from OK to ALARM within two 5-minute evaluation periods
- Created a CloudWatch Logs metric filter to count application ERROR events and feed a custom namespace alarm, demonstrating log-to-alert pipeline construction
- Built a custom CloudWatch dashboard combining EC2 CPU, network, RDS connections, storage, and billing metrics in a single operational view

---

*Part of the AWS Cloud Projects portfolio — hands-on infrastructure built and documented end to end.*