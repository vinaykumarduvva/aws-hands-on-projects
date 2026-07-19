# PART 3 - DATABASE TIER (RDS Multi-AZ)

# Step 6 - Store credentials in Secrets Manager
$DB_SECRET_ARN = aws secretsmanager create-secret `
  --name "capstone/db/credentials" `
  --description "Capstone RDS MySQL admin credentials" `
  --secret-string '{
    "username":"admin",
    "password":"Capstone#DB2024!",
    "engine":"mysql",
    "port":3306,
    "dbname":"capstonedb"
  }' `
  --query "ARN" --output text
Write-Host "Secret ARN: $DB_SECRET_ARN"

# Step 7 - Create RDS subnet group
# Retrieve DB subnets if needed
# $VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text
# $DB_A = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-db-subnet-a" --query "Subnets[0].SubnetId" --output text
# $DB_B = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-db-subnet-b" --query "Subnets[0].SubnetId" --output text

aws rds create-db-subnet-group `
  --db-subnet-group-name capstone-db-subnet-group `
  --db-subnet-group-description "DB tier private subnets" `
  --subnet-ids $DB_A $DB_B `
  --tags Key=Project,Value=project-14-capstone

# Step 8 - Launch RDS Multi-AZ
# Retrieve DB SG if needed
# $DB_SG = aws ec2 describe-security-groups --filters "Name=group-name,Values=capstone-db-sg" --query "SecurityGroups[0].GroupId" --output text

aws rds create-db-instance `
  --db-instance-identifier capstone-database `
  --db-instance-class db.t3.micro `
  --engine mysql --engine-version 8.0 `
  --master-username admin `
  --master-user-password "Capstone#DB2024!" `
  --db-name capstonedb `
  --vpc-security-group-ids $DB_SG `
  --db-subnet-group-name capstone-db-subnet-group `
  --allocated-storage 20 `
  --storage-type gp2 `
  --multi-az `
  --no-publicly-accessible `
  --backup-retention-period 7 `
  --deletion-protection `
  --tags Key=Project,Value=project-14-capstone

Write-Host "RDS Multi-AZ creation started (8-12 minutes)..."
Write-Host "Continuing with other resources while RDS provisions..."
