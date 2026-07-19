# PART 2 - SECURITY GROUPS (3-TIER CHAINING)
# Ensure $VPC_ID is available. You may need to retrieve it if running separately:
# $VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text

# ── ALB Security Group (Web Tier) ─────────────────────────────
$ALB_SG = aws ec2 create-security-group `
  --group-name capstone-alb-sg `
  --description "Web Tier: ALB accepts HTTP from internet" `
  --vpc-id $VPC_ID --query "GroupId" --output text

aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr "0.0.0.0/0"
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 443 --cidr "0.0.0.0/0"
Write-Host "ALB SG: $ALB_SG"

# ── App Server Security Group (App Tier) ──────────────────────
$APP_SG = aws ec2 create-security-group `
  --group-name capstone-app-sg `
  --description "App Tier: accepts HTTP from ALB only" `
  --vpc-id $VPC_ID --query "GroupId" --output text

aws ec2 authorize-security-group-ingress --group-id $APP_SG --protocol tcp --port 80 --source-group $ALB_SG
Write-Host "App SG: $APP_SG"

# ── RDS Security Group (DB Tier) ──────────────────────────────
$DB_SG = aws ec2 create-security-group `
  --group-name capstone-db-sg `
  --description "DB Tier: MySQL from app tier only" `
  --vpc-id $VPC_ID --query "GroupId" --output text

aws ec2 authorize-security-group-ingress --group-id $DB_SG --protocol tcp --port 3306 --source-group $APP_SG
Write-Host "DB SG: $DB_SG"

Write-Host ""
Write-Host "Security group chain:"
Write-Host "Internet -> ALB SG -> App SG -> DB SG"
Write-Host "Zero direct internet access to app or DB tiers"
