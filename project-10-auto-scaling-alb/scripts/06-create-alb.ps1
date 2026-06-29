# =============================================================================
# Project 10 — Script 06: Create Application Load Balancer
# Creates internet-facing ALB with HTTP listener forwarding to target group
# Region: ap-south-1
# =============================================================================

Write-Host "=== Project 10 — Create Application Load Balancer ===" -ForegroundColor Cyan
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

$ALB_SG = aws ec2 describe-security-groups `
    --filters "Name=group-name,Values=alb-sg" `
    "Name=vpc-id,Values=$VPC_ID" `
    --query "SecurityGroups[0].GroupId" --output text

$TG_ARN = aws elbv2 describe-target-groups `
    --names web-server-tg `
    --query "TargetGroups[0].TargetGroupArn" --output text

Write-Host "  VPC:      $VPC_ID" -ForegroundColor Green
Write-Host "  Subnet A: $SUBNET_A" -ForegroundColor Green
Write-Host "  Subnet B: $SUBNET_B" -ForegroundColor Green
Write-Host "  ALB SG:   $ALB_SG" -ForegroundColor Green
Write-Host "  TG ARN:   $TG_ARN" -ForegroundColor Green
Write-Host ""

# ── CREATE ALB ────────────────────────────────────────────────────────────────
Write-Host "[1/3] Creating Application Load Balancer..." -ForegroundColor Yellow

$ALB_ARN = aws elbv2 create-load-balancer `
    --name my-alb `
    --subnets $SUBNET_A $SUBNET_B `
    --security-groups $ALB_SG `
    --scheme internet-facing `
    --type application `
    --ip-address-type ipv4 `
    --query "LoadBalancers[0].LoadBalancerArn" `
    --output text

Write-Host "  ALB ARN: $ALB_ARN" -ForegroundColor Green

# ── GET DNS NAME ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/3] Getting ALB DNS name..." -ForegroundColor Yellow

$ALB_DNS = aws elbv2 describe-load-balancers `
    --load-balancer-arns $ALB_ARN `
    --query "LoadBalancers[0].DNSName" `
    --output text

Write-Host "  ALB DNS: $ALB_DNS" -ForegroundColor Green

# ── CREATE HTTP LISTENER ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Creating HTTP listener (port 80 → target group)..." -ForegroundColor Yellow

$LISTENER_ARN = aws elbv2 create-listener `
    --load-balancer-arn $ALB_ARN `
    --protocol HTTP `
    --port 80 `
    --default-actions "Type=forward,TargetGroupArn=$TG_ARN" `
    --query "Listeners[0].ListenerArn" `
    --output text

Write-Host "  Listener ARN: $LISTENER_ARN" -ForegroundColor Green

# ── WAIT FOR ALB TO BE ACTIVE ─────────────────────────────────────────────────
Write-Host ""
Write-Host "Waiting for ALB to become active (2-3 minutes)..." -ForegroundColor Yellow
aws elbv2 wait load-balancer-available --load-balancer-arns $ALB_ARN
Write-Host "  ALB is active!" -ForegroundColor Green

# ── SUMMARY ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== ALB Complete ===" -ForegroundColor Cyan
Write-Host "  Name:      my-alb"
Write-Host "  Scheme:    internet-facing"
Write-Host "  Type:      application"
Write-Host "  Listener:  HTTP:80 → web-server-tg"
Write-Host ""
Write-Host "  URL: http://$ALB_DNS" -ForegroundColor Green
Write-Host ""
Write-Host "  The ALB is active but has no targets yet." -ForegroundColor Yellow
Write-Host "  ASG will register instances in the next step." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run 07-create-auto-scaling-group.ps1" -ForegroundColor Cyan
