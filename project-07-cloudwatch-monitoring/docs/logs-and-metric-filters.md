# CloudWatch Logs and Metric Filters

## Overview

CloudWatch Logs enables three things:
1. Centralised log storage for EC2, Lambda, RDS, and other services
2. Log Insights — SQL-like queries over log data
3. Metric filters — convert log patterns into CloudWatch metrics that feed alarms

This project demonstrates metric filter creation and tests it with simulated log events.

---

## Log Group Configuration

```
Name:           /aws/ec2/monitoring-test
Retention:      7 days
Log Streams:    app-server-1
```

**Retention policy**: Without a retention policy, CloudWatch Logs stores data indefinitely — accumulating cost. 7 days is appropriate for a test environment. Production retention varies: 30 days for operational logs, 1 year for audit logs, indefinitely for compliance.

**Naming convention**: `/aws/ec2/<instance-name>` follows AWS conventions. Other common patterns:
- `/aws/lambda/<function-name>` — Lambda logs (auto-created)
- `/aws/rds/instance/<db-id>/error` — RDS error logs
- `/app/<service-name>/production` — application logs

---

## Metric Filter — ErrorCount

### Configuration

```
Log Group:    /aws/ec2/monitoring-test
Filter Name:  ErrorCount
Pattern:      ERROR
Metric Transformations:
  Metric Name:      ApplicationErrors
  Metric Namespace: CustomMetrics
  Metric Value:     1
  Default Value:    0
```

### How It Works

Every time CloudWatch Logs ingests a new log event in the `/aws/ec2/monitoring-test` group, it evaluates the filter pattern against the log line. If the line contains the string `ERROR` (case-sensitive), the metric value increments by 1.

The `defaultValue: 0` ensures the metric publishes a 0 data point even during periods with no matching lines. Without this, the metric has gaps and alarms can enter `INSUFFICIENT_DATA` state.

### Pattern Syntax

CloudWatch Logs filter patterns support several forms:

| Pattern | Matches |
|---|---|
| `ERROR` | Any line containing the literal string "ERROR" |
| `[level, msg]` | Space-delimited fields — captures structured logs |
| `{ $.level = "ERROR" }` | JSON log format — matches `{"level":"ERROR",...}` |
| `?ERROR ?WARN` | Lines containing ERROR or WARN |

This project uses the simplest form (`ERROR`) for clarity. Production metric filters typically use JSON patterns for structured log formats.

---

## Test Log Events

The test pushes 8 log events — 3 INFO lines and 5 ERROR lines:

```
INFO: Application started successfully
INFO: User login successful
ERROR: Database connection timeout
ERROR: Failed to process payment
ERROR: Null pointer exception in OrderService
ERROR: Authentication service unavailable
ERROR: Rate limit exceeded
INFO: Retry attempt 1 of 3
```

With 5 ERROR lines ingested, the `ApplicationErrors` metric has a `Sum` of 5 in the evaluation window. The `App-Errors-High` alarm threshold is `> 5`, so this borderline case results in the metric hitting exactly 5 — which does NOT breach the `GreaterThanThreshold` condition.

**To guarantee the alarm fires**: Push 6+ ERROR lines, or lower the threshold to `>= 5` using `GreaterThanOrEqualToThreshold`.

---

## Alarm on Custom Metric

```
Alarm Name:        App-Errors-High
Namespace:         CustomMetrics
Metric:            ApplicationErrors
Statistic:         Sum
Period:            300 (5 minutes)
Evaluation:        1 period
Threshold:         5
Operator:          GreaterThanThreshold
```

This alarm is identical in structure to the infrastructure alarms — the only difference is the metric source is a custom namespace fed by the log metric filter rather than a built-in AWS service metric.

---

## Querying Logs with CloudWatch Log Insights

Once log events are ingested, Log Insights enables ad-hoc analysis:

**Count errors by type (last 1 hour)**:
```
fields @timestamp, @message
| filter @message like /ERROR/
| stats count() as errorCount by @message
| sort errorCount desc
```

**Find all errors in a time range**:
```
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 50
```

**Check log ingestion rate**:
```
stats count() as events by bin(5m)
| sort @timestamp desc
```

Console path: `CloudWatch → Logs → Log Insights → select log group → run query`

---

## Production Pattern: Application Log Pipeline

In a real application, this pipeline would use the CloudWatch Unified Agent:

```
EC2 Application
  │ writes to /var/log/myapp/error.log
  ▼
CloudWatch Unified Agent (amazon-cloudwatch-agent)
  │ configured via /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  │ ships logs in near-real-time
  ▼
CloudWatch Logs → Metric Filter → Alarm → SNS → Email
```

The Unified Agent supports structured JSON logs, custom field extraction, and multi-line log events (stack traces). This project uses the CLI to simulate log ingestion directly — skipping the agent install for brevity.