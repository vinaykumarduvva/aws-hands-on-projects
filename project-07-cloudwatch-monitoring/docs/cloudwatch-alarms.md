# CloudWatch Alarms — Reference

All 8 alarms created in this project, with full configuration details.

---

## Alarm 1 — EC2-CPU-High

```
Namespace:          AWS/EC2
Metric:             CPUUtilization
Dimension:          InstanceId = monitoring-test instance ID
Statistic:          Average
Period:             300 seconds (5 minutes)
Evaluation Periods: 2
Threshold:          70
Operator:           GreaterThanThreshold
Alarm Actions:      SNS: monitoring-alerts
OK Actions:         SNS: monitoring-alerts
Missing Data:       notBreaching
```

**Trigger condition**: Average CPU > 70% for two consecutive 5-minute periods (10 minutes total).

**Why ok-actions**: Sends recovery email when CPU returns below threshold. Closes the incident loop.

---

## Alarm 2 — EC2-StatusCheck-Failed

```
Namespace:          AWS/EC2
Metric:             StatusCheckFailed
Dimension:          InstanceId = monitoring-test instance ID
Statistic:          Maximum
Period:             60 seconds (1 minute)
Evaluation Periods: 2
Threshold:          1
Operator:           GreaterThanOrEqualToThreshold
Alarm Actions:      SNS: monitoring-alerts
Missing Data:       notBreaching
```

**Trigger condition**: Any status check failure (value ≥ 1) in two consecutive 1-minute periods.

**Statistic rationale**: Maximum captures any failure during the period, even if other data points show 0.

---

## Alarm 3 — EC2-NetworkIn-High

```
Namespace:          AWS/EC2
Metric:             NetworkIn
Dimension:          InstanceId = monitoring-test instance ID
Statistic:          Average
Period:             300 seconds (5 minutes)
Evaluation Periods: 1
Threshold:          5000000 (bytes = 5MB)
Operator:           GreaterThanThreshold
Alarm Actions:      SNS: monitoring-alerts
Missing Data:       notBreaching
```

**Trigger condition**: Average inbound network traffic > 5MB in a 5-minute window.

**Units**: CloudWatch reports NetworkIn in bytes, not megabits. 5,000,000 bytes ≈ 5MB ≈ 40 Mbit.

---

## Alarm 4 — RDS-CPU-High

```
Namespace:          AWS/RDS
Metric:             CPUUtilization
Dimension:          DBInstanceIdentifier = myapp-database
Statistic:          Average
Period:             300 seconds (5 minutes)
Evaluation Periods: 2
Threshold:          80
Operator:           GreaterThanThreshold
Alarm Actions:      SNS: monitoring-alerts
OK Actions:         SNS: monitoring-alerts
Missing Data:       notBreaching
```

**Trigger condition**: Average RDS CPU > 80% for two consecutive 5-minute periods.

**State note**: Will show `INSUFFICIENT_DATA` if RDS instance `myapp-database` does not exist. This is expected after Project 6 cleanup.

---

## Alarm 5 — RDS-Storage-Low

```
Namespace:          AWS/RDS
Metric:             FreeStorageSpace
Dimension:          DBInstanceIdentifier = myapp-database
Statistic:          Average
Period:             300 seconds (5 minutes)
Evaluation Periods: 1
Threshold:          2000000000 (bytes = 2GB)
Operator:           LessThanThreshold
Alarm Actions:      SNS: monitoring-alerts
OK Actions:         SNS: monitoring-alerts
Missing Data:       notBreaching
```

**Trigger condition**: Free storage drops below 2GB.

**Units**: FreeStorageSpace is in bytes. 2,000,000,000 bytes = approximately 2GB. (Exact: 2GB = 2,147,483,648 bytes — the 2,000,000,000 value is a safe approximation that fires slightly early.)

---

## Alarm 6 — RDS-Connections-High

```
Namespace:          AWS/RDS
Metric:             DatabaseConnections
Dimension:          DBInstanceIdentifier = myapp-database
Statistic:          Average
Period:             300 seconds (5 minutes)
Evaluation Periods: 1
Threshold:          50
Operator:           GreaterThanThreshold
Alarm Actions:      SNS: monitoring-alerts
Missing Data:       notBreaching
```

**Trigger condition**: Active database connections > 50.

**Context**: db.t3.micro maximum connections = 66. Alert at 50 (76% of max) to allow investigation before exhaustion.

---

## Alarm 7 — Billing-Alert-5USD

```
Namespace:          AWS/Billing
Metric:             EstimatedCharges
Dimension:          Currency = USD
Statistic:          Maximum
Period:             86400 seconds (24 hours)
Evaluation Periods: 1
Threshold:          5
Operator:           GreaterThanThreshold
Alarm Actions:      SNS: monitoring-alerts
Missing Data:       notBreaching
Region:             us-east-1 (REQUIRED — billing metrics only here)
```

**Trigger condition**: Estimated monthly charges exceed $5.

**Important**: This alarm MUST be created in us-east-1. AWS Billing metrics are only published to us-east-1 regardless of which region your resources are in.

---

## Alarm 8 — App-Errors-High

```
Namespace:          CustomMetrics
Metric:             ApplicationErrors
Dimension:          (none — custom metric with no dimensions)
Statistic:          Sum
Period:             300 seconds (5 minutes)
Evaluation Periods: 1
Threshold:          5
Operator:           GreaterThanThreshold
Alarm Actions:      SNS: monitoring-alerts
Missing Data:       notBreaching
```

**Trigger condition**: More than 5 ERROR-pattern log entries in a 5-minute window.

**Source**: This metric does not come from AWS — it is created by the CloudWatch Logs metric filter on log group `/aws/ec2/monitoring-test`. Every log line matching the pattern `ERROR` increments this metric by 1.

**Verification**: After pushing test log events with 5 ERROR lines, this alarm transitions to ALARM state within one 5-minute evaluation period.

---

## Alarm States Summary (Post-Build)

| Alarm | Expected State | Notes |
|---|---|---|
| EC2-CPU-High | OK | CPU at idle baseline |
| EC2-StatusCheck-Failed | OK | Instance healthy |
| EC2-NetworkIn-High | OK | Minimal traffic |
| RDS-CPU-High | INSUFFICIENT_DATA | No RDS if Project 6 cleaned up |
| RDS-Storage-Low | INSUFFICIENT_DATA | No RDS if Project 6 cleaned up |
| RDS-Connections-High | INSUFFICIENT_DATA | No RDS if Project 6 cleaned up |
| Billing-Alert-5USD | OK | Within free tier |
| App-Errors-High | ALARM | After test log events pushed |

The INSUFFICIENT_DATA state for RDS alarms is normal — it means the alarm exists and is correctly configured, but there is no data source to evaluate against.