# =============================================================================
# Project 7 — Script 07: CloudWatch Dashboard
# Creates AWS-Bootcamp-Dashboard with EC2, RDS, and billing widgets
# =============================================================================

Write-Host "=== Project 7 — CloudWatch Dashboard ===" -ForegroundColor Cyan
Write-Host ""

if (-not $MON_INSTANCE_ID) {
    Write-Host "ERROR: MON_INSTANCE_ID not set. Run 02-launch-monitoring-ec2.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "Building dashboard for instance: $MON_INSTANCE_ID" -ForegroundColor Yellow
Write-Host ""

# ── BUILD DASHBOARD JSON ──────────────────────────────────────────────────────
$DASHBOARD_BODY = @"
{
  "widgets": [
    {
      "type": "metric",
      "x": 0, "y": 0, "width": 12, "height": 6,
      "properties": {
        "title": "EC2 CPU Utilization",
        "metrics": [
          ["AWS/EC2","CPUUtilization","InstanceId","$MON_INSTANCE_ID",
           {"stat":"Average","period":300,"color":"#2196F3","label":"CPU %"}]
        ],
        "view": "timeSeries",
        "annotations": {
          "horizontal": [{"value":70,"color":"#f44336","label":"Alarm threshold (70%)"}]
        },
        "period": 300,
        "yAxis": {"left":{"min":0,"max":100}},
        "region": "us-east-1",
        "legend": {"position":"bottom"}
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 0, "width": 12, "height": 6,
      "properties": {
        "title": "EC2 Network Traffic",
        "metrics": [
          ["AWS/EC2","NetworkIn","InstanceId","$MON_INSTANCE_ID",
           {"stat":"Average","period":300,"color":"#4CAF50","label":"Network In (bytes)"}],
          ["AWS/EC2","NetworkOut","InstanceId","$MON_INSTANCE_ID",
           {"stat":"Average","period":300,"color":"#FF9800","label":"Network Out (bytes)"}]
        ],
        "view": "timeSeries",
        "region": "us-east-1",
        "legend": {"position":"bottom"}
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 6, "width": 12, "height": 6,
      "properties": {
        "title": "RDS CPU Utilization",
        "metrics": [
          ["AWS/RDS","CPUUtilization","DBInstanceIdentifier","myapp-database",
           {"stat":"Average","period":300,"color":"#9C27B0","label":"RDS CPU %"}]
        ],
        "view": "timeSeries",
        "annotations": {
          "horizontal": [{"value":80,"color":"#f44336","label":"Alarm threshold (80%)"}]
        },
        "region": "us-east-1"
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 6, "width": 6, "height": 6,
      "properties": {
        "title": "RDS Database Connections",
        "metrics": [
          ["AWS/RDS","DatabaseConnections","DBInstanceIdentifier","myapp-database",
           {"stat":"Average","period":300,"color":"#E91E63"}]
        ],
        "view": "singleValue",
        "region": "us-east-1"
      }
    },
    {
      "type": "metric",
      "x": 18, "y": 6, "width": 6, "height": 6,
      "properties": {
        "title": "Estimated AWS Charges (USD)",
        "metrics": [
          ["AWS/Billing","EstimatedCharges","Currency","USD",
           {"stat":"Maximum","period":86400,"color":"#FF5722"}]
        ],
        "view": "singleValue",
        "region": "us-east-1"
      }
    }
  ]
}
"@

# Save dashboard JSON
$DASHBOARD_BODY | Out-File -FilePath "dashboard.json" -Encoding utf8
Write-Host "Dashboard JSON saved to dashboard.json" -ForegroundColor Green

# ── UPLOAD DASHBOARD ──────────────────────────────────────────────────────────
Write-Host "Uploading dashboard to CloudWatch..." -ForegroundColor Yellow

aws cloudwatch put-dashboard `
  --dashboard-name "AWS-Bootcamp-Dashboard" `
  --dashboard-body file://dashboard.json

Write-Host "Dashboard created." -ForegroundColor Green

# ── VERIFY ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Verifying dashboard..." -ForegroundColor Yellow

aws cloudwatch list-dashboards `
  --query "DashboardEntries[?DashboardName=='AWS-Bootcamp-Dashboard'].{Name:DashboardName,Size:Size,Modified:LastModified}" `
  --output table

Write-Host ""
Write-Host "=== Dashboard Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Console path: CloudWatch -> Dashboards -> AWS-Bootcamp-Dashboard"
Write-Host ""
Write-Host "Widgets created:"
Write-Host "  1. EC2 CPU Utilization (line chart, 70% threshold line)"
Write-Host "  2. EC2 Network Traffic (NetworkIn + NetworkOut dual line)"
Write-Host "  3. RDS CPU Utilization (line chart, 80% threshold line)"
Write-Host "  4. RDS Database Connections (single value)"
Write-Host "  5. Estimated AWS Charges USD (single value)"
Write-Host ""
Write-Host "Next step: Run 08-create-log-group.ps1" -ForegroundColor Cyan