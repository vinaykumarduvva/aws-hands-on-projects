# =============================================================================
# Project 10 — Script 07: Create Auto Scaling Group
# Creates ASG with min:2, max:4, desired:2, ELB health checks, CPU scaling
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Create Auto Scaling Group ===" -ForegroundColor Cyan
Write-Host ""

# ── PRE-REQUISITES ────────────────────────────────────────────────────────────
$VPC_ID = aws ec2 describe-vpcs `
  --filters "Name=isDefault,Values=true" `
  --query "Vpcs[0].VpcId" --output text

$SUBNETS = aws ec2 describe-subnets `
  --filters "Name=vpc-id,Values=$VPC_ID" `
  "Name=defaultForAz,Values=true" `
  --query "Subnets[*].SubnetId" `
  --output text

$SUBNET_LIST = $SUBNETS -split '\s+'
$SUBNET_A = $SUBNET_LIST[0]
$SUBNET_B = $SUBNET_LIST[1]

$LT_ID = aws ec2 describe-launch-templates `
  --launch-template-names web-server-lt `
  --query "LaunchTemplates[0].LaunchTemplateId" --output text

$TG_ARN = aws elbv2 describe-target-groups `
  --names web-server-tg `
  --query "TargetGroups[0].TargetGroupArn" --output text

Write-Host "  VPC:              $VPC_ID" -ForegroundColor Green
Write-Host "  Subnets:          $SUBNET_A, $SUBNET_B" -ForegroundColor Green
Write-Host "  Launch Template:  $LT_ID" -ForegroundColor Green
Write-Host "  Target Group:     $TG_ARN" -ForegroundColor Green
Write-Host ""

# ── CREATE AUTO SCALING GROUP ─────────────────────────────────────────────────
Write-Host "[1/2] Creating Auto Scaling Group..." -ForegroundColor Yellow

aws autoscaling create-auto-scaling-group `
  --auto-scaling-group-name web-server-asg `
  --launch-template "LaunchTemplateId=$LT_ID,Version=`$Latest" `
  --min-size 2 `
  --max-size 4 `
  --desired-capacity 2 `
  --vpc-zone-identifier "$SUBNET_A,$SUBNET_B" `
  --target-group-arns $TG_ARN `
  --health-check-type ELB `
  --health-check-grace-period 120 `
  --tags "Key=Name,Value=asg-web-server,PropagateAtLaunch=true" `
  "Key=Project,Value=project-10-asg-alb,PropagateAtLaunch=true"

Write-Host "  ASG created: web-server-asg" -ForegroundColor Green
Write-Host "  Min: 2 | Desired: 2 | Max: 4" -ForegroundColor Green
Write-Host "  Health Check: ELB (ALB), Grace Period: 120s" -ForegroundColor Green

# ── ADD TARGET TRACKING SCALING POLICY ────────────────────────────────────────
Write-Host ""
Write-Host "[2/2] Adding CPU target tracking scaling policy..." -ForegroundColor Yellow

aws autoscaling put-scaling-policy `
  --auto-scaling-group-name web-server-asg `
  --policy-name cpu-target-tracking `
  --policy-type TargetTrackingScaling `
  --target-tracking-configuration "{
      `"PredefinedMetricSpecification`":{
        `"PredefinedMetricType`":`"ASGAverageCPUUtilization`"
      },
      `"TargetValue`":50.0,
      `"EstimatedInstanceWarmup`":120
    }" | Out-Null

Write-Host "  Scaling policy: cpu-target-tracking" -ForegroundColor Green
Write-Host "  Target: 50% average CPU utilization" -ForegroundColor Green
Write-Host "  Warmup: 120 seconds" -ForegroundColor Green

# ── WAIT FOR INSTANCES ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Waiting for instances to launch (60 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# ── CHECK STATUS ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Checking ASG status..." -ForegroundColor Yellow
aws autoscaling describe-auto-scaling-groups `
  --auto-scaling-group-names web-server-asg `
  --query "AutoScalingGroups[0].{
      Name:AutoScalingGroupName,
      Min:MinSize,
      Max:MaxSize,
      Desired:DesiredCapacity,
      Instances:Instances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus,AZ:AvailabilityZone}
    }" `
  --output json

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Auto Scaling Group Complete ===" -ForegroundColor Cyan
Write-Host "  ASG Name:        web-server-asg"
Write-Host "  Min/Desired/Max: 2 / 2 / 4"
Write-Host "  Scaling Policy:  CPU target tracking at 50%"
Write-Host "  Health Check:    ELB (ALB checks via Target Group)"
Write-Host "  Subnets:         2 AZs for high availability"
Write-Host ""
Write-Host "  Instances are launching — it takes 2-3 minutes to pass health checks." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run 08-verify-and-test.ps1" -ForegroundColor Cyan
