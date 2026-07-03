# Troubleshooting — Project 10 Auto Scaling Group + ALB

## Common Issues and Fixes

### 1. Instances Stuck in "Pending" State

**Symptom:** ASG instances show LifecycleState: Pending for more than 5 minutes.

**Cause:** Health check failing — instance cannot serve HTTP on port 80.

**Fix:**
```powershell
# Check instance user data log
aws ssm start-session --target i-xxxxx
# Inside session:
cat /tmp/setup.log
systemctl status httpd
journalctl -u httpd --no-pager
```

Common causes:
- User data script failed (yum update timeout)
- Apache not started (httpd service not running)
- Security group blocks port 80 from ALB

---

### 2. ALB Shows No Healthy Targets

**Symptom:** `describe-target-health` shows all targets as "unhealthy" or "initial".

**Causes and fixes:**

| Cause | Fix |
|---|---|
| Instances still booting | Wait 2-3 minutes for health check grace period |
| EC2 SG missing ALB rule | Add TCP:80 from alb-sg to asg-ec2-sg |
| Apache not running | SSH in, run `systemctl start httpd` |
| Wrong health check path | Verify TG health check path is `/` |
| Wrong health check port | Verify TG port is 80 |

```powershell
# Check target health details (includes reason)
aws elbv2 describe-target-health `
    --target-group-arn $TG_ARN `
    --query "TargetHealthDescriptions[*].{
      Instance:Target.Id,
      State:TargetHealth.State,
      Reason:TargetHealth.Reason,
      Description:TargetHealth.Description}" `
    --output table
```

---

### 3. Browser Shows "Connection Refused" or Timeout

**Symptom:** Opening `http://ALB_DNS` in browser gives connection error.

**Causes:**

| Cause | Fix |
|---|---|
| ALB still provisioning | Wait for state = "active" |
| ALB SG blocks HTTP | Add TCP:80 from 0.0.0.0/0 to alb-sg |
| No healthy targets | Wait for instances to pass health checks |
| DNS not propagated | Wait 1-2 minutes, try again |

```powershell
# Check ALB state
aws elbv2 describe-load-balancers `
    --names my-alb `
    --query "LoadBalancers[0].State.Code" --output text
# Expected: "active"
```

---

### 4. ASG Not Scaling Out

**Symptom:** CPU is high but no new instances launching.

**Causes:**

| Cause | Fix |
|---|---|
| CPU not sustained long enough | Alarm needs 3 data points over 3 minutes |
| Already at max capacity | Increase max-size in ASG |
| No scaling policy attached | Verify policy exists |
| Instance warmup too long | New instances excluded from average |

```powershell
# Check scaling policy
aws autoscaling describe-policies `
    --auto-scaling-group-name web-server-asg `
    --query "ScalingPolicies[*].{Name:PolicyName,Type:PolicyType}" `
    --output table

# Check CloudWatch alarms
aws cloudwatch describe-alarms `
    --alarm-name-prefix "TargetTracking-web-server-asg" `
    --query "MetricAlarms[*].{Name:AlarmName,State:StateValue,Threshold:Threshold}" `
    --output table

# Check scaling activities
aws autoscaling describe-scaling-activities `
    --auto-scaling-group-name web-server-asg `
    --max-items 5 `
    --query "Activities[*].{Time:StartTime,Status:StatusCode,Cause:Cause}" `
    --output table
```

---

### 5. ALB Creation Fails — "At Least Two Subnets"

**Symptom:** `create-load-balancer` returns error about subnets.

**Fix:** ALB requires subnets in at least 2 different AZs.

```powershell
# Verify subnets are in different AZs
aws ec2 describe-subnets `
    --subnet-ids $SUBNET_A $SUBNET_B `
    --query "Subnets[*].{SubnetId:SubnetId,AZ:AvailabilityZone}" `
    --output table

# Must show different AZs (e.g., ap-south-1a and ap-south-1b)
```

---

### 6. Cannot Delete Security Groups

**Symptom:** `delete-security-group` fails with "DependencyViolation".

**Cause:** Security group is still associated with ALB, instances, or ENIs.

**Fix:** Delete resources in order:
1. Delete ASG (terminates instances)
2. Delete ALB (releases ENIs)
3. Wait 30-60 seconds
4. Delete Target Group
5. Delete Security Groups

```powershell
# Find what is using the security group
aws ec2 describe-network-interfaces `
    --filters "Name=group-id,Values=$EC2_SG" `
    --query "NetworkInterfaces[*].{ID:NetworkInterfaceId,Type:InterfaceType,Description:Description}" `
    --output table
```

---

### 7. Target Group Shows "draining" State

**Symptom:** Targets stuck in "draining" state for a long time.

**Cause:** Connection draining wait period (default 300 seconds).

**Fix:** Wait — draining completes after the deregistration delay.

```powershell
# Check deregistration delay (default 300s)
aws elbv2 describe-target-group-attributes `
    --target-group-arn $TG_ARN `
    --query "Attributes[?Key=='deregistration_delay.timeout_seconds']" `
    --output table
```

---

### 8. ASG Infinite Launch-Terminate Loop

**Symptom:** ASG keeps launching and terminating instances repeatedly.

**Cause:** Health check grace period is too short — instances are terminated
before user data completes.

**Fix:**
```powershell
# Increase health check grace period
aws autoscaling update-auto-scaling-group `
    --auto-scaling-group-name web-server-asg `
    --health-check-grace-period 300
```

---

### 9. Instances Not Receiving Equal Traffic

**Symptom:** One instance gets most requests, others idle.

**Causes:**

| Cause | Fix |
|---|---|
| Sticky sessions enabled | Disable or use shorter TTL |
| Client caching DNS | Different clients needed |
| Cross-zone disabled | Enable cross-zone load balancing |

The ALB uses round-robin by default. Test with:
```powershell
1..20 | ForEach-Object {
    $r = Invoke-WebRequest -Uri "http://$ALB_DNS" -UseBasicParsing
    [regex]::Match($r.Content, 'i-[0-9a-f]+').Value
}
```

---

### 10. stress Command Not Found

**Symptom:** Running `stress` on the instance fails.

**Fix:** The user data script installs it, but if it failed:
```bash
sudo yum install -y stress
# Then run:
sudo stress --cpu 1 --timeout 600 &
```

---

## Debugging Checklist

```text
□ Is the ALB in "active" state?
□ Are both subnets in different AZs?
□ Does alb-sg allow TCP:80 from 0.0.0.0/0?
□ Does asg-ec2-sg allow TCP:80 from alb-sg?
□ Is the Launch Template using the correct SG?
□ Is Apache running on the instances? (systemctl status httpd)
□ Does the health check path (/) return HTTP 200?
□ Is the ASG attached to the correct Target Group?
□ Is the health check grace period long enough (120s+)?
□ Are there at least 2 instances InService?
```

---
