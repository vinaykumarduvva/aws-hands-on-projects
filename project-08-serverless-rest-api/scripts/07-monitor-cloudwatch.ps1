# ============================================================
# Project 8 - Part 7: Monitor with CloudWatch
# Description: View Lambda logs and metrics
# ============================================================

. "$PSScriptRoot\env.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PART 7: MONITOR WITH CLOUDWATCH" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$logGroupName = "/aws/lambda/$LAMBDA_FUNCTION_NAME"

# ── 1. LIST LOG GROUPS ──────────────────────────────────────────
Write-Host "[1/6] Lambda Log Groups:" -ForegroundColor Yellow
$logGroups = aws logs describe-log-groups `
    --log-group-name-prefix "/aws/lambda/$LAMBDA_FUNCTION_NAME" `
    --query "logGroups[*].{Name:logGroupName,Retention:retentionInDays,StoredBytes:storedBytes,CreationTime:creationTime}" `
    --output table

if (-not $logGroups) {
    Write-Host "  ⚠ No log groups found. Wait a few minutes after invoking Lambda." -ForegroundColor Yellow
}

# ── 2. GET LATEST LOG STREAM ────────────────────────────────────
Write-Host "[2/6] Getting latest log stream..." -ForegroundColor Yellow
$logStreams = aws logs describe-log-streams `
    --log-group-name $logGroupName `
    --order-by LastEventTime `
    --descending `
    --max-items 5 `
    --query "logStreams[*].{Name:logStreamName,LastEvent:lastEventTimestamp,FirstEvent:firstEventTimestamp}" `
    --output table

if ($logStreams) {
    # Get the most recent log stream name
    $latestStream = aws logs describe-log-streams `
        --log-group-name $logGroupName `
        --order-by LastEventTime `
        --descending `
        --max-items 1 `
        --query "logStreams[0].logStreamName" `
        --output text
    
    Write-Host "  ✓ Latest stream: $latestStream" -ForegroundColor Green
}

# ── 3. VIEW RECENT LOGS ─────────────────────────────────────────
Write-Host "[3/6] Recent Log Events:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

if ($latestStream) {
    $logEvents = aws logs get-log-events `
        --log-group-name $logGroupName `
        --log-stream-name $latestStream `
        --limit 50 `
        --query "events[*].{Timestamp:timestamp,Message:message}" `
        --output json | ConvertFrom-Json
    
    if ($logEvents) {
        $logEvents | ForEach-Object {
            $time = [DateTime]::new(1970, 1, 1, 0, 0, 0, 0).AddMilliseconds($_.Timestamp).ToString("HH:mm:ss")
            Write-Host "[$time]" -ForegroundColor DarkGray -NoNewline
            Write-Host " $($_.Message)" -ForegroundColor White
        }
    } else {
        Write-Host "  No log events found" -ForegroundColor Gray
    }
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

# ── 4. INVOCATION METRICS ───────────────────────────────────────
Write-Host "[4/6] Lambda Invocation Metrics (Last Hour):" -ForegroundColor Yellow

$startTime = (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
$endTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

# Invocations
$invocations = aws cloudwatch get-metric-statistics `
    --namespace AWS/Lambda `
    --metric-name Invocations `
    --dimensions Name=FunctionName,Value=$LAMBDA_FUNCTION_NAME `
    --start-time $startTime `
    --end-time $endTime `
    --period 300 `
    --statistics Sum `
    --query "Datapoints[*].{Time:Timestamp,Count:Sum}" `
    --output table

Write-Host "  Invocations:" -ForegroundColor Gray
Write-Host $invocations

# Errors
Write-Host "[5/6] Lambda Error Metrics (Last Hour):" -ForegroundColor Yellow

$errors = aws cloudwatch get-metric-statistics `
    --namespace AWS/Lambda `
    --metric-name Errors `
    --dimensions Name=FunctionName,Value=$LAMBDA_FUNCTION_NAME `
    --start-time $startTime `
    --end-time $endTime `
    --period 300 `
    --statistics Sum `
    --query "Datapoints[*].{Time:Timestamp,Count:Sum}" `
    --output table

Write-Host "  Errors:" -ForegroundColor Gray
Write-Host $errors

# Duration
Write-Host "[6/6] Lambda Duration Metrics (Last Hour):" -ForegroundColor Yellow

$duration = aws cloudwatch get-metric-statistics `
    --namespace AWS/Lambda `
    --metric-name Duration `
    --dimensions Name=FunctionName,Value=$LAMBDA_FUNCTION_NAME `
    --start-time $startTime `
    --end-time $endTime `
    --period 300 `
    --statistics Average `
    --query "Datapoints[*].{Time:Timestamp,AvgDuration:Average}" `
    --output table

Write-Host "  Duration (ms):" -ForegroundColor Gray
Write-Host $duration

# ── 7. API GATEWAY METRICS ──────────────────────────────────────
if ($API_ID) {
    Write-Host ""
    Write-Host "API Gateway Metrics (Last Hour):" -ForegroundColor Yellow
    
    # Count
    aws cloudwatch get-metric-statistics `
        --namespace AWS/ApiGateway `
        --metric-name Count `
        --dimensions Name=ApiName,Value=$API_NAME `
        --start-time $startTime `
        --end-time $endTime `
        --period 3600 `
        --statistics Sum `
        --query "Datapoints[0].Sum" `
        --output table
    
    # Latency
    aws cloudwatch get-metric-statistics `
        --namespace AWS/ApiGateway `
        --metric-name Latency `
        --dimensions Name=ApiName,Value=$API_NAME `
        --start-time $startTime `
        --end-time $endTime `
        --period 3600 `
        --statistics Average `
        --query "Datapoints[0].{AvgLatency:Average,Unit:Unit}" `
        --output table
}

# ── 8. DYNAMODB METRICS ─────────────────────────────────────────
Write-Host "DynamoDB Metrics (Last Hour):" -ForegroundColor Yellow

aws cloudwatch get-metric-statistics `
    --namespace AWS/DynamoDB `
    --metric-name ConsumedReadCapacityUnits `
    --dimensions Name=TableName,Value=$TABLE_NAME `
    --start-time $startTime `
    --end-time $endTime `
    --period 3600 `
    --statistics Sum `
    --query "Datapoints[0].Sum" `
    --output table 2>$null

Write-Host ""

# ── SUMMARY ──────────────────────────────────────────────────────
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MONITORING SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Log Group: $logGroupName" -ForegroundColor White
Write-Host "  Dashboard: https://console.aws.amazon.com/cloudwatch" -ForegroundColor White
Write-Host ""
Write-Host "Key Links:" -ForegroundColor Yellow
Write-Host "  • Lambda Console: https://console.aws.amazon.com/lambda/home?region=$REGION#/functions/$LAMBDA_FUNCTION_NAME" -ForegroundColor Gray
Write-Host "  • API Gateway: https://console.aws.amazon.com/apigateway/home?region=$REGION#/apis/$API_ID/resources" -ForegroundColor Gray
Write-Host "  • DynamoDB: https://console.aws.amazon.com/dynamodb/home?region=$REGION#tables:selected=$TABLE_NAME" -ForegroundColor Gray
Write-Host "  • CloudWatch: https://console.aws.amazon.com/cloudwatch/home?region=$REGION" -ForegroundColor Gray
Write-Host ""