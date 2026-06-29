# Deployment Guide

## Automated Scripts Available
> [!TIP]
> **Dual-Platform Execution:** This project contains fully automated deployment and teardown scripts for both Windows (PowerShell) and Linux/macOS (Bash). Check the `scripts/` directory for `.ps1` files and the `bash-scripts/` directory for `.sh` files.

## Cleanup Guide

# Cleanup Guide — CloudWatch Monitoring Project

## Cleanup Order

CloudWatch alarms, dashboards, and log groups have no dependency chain — they can be deleted in any order. EC2 and its security group must be deleted after each other (SG after instance).

Script: `scripts/12-cleanup.ps1`

---

## Step-by-Step

### Step 1 — Delete All CloudWatch Alarms

```powershell
aws cloudwatch delete-alarms `
  --alarm-names `
    "EC2-CPU-High" `
    "EC2-StatusCheck-Failed" `
    "EC2-NetworkIn-High" `
    "RDS-CPU-High" `
    "RDS-Storage-Low" `
    "RDS-Connections-High" `
    "Billing-Alert-5USD" `
    "App-Errors-High"
```

All 8 alarms deleted in one API call. No wait needed.

### Step 2 — Delete Dashboard

```powershell
aws cloudwatch delete-dashboards \
  --dashboard-names "AWS-Bootcamp-Dashboard"
```

### Step 3 — Delete Log Group

```powershell
aws logs delete-log-group \
  --log-group-name "/aws/ec2/monitoring-test"
```

Deleting the log group deletes all log streams and events within it.

### Step 4 — Delete SNS Subscription and Topic

```powershell
# Get subscription ARN first
$SUB_ARN = aws sns list-subscriptions-by-topic \
  --topic-arn $SNS_ARN \
  --query "Subscriptions[0].SubscriptionArn" \
  --output text

# Unsubscribe (only if confirmed — PendingConfirmation subscriptions auto-expire)
if ($SUB_ARN -ne "PendingConfirmation") {
    aws sns unsubscribe --subscription-arn $SUB_ARN
}

# Delete the topic
aws sns delete-topic --topic-arn $SNS_ARN
```

Deleting the topic does not automatically unsubscribe — the endpoint receives no more messages, but the subscription record may linger. Explicit unsubscribe is cleaner.

### Step 5 — Terminate EC2 and Delete Security Group

```powershell
aws ec2 terminate-instances --instance-ids $MON_INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $MON_INSTANCE_ID
aws ec2 delete-security-group --group-id $MON_SG
```

Security group cannot be deleted while the instance is running or stopping — the wait command ensures termination is complete.

---

## Verification

```powershell
# Alarms gone
aws cloudwatch describe-alarms \
  --query "MetricAlarms[*].AlarmName" --output table
# Expected: empty

# Dashboard gone
aws cloudwatch list-dashboards \
  --query "DashboardEntries[*].DashboardName" --output table
# Expected: empty

# Log group gone
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/ec2/monitoring-test"
# Expected: empty list

# SNS topic gone
aws sns list-topics \
  --query "Topics[?contains(TopicArn,'monitoring-alerts')]"
# Expected: empty

# EC2 gone
aws ec2 describe-instances \
  --instance-ids $MON_INSTANCE_ID \
  --query "Reservations[0].Instances[0].State.Name" --output text
# Expected: terminated
```

---

## What This Project Leaves Behind

After cleanup, nothing billable remains. Verify in **AWS Billing → Cost Explorer** 24 hours later:
- CloudWatch: $0 (all within free tier)
- SNS: $0 (email notifications are free)
- EC2: $0 (terminated)
- CloudWatch Logs: $0 (minimal ingestion, within free tier)

---

## Re-fetch IDs If Variables Are Lost

```powershell
$SNS_ARN = aws sns list-topics `
  --query "Topics[?contains(TopicArn,`'monitoring-alerts`')].TopicArn | [0]" `
  --output text

$MON_INSTANCE_ID = aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=monitoring-test" `
  --query "Reservations[0].Instances[0].InstanceId" `
  --output text

$MON_SG = aws ec2 describe-security-groups `
  --filters "Name=group-name,Values=monitoring-test-sg" `
  --query "SecurityGroups[0].GroupId" `
  --output text

Write-Host "SNS:  $SNS_ARN"
Write-Host "EC2:  $MON_INSTANCE_ID"
Write-Host "SG:   $MON_SG"
```

