# PART 7 - MONITORING AND ALERTING

# Step 12 - Create SNS topic
$SNS_ARN = aws sns create-topic `
  --name capstone-alerts `
  --attributes DisplayName="Capstone Monitoring" `
  --query "TopicArn" --output text

aws sns subscribe `
  --topic-arn $SNS_ARN `
  --protocol email `
  --notification-endpoint "your-email@gmail.com"

Write-Host "SNS topic created - confirm subscription email"

# Retrieve ALB_ARN and TG_ARN if needed
# $ALB_ARN = aws elbv2 describe-load-balancers --names capstone-alb --query "LoadBalancers[0].LoadBalancerArn" --output text
# $TG_ARN = aws elbv2 describe-target-groups --names capstone-app-tg --query "TargetGroups[0].TargetGroupArn" --output text
$ALB_ID = ($ALB_ARN -split '/')[-3..-1] -join '/'
$TG_ID = ($TG_ARN -split ':')[-1]

# Step 13 - Create CloudWatch alarms
# ALB 5XX Error Rate alarm
aws cloudwatch put-metric-alarm `
  --alarm-name "Capstone-ALB-5XX-High" `
  --alarm-description "ALB 5XX error rate above 10 per minute" `
  --namespace "AWS/ApplicationELB" `
  --metric-name "HTTPCode_Target_5XX_Count" `
  --dimensions "Name=LoadBalancer,Value=$ALB_ID" `
  --statistic Sum --period 60 `
  --evaluation-periods 2 --threshold 10 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data notBreaching

# ASG CPU High alarm
aws cloudwatch put-metric-alarm `
  --alarm-name "Capstone-ASG-CPU-High" `
  --alarm-description "App tier CPU above 70%" `
  --namespace "AWS/EC2" `
  --metric-name "CPUUtilization" `
  --dimensions "Name=AutoScalingGroupName,Value=capstone-asg" `
  --statistic Average --period 300 `
  --evaluation-periods 2 --threshold 70 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data notBreaching

# RDS CPU alarm
aws cloudwatch put-metric-alarm `
  --alarm-name "Capstone-RDS-CPU-High" `
  --alarm-description "DB tier CPU above 80%" `
  --namespace "AWS/RDS" `
  --metric-name "CPUUtilization" `
  --dimensions "Name=DBInstanceIdentifier,Value=capstone-database" `
  --statistic Average --period 300 `
  --evaluation-periods 2 --threshold 80 `
  --comparison-operator GreaterThanThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data notBreaching

# RDS Free Storage alarm
aws cloudwatch put-metric-alarm `
  --alarm-name "Capstone-RDS-Storage-Low" `
  --alarm-description "DB free storage below 5GB" `
  --namespace "AWS/RDS" `
  --metric-name "FreeStorageSpace" `
  --dimensions "Name=DBInstanceIdentifier,Value=capstone-database" `
  --statistic Average --period 300 `
  --evaluation-periods 1 --threshold 5000000000 `
  --comparison-operator LessThanThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data notBreaching

# Healthy host count alarm (catches instance failures)
aws cloudwatch put-metric-alarm `
  --alarm-name "Capstone-ALB-Healthy-Hosts-Low" `
  --alarm-description "Fewer than 2 healthy instances behind ALB" `
  --namespace "AWS/ApplicationELB" `
  --metric-name "HealthyHostCount" `
  --dimensions `
    "Name=TargetGroup,Value=$TG_ID" `
    "Name=LoadBalancer,Value=$ALB_ID" `
  --statistic Minimum --period 60 `
  --evaluation-periods 1 --threshold 2 `
  --comparison-operator LessThanThreshold `
  --alarm-actions $SNS_ARN `
  --treat-missing-data breaching

Write-Host "All 5 CloudWatch alarms created"

# Step 14 - Create CloudWatch Dashboard
$DASHBOARD = @"
{
  "widgets": [
    {
      "type":"metric","x":0,"y":0,"width":12,"height":6,
      "properties":{
        "title":"ALB Request Count + 5XX Errors",
        "metrics":[
          ["AWS/ApplicationELB","RequestCount","LoadBalancer","$ALB_ID",{"stat":"Sum","color":"#2196F3"}],
          ["AWS/ApplicationELB","HTTPCode_Target_5XX_Count","LoadBalancer","$ALB_ID",{"stat":"Sum","color":"#f44336"}]
        ],
        "view":"timeSeries","region":"ap-south-1","period":60
      }
    },
    {
      "type":"metric","x":12,"y":0,"width":6,"height":6,
      "properties":{
        "title":"ALB Healthy Hosts",
        "metrics":[
          ["AWS/ApplicationELB","HealthyHostCount","TargetGroup","$TG_ID","LoadBalancer","$ALB_ID",{"stat":"Minimum","color":"#4CAF50"}]
        ],
        "view":"singleValue","region":"ap-south-1"
      }
    },
    {
      "type":"metric","x":18,"y":0,"width":6,"height":6,
      "properties":{
        "title":"ALB Response Time (ms)",
        "metrics":[
          ["AWS/ApplicationELB","TargetResponseTime","LoadBalancer","$ALB_ID",{"stat":"Average","color":"#FF9800"}]
        ],
        "view":"singleValue","region":"ap-south-1"
      }
    },
    {
      "type":"metric","x":0,"y":6,"width":12,"height":6,
      "properties":{
        "title":"App Tier CPU Utilization",
        "metrics":[
          ["AWS/EC2","CPUUtilization","AutoScalingGroupName","capstone-asg",{"stat":"Average","color":"#9C27B0"}]
        ],
        "view":"timeSeries","region":"ap-south-1",
        "annotations":{"horizontal":[{"value":60,"color":"#f44336","label":"Scale threshold"}]}
      }
    },
    {
      "type":"metric","x":12,"y":6,"width":12,"height":6,
      "properties":{
        "title":"DB Tier CPU + Connections",
        "metrics":[
          ["AWS/RDS","CPUUtilization","DBInstanceIdentifier","capstone-database",{"stat":"Average","color":"#E91E63","label":"CPU %"}],
          ["AWS/RDS","DatabaseConnections","DBInstanceIdentifier","capstone-database",{"stat":"Average","color":"#00BCD4","yAxis":"right","label":"Connections"}]
        ],
        "view":"timeSeries","region":"ap-south-1"
      }
    }
  ]
}
"@

aws cloudwatch put-dashboard `
  --dashboard-name "Capstone-3Tier-Dashboard" `
  --dashboard-body $DASHBOARD

Write-Host "CloudWatch Dashboard created"
