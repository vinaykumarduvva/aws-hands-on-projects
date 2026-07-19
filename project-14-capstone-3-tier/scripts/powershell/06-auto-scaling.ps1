# PART 6 - AUTO SCALING GROUP

# Retrieve LT, TG, App Subnets if needed
# $LT_ID = aws ec2 describe-launch-templates --launch-template-names capstone-app-lt --query "LaunchTemplates[0].LaunchTemplateId" --output text
# $TG_ARN = aws elbv2 describe-target-groups --names capstone-app-tg --query "TargetGroups[0].TargetGroupArn" --output text
# $VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text
# $APP_A = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-app-subnet-a" --query "Subnets[0].SubnetId" --output text
# $APP_B = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-app-subnet-b" --query "Subnets[0].SubnetId" --output text

# Create ASG in private app subnets
aws autoscaling create-auto-scaling-group `
  --auto-scaling-group-name capstone-asg `
  --launch-template "LaunchTemplateId=$LT_ID,Version=`$Latest" `
  --min-size 2 --max-size 4 --desired-capacity 2 `
  --vpc-zone-identifier "$APP_A,$APP_B" `
  --target-group-arns $TG_ARN `
  --health-check-type ELB `
  --health-check-grace-period 180 `
  --tags `
    "Key=Name,Value=capstone-app-server,PropagateAtLaunch=true" `
    "Key=Project,Value=project-14-capstone,PropagateAtLaunch=true"

# Add target tracking scaling policy at 60% CPU
aws autoscaling put-scaling-policy `
  --auto-scaling-group-name capstone-asg `
  --policy-name capstone-cpu-tracking `
  --policy-type TargetTrackingScaling `
  --target-tracking-configuration "{
    `"PredefinedMetricSpecification`":{
      `"PredefinedMetricType`":`"ASGAverageCPUUtilization`"
    },
    `"TargetValue`":60.0,
    `"EstimatedInstanceWarmup`":180
  }"

Write-Host "ASG created - instances launching..."
