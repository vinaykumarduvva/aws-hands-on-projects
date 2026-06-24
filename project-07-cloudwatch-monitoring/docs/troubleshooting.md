# Troubleshooting — CloudWatch Monitoring Project

---

## Alarm Stays in INSUFFICIENT_DATA

**Symptom**: Alarm shows `INSUFFICIENT_DATA` instead of `OK` after creation.

**Cause**: CloudWatch needs at least one data point before it can evaluate the threshold. EC2 metrics publish every 1 minute (basic monitoring) or every 10 seconds (detailed monitoring, extra cost).

**Fix**:
- Wait 5–10 minutes after launching the EC2 instance
- Verify the instance ID in the alarm matches the running instance:
  ```powershell
  aws cloudwatch describe-alarms \
    --alarm-names "EC2-CPU-High" \
    --query "MetricAlarms[0].Dimensions"
  ```
- Check that basic monitoring is enabled (it is by default)

**RDS alarms**: If the RDS instance from Project 6 was deleted, RDS alarms remain `INSUFFICIENT_DATA`. This is expected and correct — the alarm exists but has no data source.

---

## Email Not Received After Alarm Fires

**Symptom**: Alarm state changed to ALARM but no email arrived.

**Cause 1 — Subscription not confirmed**
- SNS will not deliver to an unconfirmed subscription
- Check status: `aws sns list-subscriptions-by-topic --topic-arn $SNS_ARN`
- If status shows `PendingConfirmation`, resend the confirmation email:
  ```powershell
  aws sns subscribe \
    --topic-arn $SNS_ARN \
    --protocol email \
    --notification-endpoint "your-email@example.com"
  ```
- Check your spam/junk folder — the AWS confirmation email is often filtered

**Cause 2 — Wrong SNS ARN in alarm**
- Verify: `aws cloudwatch describe-alarms --alarm-names "EC2-CPU-High" --query "MetricAlarms[0].AlarmActions"`
- Should match your `$SNS_ARN`

**Cause 3 — Alarm never reached ALARM state**
- Check alarm history: `aws cloudwatch describe-alarm-history --alarm-name "EC2-CPU-High"`
- The alarm requires 2 consecutive 5-minute periods above 70%. The stress test must run for at least 11 minutes.

---

## Billing Alarm Not Visible in CloudWatch

**Symptom**: Cannot find the billing alarm or `EstimatedCharges` metric.

**Cause**: Billing metrics only exist in `us-east-1`. Viewing CloudWatch in any other region shows nothing for billing.

**Fix**:
- Switch AWS console region to `US East (N. Virginia)` — `us-east-1`
- For CLI: add `--region us-east-1` to billing alarm commands
- Verify: `aws cloudwatch describe-alarms --alarm-names "Billing-Alert-5USD" --region us-east-1`

---

## CPU Stress Test Not Triggering Alarm

**Symptom**: Ran `stress --cpu 1 --timeout 300` but alarm stayed OK.

**Cause 1 — Not enough time**
- The alarm needs 2 × 5-minute periods = 10 minutes minimum
- The stress tool ran for 5 minutes (300 seconds) — not long enough
- **Fix**: Use `--timeout 720` (12 minutes) to guarantee two full evaluation periods

**Cause 2 — Wrong instance being monitored**
- Alarm is watching a different instance ID
- Check: `aws cloudwatch describe-alarms --alarm-names "EC2-CPU-High" --query "MetricAlarms[0].Dimensions"`
- Verify it matches `$MON_INSTANCE_ID`

**Cause 3 — CPU didn't actually reach 70%**
- `stress --cpu 1` uses one CPU core — on a t2.micro with 1 vCPU this should reach ~100%
- Confirm with `top` in a second SSH window — `%Cpu(s): 99.7 us` is expected

---

## Dashboard Shows No Data

**Symptom**: Dashboard widgets show "No data available".

**Cause 1 — Wrong instance ID hardcoded**
- The dashboard JSON was created with `$MON_INSTANCE_ID` at the time of creation
- If the instance was replaced, the ID changed
- Fix: Edit the widget → reselect the metric → save

**Cause 2 — Viewing wrong time range**
- Set the dashboard time picker to "Last 3 hours"
- Metrics only exist from the time the instance was launched

**Cause 3 — Billing widget shows no data**
- AWS updates billing metrics once per day
- The widget may show no data if checked immediately after creation
- Wait 24 hours or check at a specific time the next day

---

## Log Metric Filter Not Counting

**Symptom**: After pushing log events with ERROR lines, the `ApplicationErrors` metric shows no data.

**Cause 1 — Pattern case mismatch**
- The filter pattern `ERROR` is case-sensitive
- `Error` or `error` will NOT match
- Verify your test log events contain uppercase `ERROR`

**Cause 2 — Log stream sequence token issue**
- Subsequent `put-log-events` calls to the same stream require a sequence token
- The script uses timestamps to avoid this — check that timestamps are in milliseconds

**Cause 3 — Metric filter created after log events were pushed**
- Metric filters only apply to log events ingested AFTER the filter was created
- Create the filter first, then push log events

**Fix**:
1. Run `09-create-metric-filter.ps1` to ensure filter exists
2. Then run `10-test-log-events.ps1` to push new events
3. Wait 1–2 minutes for the metric to update

---

## Variables Lost Between PowerShell Sessions

**Symptom**: `$SNS_ARN`, `$MON_INSTANCE_ID` are empty.

**Fix — Re-fetch all IDs**:
```powershell
$SNS_ARN = aws sns list-topics \
  --query "Topics[?contains(TopicArn,'monitoring-alerts')].TopicArn | [0]" \
  --output text

$MON_INSTANCE_ID = aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=monitoring-test" \
            "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text

Write-Host "SNS: $SNS_ARN"
Write-Host "EC2: $MON_INSTANCE_ID"
```

---

## Alarm Actions Not Firing (OK → ALARM Transition Missed)

**Symptom**: Alarm is in ALARM state but SNS never received a message.

**Cause**: The alarm transitioned directly from `INSUFFICIENT_DATA` to `ALARM` on the first evaluation. Some alarm action implementations only fire on `OK → ALARM` transitions, not `INSUFFICIENT_DATA → ALARM`.

**Fix**: This is a known AWS behaviour. The alarm will fire properly on the next `OK → ALARM` transition. To force an `OK → ALARM` cycle:
1. Let the stress test complete → alarm returns to OK
2. Run stress test again → alarm transitions OK → ALARM → email fires