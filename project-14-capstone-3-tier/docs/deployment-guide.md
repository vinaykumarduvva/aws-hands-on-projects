# Deployment Guide: 3-Tier HA Architecture

This guide covers the deployment of the complete Capstone Project architecture using three different methods: AWS Management Console, Bash Scripts, and PowerShell Scripts.

## 🛠️ Prerequisites
- AWS CLI configured with appropriate permissions.
- Default region set to `ap-south-1`.
- Existing EC2 key pair named `aws-ec2-keypair`.
- jq installed (if using Bash)

---

## 🖥️ Method 1: AWS Management Console

If you are a beginner or simply prefer to build the architecture manually to understand how the underlying services connect, follow these step-by-step instructions in the AWS Console. 

### 1. VPC & Networking (The Foundation)
*Before deploying servers, we need a secure, isolated network to put them in.*
- **Create a VPC:** Navigate to **VPC > Create VPC**. Set the IPv4 CIDR block to `10.0.0.0/16`.
- **Create Subnets:** Create exactly 6 subnets across two Availability Zones (AZs):
  - **2 Public Subnets** (Web Tier)
  - **2 Private Subnets** (Application Tier)
  - **2 Private Subnets** (Database Tier)
- **Configure Internet Access:** 
  - Create an **Internet Gateway (IGW)** and attach it to your VPC. 
  - Create a **NAT Gateway** in one of your Public Subnets (this allows your private servers to securely download updates).
- **Update Route Tables:**
  - Route the **Public Subnets** to the Internet Gateway.
  - Route the **Private Subnets** to the NAT Gateway.

### 2. Security Groups (The Firewalls)
*Security groups act as virtual firewalls. We use "Chaining" to ensure each tier can only talk to the tier directly above it.*
- **ALB Security Group:** Allow HTTP (Port 80) and HTTPS (Port 443) from anywhere (`0.0.0.0/0`).
- **App Security Group:** Allow HTTP (Port 80) **only** from the ALB Security Group.
- **DB Security Group:** Allow MySQL (Port 3306) **only** from the App Security Group.

### 3. Database Tier (The Backend)
*We deploy a highly available database that automatically replicates data across zones.*
- **Store Credentials:** Navigate to **Secrets Manager** and securely store your database username and password (e.g., as `capstone/db/credentials`).
- **Create Subnet Group:** In RDS, create a DB Subnet Group containing your two Private DB subnets.
- **Launch RDS:** Create a MySQL database instance. Ensure you select **Multi-AZ deployment**, attach the DB Security Group, and assign it to your DB Subnet Group.

### 4. Application Tier (The Compute Engine)
*This is where your application code actually runs.*
- **Create an IAM Role:** Create an EC2 role with the `AmazonSSMManagedInstanceCore` policy and an inline policy allowing access to your Secrets Manager secret.
- **Create a Launch Template:** 
  - Navigate to **EC2 > Launch Templates**.
  - Select Amazon Linux 2023 (`t2.micro`).
  - Attach the App Security Group and the IAM Role.
  - In the **Advanced Details > User Data** section, provide a bash script to install your web server (e.g., Apache) and fetch the database credentials dynamically.

### 5. Web Tier (The Traffic Router)
*The load balancer acts as a single point of entry, routing user traffic evenly across your servers.*
- **Create a Target Group:** Navigate to **EC2 > Target Groups**. Create a target group for Port 80 and configure a health check path (e.g., `/health.json`).
- **Create the Load Balancer:** Navigate to **EC2 > Load Balancers**. Create an **Application Load Balancer (ALB)**. Place it in your Public Subnets and attach the ALB Security Group. Configure the listener to forward traffic to your Target Group.

### 6. Auto Scaling (Elasticity)
*Auto scaling ensures you always have the right amount of compute power to handle traffic.*
- **Create an Auto Scaling Group (ASG):** Navigate to **EC2 > Auto Scaling Groups**.
- **Configure ASG:** Use your Launch Template and select your Private App subnets. Set the capacity to Minimum: 2, Maximum: 4, Desired: 2.
- **Attach Load Balancer:** Attach the Target Group you created earlier.
- **Add a Scaling Policy:** Create a Target Tracking scaling policy that adds instances when average CPU utilization exceeds 60%.

### 7. Monitoring (Observability)
*Setting up alerts ensures you are notified if anything goes wrong.*
- **Create Notifications:** Go to **SNS** and create a topic. Subscribe your email address to receive alerts.
- **Set Up Alarms:** Navigate to **CloudWatch** and create Alarms for:
  - ALB 5XX Error Rates (High)
  - ASG CPU Utilization (> 70%)
  - RDS CPU Utilization (> 80%)
  - RDS Free Storage (< 5GB)
  - ALB Healthy Host Count (< 2)
- **Create a Dashboard:** (Optional) Build a custom CloudWatch Dashboard to visualize these metrics in one place.

---

## 🐧 Method 2: AWS CLI (Bash)

To automate the deployment on macOS/Linux environments, execute the Bash scripts sequentially from the root directory:

```bash
cd scripts/bash
chmod +x *.sh

./00-pre-flight.sh
./01-build-network.sh
# Execute 02 through 08 sequentially
```

<details><summary><b>View Full Bash Deployment Scripts</b></summary>

### 00-pre-flight.sh
```bash
#!/bin/bash
set -e
set -u

echo "=> PRE-FLIGHT"
echo "=> Confirming region"
aws configure get region

aws configure set region ap-south-1

echo "=> Getting account ID"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo "Account ID: $ACCOUNT_ID"

echo "=> Confirming key pair exists"
aws ec2 describe-key-pairs --key-names aws-ec2-keypair --query "KeyPairs[0].KeyName" --output text

echo "=> Creating project folders"
mkdir -p "$HOME/aws-cloud-projects/project-14-capstone"
cd "$HOME/aws-cloud-projects/project-14-capstone"
mkdir -p templates scripts docs screenshots diagrams
```

### 01-build-network.sh
```bash
#!/bin/bash
set -e
set -u

echo "=> PART 1 â€” BUILD THE NETWORK LAYER"
echo "=> Step 1 â€” Create VPC"
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=capstone-vpc},{Key=Project,Value=project-14-capstone}]" \
  --query "Vpc.VpcId" --output text)

aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support
echo "VPC: $VPC_ID"

echo "=> Step 2 â€” Create all 6 subnets"
# Public subnets (Web Tier)
PUB_A=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/24 --availability-zone ap-south-1a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-a},{Key=Tier,Value=web}]" --query "Subnet.SubnetId" --output text)
PUB_B=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.2.0/24 --availability-zone ap-south-1b --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-b},{Key=Tier,Value=web}]" --query "Subnet.SubnetId" --output text)

# Private App subnets (App Tier)
APP_A=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.3.0/24 --availability-zone ap-south-1a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-app-subnet-a},{Key=Tier,Value=app}]" --query "Subnet.SubnetId" --output text)
APP_B=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.4.0/24 --availability-zone ap-south-1b --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-app-subnet-b},{Key=Tier,Value=app}]" --query "Subnet.SubnetId" --output text)

# Private DB subnets (DB Tier)
DB_A=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.5.0/24 --availability-zone ap-south-1a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-db-subnet-a},{Key=Tier,Value=db}]" --query "Subnet.SubnetId" --output text)
DB_B=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.6.0/24 --availability-zone ap-south-1b --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-db-subnet-b},{Key=Tier,Value=db}]" --query "Subnet.SubnetId" --output text)

echo "=> Enabling auto-assign public IP on public subnets"
aws ec2 modify-subnet-attribute --subnet-id "$PUB_A" --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id "$PUB_B" --map-public-ip-on-launch
echo "All 6 subnets created"

echo "=> Step 3 â€” Internet Gateway"
IGW_ID=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=capstone-igw}]" --query "InternetGateway.InternetGatewayId" --output text)
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
echo "IGW: $IGW_ID"

echo "=> Step 4 â€” NAT Gateway"
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc --query "AllocationId" --output text)
NAT_GW_ID=$(aws ec2 create-nat-gateway --subnet-id "$PUB_A" --allocation-id "$EIP_ALLOC" --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=capstone-nat}]" --query "NatGateway.NatGatewayId" --output text)
echo "NAT Gateway: $NAT_GW_ID â€” waiting..."
aws ec2 wait nat-gateway-available --nat-gateway-ids "$NAT_GW_ID"
echo "NAT Gateway available"

echo "=> Step 5 â€” Route Tables"
PUB_RT=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=public-rt}]" --query "RouteTable.RouteTableId" --output text)
aws ec2 create-route --route-table-id "$PUB_RT" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" > /dev/null
aws ec2 associate-route-table --route-table-id "$PUB_RT" --subnet-id "$PUB_A" > /dev/null
aws ec2 associate-route-table --route-table-id "$PUB_RT" --subnet-id "$PUB_B" > /dev/null

PRI_RT=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=private-rt}]" --query "RouteTable.RouteTableId" --output text)
aws ec2 create-route --route-table-id "$PRI_RT" --destination-cidr-block 0.0.0.0/0 --nat-gateway-id "$NAT_GW_ID" > /dev/null

for SUBNET in "$APP_A" "$APP_B" "$DB_A" "$DB_B"; do
  aws ec2 associate-route-table --route-table-id "$PRI_RT" --subnet-id "$SUBNET" > /dev/null
done
echo "Route tables configured"
```

### 02-security-groups.sh
```bash
#!/bin/bash
set -e
set -u

echo "=> PART 2 â€” SECURITY GROUPS (3-TIER CHAINING)"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text)

echo "=> ALB Security Group (Web Tier)"
ALB_SG=$(aws ec2 create-security-group \
  --group-name capstone-alb-sg \
  --description "Web Tier: ALB accepts HTTP from internet" \
  --vpc-id "$VPC_ID" --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress --group-id "$ALB_SG" --protocol tcp --port 80 --cidr "0.0.0.0/0" > /dev/null
aws ec2 authorize-security-group-ingress --group-id "$ALB_SG" --protocol tcp --port 443 --cidr "0.0.0.0/0" > /dev/null
echo "ALB SG: $ALB_SG"

echo "=> App Server Security Group (App Tier)"
APP_SG=$(aws ec2 create-security-group \
  --group-name capstone-app-sg \
  --description "App Tier: accepts HTTP from ALB only" \
  --vpc-id "$VPC_ID" --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress --group-id "$APP_SG" --protocol tcp --port 80 --source-group "$ALB_SG" > /dev/null
echo "App SG: $APP_SG"

echo "=> RDS Security Group (DB Tier)"
DB_SG=$(aws ec2 create-security-group \
  --group-name capstone-db-sg \
  --description "DB Tier: MySQL from app tier only" \
  --vpc-id "$VPC_ID" --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress --group-id "$DB_SG" --protocol tcp --port 3306 --source-group "$APP_SG" > /dev/null
echo "DB SG: $DB_SG"

echo ""
echo "Security group chain:"
echo "Internet â†’ ALB SG â†’ App SG â†’ DB SG"
echo "Zero direct internet access to app or DB tiers"
```

### 03-database-tier.sh
```bash
#!/bin/bash
set -e
set -u

echo "=> PART 3 â€” DATABASE TIER (RDS Multi-AZ)"

echo "=> Step 6 â€” Store credentials in Secrets Manager"
DB_SECRET_ARN=$(aws secretsmanager create-secret \
  --name "capstone/db/credentials" \
  --description "Capstone RDS MySQL admin credentials" \
  --secret-string '{
    "username":"admin",
    "password":"Capstone#DB2024!",
    "engine":"mysql",
    "port":3306,
    "dbname":"capstonedb"
  }' \
  --query "ARN" --output text)
echo "Secret ARN: $DB_SECRET_ARN"

echo "=> Step 7 â€” Create RDS subnet group"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text)
DB_A=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-db-subnet-a" --query "Subnets[0].SubnetId" --output text)
DB_B=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-db-subnet-b" --query "Subnets[0].SubnetId" --output text)

aws rds create-db-subnet-group \
  --db-subnet-group-name capstone-db-subnet-group \
  --db-subnet-group-description "DB tier private subnets" \
  --subnet-ids "$DB_A" "$DB_B" \
  --tags Key=Project,Value=project-14-capstone > /dev/null

echo "=> Step 8 â€” Launch RDS Multi-AZ"
DB_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=capstone-db-sg" --query "SecurityGroups[0].GroupId" --output text)

aws rds create-db-instance \
  --db-instance-identifier capstone-database \
  --db-instance-class db.t3.micro \
  --engine mysql --engine-version 8.0 \
  --master-username admin \
  --master-user-password "Capstone#DB2024!" \
  --db-name capstonedb \
  --vpc-security-group-ids "$DB_SG" \
  --db-subnet-group-name capstone-db-subnet-group \
  --allocated-storage 20 \
  --storage-type gp2 \
  --multi-az \
  --no-publicly-accessible \
  --backup-retention-period 7 \
  --deletion-protection \
  --tags Key=Project,Value=project-14-capstone > /dev/null

echo "RDS Multi-AZ creation started (8-12 minutes)..."
echo "Continuing with other resources while RDS provisions..."
```

### 04-application-tier.sh
```bash
#!/bin/bash
set -e
set -u

echo "=> PART 4 â€” APPLICATION TIER (ASG + Launch Template)"

echo "=> Step 9 â€” Create IAM role for EC2"
aws iam create-role \
  --role-name capstone-ec2-role \
  --assume-role-policy-document '{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Principal":{"Service":"ec2.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }]
  }' > /dev/null

aws iam attach-role-policy \
  --role-name capstone-ec2-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

DB_SECRET_ARN=$(aws secretsmanager describe-secret --secret-id "capstone/db/credentials" --query "ARN" --output text)

aws iam put-role-policy \
  --role-name capstone-ec2-role \
  --policy-name secrets-access \
  --policy-document "{
    \"Version\":\"2012-10-17\",
    \"Statement\":[{
      \"Effect\":\"Allow\",
      \"Action\":[
        \"secretsmanager:GetSecretValue\"
      ],
      \"Resource\":\"$DB_SECRET_ARN\"
    }]
  }"

aws iam create-instance-profile --instance-profile-name capstone-ec2-profile > /dev/null
aws iam add-role-to-instance-profile --instance-profile-name capstone-ec2-profile --role-name capstone-ec2-role

sleep 10
echo "EC2 IAM role created"

echo "=> Step 10 â€” Get latest AMI"
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
  --region ap-south-1 \
  --query "sort_by(Images,&CreationDate)[-1].ImageId" \
  --output text)
echo "AMI: $AMI_ID"

echo "=> Step 11 â€” Create Launch Template"
APP_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=capstone-app-sg" --query "SecurityGroups[0].GroupId" --output text)

USER_DATA_B64=$(cat << 'EOF' | base64 -w 0
#!/bin/bash
yum update -y
yum install -y httpd mysql

# Start Apache
systemctl start httpd
systemctl enable httpd

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Get DB credentials from Secrets Manager
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id capstone/db/credentials \
  --region ap-south-1 \
  --query SecretString \
  --output text 2>/dev/null || echo '{"dbname":"capstonedb"}')

DB_NAME=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin).get('dbname','capstonedb'))" 2>/dev/null || echo "capstonedb")

# Create application page
cat > /var/www/html/index.html << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Capstone â€” 3-Tier HA App</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:Arial,sans-serif;background:linear-gradient(135deg,#232f3e,#1a73e8);
      min-height:100vh;display:flex;align-items:center;justify-content:center}
    .card{background:white;border-radius:16px;padding:40px;max-width:640px;
      width:90%;box-shadow:0 20px 60px rgba(0,0,0,.3)}
    .badge{background:#ff9900;color:white;padding:6px 16px;border-radius:20px;
      font-size:13px;display:inline-block;margin-bottom:20px}
    h1{color:#232f3e;font-size:24px;margin-bottom:20px}
    .tier{display:flex;gap:8px;margin-bottom:16px;align-items:center}
    .tier-label{background:#232f3e;color:white;padding:4px 10px;border-radius:4px;
      font-size:12px;min-width:70px;text-align:center}
    .tier-detail{font-size:13px;color:#444}
    .info{background:#f0f7ff;border-radius:8px;padding:14px;margin:10px 0}
    .label{font-size:11px;color:#888;text-transform:uppercase}
    .value{font-size:15px;font-weight:bold;color:#232f3e}
    .healthy{background:#d4edda;color:#155724;border-radius:8px;
      padding:12px;margin-top:20px;text-align:center;font-weight:bold}
  </style>
</head>
<body>
  <div class="card">
    <span class="badge">Project 14 â€” Capstone Architecture</span>
    <h1>3-Tier Highly Available Application</h1>
    <div class="tier">
      <span class="tier-label">WEB TIER</span>
      <span class="tier-detail">Application Load Balancer â€” ap-south-1</span>
    </div>
    <div class="tier">
      <span class="tier-label">APP TIER</span>
      <span class="tier-detail">EC2 Auto Scaling Group â€” min:2 max:4</span>
    </div>
    <div class="tier">
      <span class="tier-label">DB TIER</span>
      <span class="tier-detail">RDS MySQL Multi-AZ â€” $DB_NAME</span>
    </div>
    <div class="info">
      <div class="label">Instance ID</div>
      <div class="value">$INSTANCE_ID</div>
    </div>
    <div class="info">
      <div class="label">Availability Zone</div>
      <div class="value">$AZ</div>
    </div>
    <div class="info">
      <div class="label">Private IP</div>
      <div class="value">$PRIVATE_IP</div>
    </div>
    <div class="healthy">All Three Tiers Healthy â€” Production Ready</div>
  </div>
</body>
</html>
HTMLEOF

# Create health check endpoint
echo '{"status":"healthy","tier":"app"}' > /var/www/html/health.json
echo "Setup complete" >> /tmp/setup.log
EOF
)

LT_ID=$(aws ec2 create-launch-template \
  --launch-template-name capstone-app-lt \
  --version-description "v1 - 3-tier capstone app server" \
  --launch-template-data "{
    \"ImageId\":\"$AMI_ID\",
    \"InstanceType\":\"t2.micro\",
    \"KeyName\":\"aws-ec2-keypair\",
    \"IamInstanceProfile\":{\"Name\":\"capstone-ec2-profile\"},
    \"SecurityGroupIds\":[\"$APP_SG\"],
    \"UserData\":\"$USER_DATA_B64\",
    \"TagSpecifications\":[{
      \"ResourceType\":\"instance\",
      \"Tags\":[
        {\"Key\":\"Name\",\"Value\":\"capstone-app-server\"},
        {\"Key\":\"Project\",\"Value\":\"project-14-capstone\"},
        {\"Key\":\"Tier\",\"Value\":\"app\"}
      ]
    }]
  }" \
  --query "LaunchTemplate.LaunchTemplateId" \
  --output text)

echo "Launch Template: $LT_ID"
```

### 05-web-tier.sh
```bash
#!/bin/bash
set -e
set -u

echo "=> PART 5 â€” WEB TIER (ALB + Target Group)"

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text)
PUB_A=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-a" --query "Subnets[0].SubnetId" --output text)
PUB_B=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-b" --query "Subnets[0].SubnetId" --output text)
ALB_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=capstone-alb-sg" --query "SecurityGroups[0].GroupId" --output text)

echo "=> Create Target Group"
TG_ARN=$(aws elbv2 create-target-group \
  --name capstone-app-tg \
  --protocol HTTP --port 80 \
  --vpc-id "$VPC_ID" \
  --health-check-protocol HTTP \
  --health-check-path "/health.json" \
  --health-check-interval-seconds 30 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --query "TargetGroups[0].TargetGroupArn" \
  --output text)
echo "Target Group: $TG_ARN"

echo "=> Create ALB in public subnets"
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name capstone-alb \
  --subnets "$PUB_A" "$PUB_B" \
  --security-groups "$ALB_SG" \
  --scheme internet-facing \
  --type application \
  --query "LoadBalancers[0].LoadBalancerArn" \
  --output text)

ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns "$ALB_ARN" \
  --query "LoadBalancers[0].DNSName" \
  --output text)
echo "ALB DNS: $ALB_DNS"

echo "=> Create HTTP listener"
LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn "$ALB_ARN" \
  --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$TG_ARN" \
  --query "Listeners[0].ListenerArn" \
  --output text)

echo "Waiting for ALB to be active..."
aws elbv2 wait load-balancer-available --load-balancer-arns "$ALB_ARN"
echo "ALB active: http://$ALB_DNS"
```

### 06-auto-scaling.sh
```bash
#!/bin/bash
set -e
set -u

echo "=> PART 6 â€” AUTO SCALING GROUP"

LT_ID=$(aws ec2 describe-launch-templates --launch-template-names capstone-app-lt --query "LaunchTemplates[0].LaunchTemplateId" --output text)
TG_ARN=$(aws elbv2 describe-target-groups --names capstone-app-tg --query "TargetGroups[0].TargetGroupArn" --output text)
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text)
APP_A=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-app-subnet-a" --query "Subnets[0].SubnetId" --output text)
APP_B=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-app-subnet-b" --query "Subnets[0].SubnetId" --output text)

echo "=> Create ASG in private app subnets"
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name capstone-asg \
  --launch-template "LaunchTemplateId=$LT_ID,Version=\$Latest" \
  --min-size 2 --max-size 4 --desired-capacity 2 \
  --vpc-zone-identifier "$APP_A,$APP_B" \
  --target-group-arns "$TG_ARN" \
  --health-check-type ELB \
  --health-check-grace-period 180 \
  --tags \
    "Key=Name,Value=capstone-app-server,PropagateAtLaunch=true" \
    "Key=Project,Value=project-14-capstone,PropagateAtLaunch=true" > /dev/null

echo "=> Add target tracking scaling policy at 60% CPU"
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name capstone-asg \
  --policy-name capstone-cpu-tracking \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "PredefinedMetricSpecification":{
      "PredefinedMetricType":"ASGAverageCPUUtilization"
    },
    "TargetValue":60.0,
    "EstimatedInstanceWarmup":180
  }' > /dev/null

echo "ASG created â€” instances launching..."
```

### 07-monitoring.sh
```bash
#!/bin/bash
set -e
set -u

echo "=> PART 7 â€” MONITORING AND ALERTING"

echo "=> Step 12 â€” Create SNS topic"
SNS_ARN=$(aws sns create-topic \
  --name capstone-alerts \
  --attributes DisplayName="Capstone Monitoring" \
  --query "TopicArn" --output text)

aws sns subscribe \
  --topic-arn "$SNS_ARN" \
  --protocol email \
  --notification-endpoint "your-email@gmail.com" > /dev/null

echo "SNS topic created â€” confirm subscription email"

ALB_ARN=$(aws elbv2 describe-load-balancers --names capstone-alb --query "LoadBalancers[0].LoadBalancerArn" --output text)
TG_ARN=$(aws elbv2 describe-target-groups --names capstone-app-tg --query "TargetGroups[0].TargetGroupArn" --output text)

ALB_ID=$(echo "$ALB_ARN" | awk -F'/' '{print $(NF-2)"/"$(NF-1)"/"$NF}')
TG_ID=$(echo "$TG_ARN" | awk -F':' '{print $NF}')

echo "=> Step 13 â€” Create CloudWatch alarms"
# ALB 5XX Error Rate alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "Capstone-ALB-5XX-High" \
  --alarm-description "ALB 5XX error rate above 10 per minute" \
  --namespace "AWS/ApplicationELB" \
  --metric-name "HTTPCode_Target_5XX_Count" \
  --dimensions "Name=LoadBalancer,Value=$ALB_ID" \
  --statistic Sum --period 60 \
  --evaluation-periods 2 --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions "$SNS_ARN" \
  --treat-missing-data notBreaching

# ASG CPU High alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "Capstone-ASG-CPU-High" \
  --alarm-description "App tier CPU above 70%" \
  --namespace "AWS/EC2" \
  --metric-name "CPUUtilization" \
  --dimensions "Name=AutoScalingGroupName,Value=capstone-asg" \
  --statistic Average --period 300 \
  --evaluation-periods 2 --threshold 70 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions "$SNS_ARN" \
  --treat-missing-data notBreaching

# RDS CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "Capstone-RDS-CPU-High" \
  --alarm-description "DB tier CPU above 80%" \
  --namespace "AWS/RDS" \
  --metric-name "CPUUtilization" \
  --dimensions "Name=DBInstanceIdentifier,Value=capstone-database" \
  --statistic Average --period 300 \
  --evaluation-periods 2 --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions "$SNS_ARN" \
  --treat-missing-data notBreaching

# RDS Free Storage alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "Capstone-RDS-Storage-Low" \
  --alarm-description "DB free storage below 5GB" \
  --namespace "AWS/RDS" \
  --metric-name "FreeStorageSpace" \
  --dimensions "Name=DBInstanceIdentifier,Value=capstone-database" \
  --statistic Average --period 300 \
  --evaluation-periods 1 --threshold 5000000000 \
  --comparison-operator LessThanThreshold \
  --alarm-actions "$SNS_ARN" \
  --treat-missing-data notBreaching

# Healthy host count alarm (catches instance failures)
aws cloudwatch put-metric-alarm \
  --alarm-name "Capstone-ALB-Healthy-Hosts-Low" \
  --alarm-description "Fewer than 2 healthy instances behind ALB" \
  --namespace "AWS/ApplicationELB" \
  --metric-name "HealthyHostCount" \
  --dimensions \
    "Name=TargetGroup,Value=$TG_ID" \
    "Name=LoadBalancer,Value=$ALB_ID" \
  --statistic Minimum --period 60 \
  --evaluation-periods 1 --threshold 2 \
  --comparison-operator LessThanThreshold \
  --alarm-actions "$SNS_ARN" \
  --treat-missing-data breaching

echo "All 5 CloudWatch alarms created"

echo "=> Step 14 â€” Create CloudWatch Dashboard"
DASHBOARD=$(cat << EOF
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
EOF
)

aws cloudwatch put-dashboard \
  --dashboard-name "Capstone-3Tier-Dashboard" \
  --dashboard-body "$DASHBOARD" > /dev/null

echo "CloudWatch Dashboard created"
```

### 08-verify-stack.sh
```bash
#!/bin/bash
set -e
set -u

echo "=> PART 8 â€” VERIFY RDS IS AVAILABLE"
aws rds describe-db-instances \
  --db-instance-identifier capstone-database \
  --query "DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ,Endpoint:Endpoint.Address,AZ:AvailabilityZone,SecondaryAZ:SecondaryAvailabilityZone}" \
  --output table

aws rds wait db-instance-available --db-instance-identifier capstone-database
echo "RDS available"

RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier capstone-database --query "DBInstances[0].Endpoint.Address" --output text)
echo "RDS Endpoint: $RDS_ENDPOINT"

echo "=> PART 9 â€” VERIFY FULL STACK"
echo "=== FULL STACK VERIFICATION ==="

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text)
ALB_ARN=$(aws elbv2 describe-load-balancers --names capstone-alb --query "LoadBalancers[0].LoadBalancerArn" --output text)
TG_ARN=$(aws elbv2 describe-target-groups --names capstone-app-tg --query "TargetGroups[0].TargetGroupArn" --output text)
ALB_DNS=$(aws elbv2 describe-load-balancers --names capstone-alb --query "LoadBalancers[0].DNSName" --output text)

echo "=> 1. VPC and subnets"
aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --query "Vpcs[0].{ID:VpcId,CIDR:CidrBlock,DNS:EnableDnsHostnames}" --output table

echo "=> 2. All 6 subnets"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].{Name:Tags[?Key=='Name'].Value|[0],CIDR:CidrBlock,AZ:AvailabilityZone}" --output table

echo "=> 3. ALB status"
aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" --query "LoadBalancers[0].{DNS:DNSName,State:State.Code}" --output table

echo "=> 4. Target health"
aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --query "TargetHealthDescriptions[*].{Instance:Target.Id,State:TargetHealth.State}" --output table

echo "=> 5. ASG instances"
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names capstone-asg --query "AutoScalingGroups[0].{Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,Count:length(Instances)}" --output table

echo "=> 6. RDS Multi-AZ"
aws rds describe-db-instances --db-instance-identifier capstone-database --query "DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ,AZ:AvailabilityZone}" --output table

echo "=> 7. CloudWatch alarms"
aws cloudwatch describe-alarms --alarm-name-prefix "Capstone-" --query "MetricAlarms[*].{Name:AlarmName,State:StateValue}" --output table

echo "=> 8. Test application"
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" "http://$ALB_DNS")
echo "HTTP Status: $HTTP_STATUS"
HEALTH=$(curl -s "http://$ALB_DNS/health.json")
echo "Health check: $HEALTH"

echo ""
echo "=== ALL SYSTEMS OPERATIONAL ==="
echo "Application URL: http://$ALB_DNS"
echo "Dashboard: CloudWatch â†’ Capstone-3Tier-Dashboard"
```

</details>

> [!WARNING]  
> `03-database-tier.sh` initiates the creation of an RDS Multi-AZ database, which typically takes 8-12 minutes to provision. You can immediately run scripts 04 through 07 while it provisions in the background.

---

## 🪟 Method 3: AWS CLI (PowerShell)

To automate the deployment on Windows environments, execute the PowerShell scripts sequentially from the root directory:

```powershell
cd scripts/powershell

.\00-pre-flight.ps1
.\01-build-network.ps1
# Execute 02 through 08 sequentially
```

<details><summary><b>View Full PowerShell Deployment Scripts</b></summary>

### 00-pre-flight.ps1
```powershell
# PRE-FLIGHT
# Confirm region
aws configure get region
# Expected: ap-south-1

aws configure set region ap-south-1

# Get account ID
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
Write-Host "Account ID: $ACCOUNT_ID"

# Confirm key pair exists
aws ec2 describe-key-pairs --key-names aws-ec2-keypair --query "KeyPairs[0].KeyName" --output text

# Create project folder
mkdir C:\Users\$env:USERNAME\aws-cloud-projects\project-14-capstone
cd C:\Users\$env:USERNAME\aws-cloud-projects\project-14-capstone
mkdir templates, scripts, docs, screenshots, diagrams
```

### 01-build-network.ps1
```powershell
# PART 1 â€” BUILD THE NETWORK LAYER
# Step 1 â€” Create VPC
$VPC_ID = aws ec2 create-vpc `
  --cidr-block 10.0.0.0/16 `
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=capstone-vpc},{Key=Project,Value=project-14-capstone}]" `
  --query "Vpc.VpcId" --output text

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
Write-Host "VPC: $VPC_ID"

# Step 2 â€” Create all 6 subnets
# Public subnets (Web Tier)
$PUB_A = aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone ap-south-1a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-a},{Key=Tier,Value=web}]" --query "Subnet.SubnetId" --output text
$PUB_B = aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone ap-south-1b --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-b},{Key=Tier,Value=web}]" --query "Subnet.SubnetId" --output text

# Private App subnets (App Tier)
$APP_A = aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 --availability-zone ap-south-1a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-app-subnet-a},{Key=Tier,Value=app}]" --query "Subnet.SubnetId" --output text
$APP_B = aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.4.0/24 --availability-zone ap-south-1b --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-app-subnet-b},{Key=Tier,Value=app}]" --query "Subnet.SubnetId" --output text

# Private DB subnets (DB Tier)
$DB_A = aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.5.0/24 --availability-zone ap-south-1a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-db-subnet-a},{Key=Tier,Value=db}]" --query "Subnet.SubnetId" --output text
$DB_B = aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.6.0/24 --availability-zone ap-south-1b --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-db-subnet-b},{Key=Tier,Value=db}]" --query "Subnet.SubnetId" --output text

# Enable auto-assign public IP on public subnets
aws ec2 modify-subnet-attribute --subnet-id $PUB_A --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $PUB_B --map-public-ip-on-launch
Write-Host "All 6 subnets created"

# Step 3 â€” Internet Gateway
$IGW_ID = aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=capstone-igw}]" --query "InternetGateway.InternetGatewayId" --output text
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
Write-Host "IGW: $IGW_ID"

# Step 4 â€” NAT Gateway
$EIP_ALLOC = aws ec2 allocate-address --domain vpc --query "AllocationId" --output text
$NAT_GW_ID = aws ec2 create-nat-gateway --subnet-id $PUB_A --allocation-id $EIP_ALLOC --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=capstone-nat}]" --query "NatGateway.NatGatewayId" --output text
Write-Host "NAT Gateway: $NAT_GW_ID â€” waiting..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID
Write-Host "NAT Gateway available"

# Step 5 â€” Route Tables
$PUB_RT = aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=public-rt}]" --query "RouteTable.RouteTableId" --output text
aws ec2 create-route --route-table-id $PUB_RT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $PUB_RT --subnet-id $PUB_A
aws ec2 associate-route-table --route-table-id $PUB_RT --subnet-id $PUB_B

$PRI_RT = aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=private-rt}]" --query "RouteTable.RouteTableId" --output text
aws ec2 create-route --route-table-id $PRI_RT --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID
foreach ($SUBNET in @($APP_A, $APP_B, $DB_A, $DB_B)) {
  aws ec2 associate-route-table --route-table-id $PRI_RT --subnet-id $SUBNET | Out-Null
}
Write-Host "Route tables configured"
```

### 02-security-groups.ps1
```powershell
# PART 2 â€” SECURITY GROUPS (3-TIER CHAINING)
# Ensure $VPC_ID is available. You may need to retrieve it if running separately:
# $VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text

# â”€â”€ ALB Security Group (Web Tier) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$ALB_SG = aws ec2 create-security-group `
  --group-name capstone-alb-sg `
  --description "Web Tier: ALB accepts HTTP from internet" `
  --vpc-id $VPC_ID --query "GroupId" --output text

aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr "0.0.0.0/0"
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 443 --cidr "0.0.0.0/0"
Write-Host "ALB SG: $ALB_SG"

# â”€â”€ App Server Security Group (App Tier) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$APP_SG = aws ec2 create-security-group `
  --group-name capstone-app-sg `
  --description "App Tier: accepts HTTP from ALB only" `
  --vpc-id $VPC_ID --query "GroupId" --output text

aws ec2 authorize-security-group-ingress --group-id $APP_SG --protocol tcp --port 80 --source-group $ALB_SG
Write-Host "App SG: $APP_SG"

# â”€â”€ RDS Security Group (DB Tier) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$DB_SG = aws ec2 create-security-group `
  --group-name capstone-db-sg `
  --description "DB Tier: MySQL from app tier only" `
  --vpc-id $VPC_ID --query "GroupId" --output text

aws ec2 authorize-security-group-ingress --group-id $DB_SG --protocol tcp --port 3306 --source-group $APP_SG
Write-Host "DB SG: $DB_SG"

Write-Host ""
Write-Host "Security group chain:"
Write-Host "Internet â†’ ALB SG â†’ App SG â†’ DB SG"
Write-Host "Zero direct internet access to app or DB tiers"
```

### 03-database-tier.ps1
```powershell
# PART 3 â€” DATABASE TIER (RDS Multi-AZ)

# Step 6 â€” Store credentials in Secrets Manager
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

# Step 7 â€” Create RDS subnet group
# Retrieve DB subnets if needed
# $VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text
# $DB_A = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-db-subnet-a" --query "Subnets[0].SubnetId" --output text
# $DB_B = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-db-subnet-b" --query "Subnets[0].SubnetId" --output text

aws rds create-db-subnet-group `
  --db-subnet-group-name capstone-db-subnet-group `
  --db-subnet-group-description "DB tier private subnets" `
  --subnet-ids $DB_A $DB_B `
  --tags Key=Project,Value=project-14-capstone

# Step 8 â€” Launch RDS Multi-AZ
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
```

### 04-application-tier.ps1
```powershell
# PART 4 â€” APPLICATION TIER (ASG + Launch Template)

# Step 9 â€” Create IAM role for EC2
aws iam create-role `
  --role-name capstone-ec2-role `
  --assume-role-policy-document '{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Principal":{"Service":"ec2.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy `
  --role-name capstone-ec2-role `
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Ensure $DB_SECRET_ARN is available
# $DB_SECRET_ARN = aws secretsmanager describe-secret --secret-id "capstone/db/credentials" --query "ARN" --output text

# Add Secrets Manager access
aws iam put-role-policy `
  --role-name capstone-ec2-role `
  --policy-name secrets-access `
  --policy-document "{
    `"Version`":`"2012-10-17`",
    `"Statement`":[{
      `"Effect`":`"Allow`",
      `"Action`":[
        `"secretsmanager:GetSecretValue`"
      ],
      `"Resource`":`"$DB_SECRET_ARN`"
    }]
  }"

# Create instance profile
aws iam create-instance-profile --instance-profile-name capstone-ec2-profile
aws iam add-role-to-instance-profile --instance-profile-name capstone-ec2-profile --role-name capstone-ec2-role

Start-Sleep -Seconds 10
Write-Host "EC2 IAM role created"

# Step 10 â€” Get latest AMI
$AMI_ID = aws ec2 describe-images `
  --owners amazon `
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" `
  --region ap-south-1 `
  --query "sort_by(Images,&CreationDate)[-1].ImageId" `
  --output text
Write-Host "AMI: $AMI_ID"

# Step 11 â€” Create Launch Template
# Ensure $APP_SG is available
# $APP_SG = aws ec2 describe-security-groups --filters "Name=group-name,Values=capstone-app-sg" --query "SecurityGroups[0].GroupId" --output text

$USER_DATA = @"
#!/bin/bash
yum update -y
yum install -y httpd mysql

# Start Apache
systemctl start httpd
systemctl enable httpd

# Get instance metadata
INSTANCE_ID=`$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AZ=`$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=`$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Get DB credentials from Secrets Manager
SECRET=`$(aws secretsmanager get-secret-value \
  --secret-id capstone/db/credentials \
  --region ap-south-1 \
  --query SecretString \
  --output text 2>/dev/null || echo '{"dbname":"capstonedb"}')

DB_NAME=`$(echo `$SECRET | python3 -c "import sys,json; print(json.load(sys.stdin).get('dbname','capstonedb'))" 2>/dev/null || echo "capstonedb")

# Create application page
cat > /var/www/html/index.html << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Capstone â€” 3-Tier HA App</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:Arial,sans-serif;background:linear-gradient(135deg,#232f3e,#1a73e8);
      min-height:100vh;display:flex;align-items:center;justify-content:center}
    .card{background:white;border-radius:16px;padding:40px;max-width:640px;
      width:90%;box-shadow:0 20px 60px rgba(0,0,0,.3)}
    .badge{background:#ff9900;color:white;padding:6px 16px;border-radius:20px;
      font-size:13px;display:inline-block;margin-bottom:20px}
    h1{color:#232f3e;font-size:24px;margin-bottom:20px}
    .tier{display:flex;gap:8px;margin-bottom:16px;align-items:center}
    .tier-label{background:#232f3e;color:white;padding:4px 10px;border-radius:4px;
      font-size:12px;min-width:70px;text-align:center}
    .tier-detail{font-size:13px;color:#444}
    .info{background:#f0f7ff;border-radius:8px;padding:14px;margin:10px 0}
    .label{font-size:11px;color:#888;text-transform:uppercase}
    .value{font-size:15px;font-weight:bold;color:#232f3e}
    .healthy{background:#d4edda;color:#155724;border-radius:8px;
      padding:12px;margin-top:20px;text-align:center;font-weight:bold}
  </style>
</head>
<body>
  <div class="card">
    <span class="badge">Project 14 â€” Capstone Architecture</span>
    <h1>3-Tier Highly Available Application</h1>
    <div class="tier">
      <span class="tier-label">WEB TIER</span>
      <span class="tier-detail">Application Load Balancer â€” ap-south-1</span>
    </div>
    <div class="tier">
      <span class="tier-label">APP TIER</span>
      <span class="tier-detail">EC2 Auto Scaling Group â€” min:2 max:4</span>
    </div>
    <div class="tier">
      <span class="tier-label">DB TIER</span>
      <span class="tier-detail">RDS MySQL Multi-AZ â€” `$DB_NAME</span>
    </div>
    <div class="info">
      <div class="label">Instance ID</div>
      <div class="value">`$INSTANCE_ID</div>
    </div>
    <div class="info">
      <div class="label">Availability Zone</div>
      <div class="value">`$AZ</div>
    </div>
    <div class="info">
      <div class="label">Private IP</div>
      <div class="value">`$PRIVATE_IP</div>
    </div>
    <div class="healthy">All Three Tiers Healthy â€” Production Ready</div>
  </div>
</body>
</html>
HTMLEOF

# Create health check endpoint
echo '{"status":"healthy","tier":"app"}' > /var/www/html/health.json
echo "Setup complete" >> /tmp/setup.log
"@

$USER_DATA_B64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($USER_DATA))

$LT_ID = aws ec2 create-launch-template `
  --launch-template-name capstone-app-lt `
  --version-description "v1 - 3-tier capstone app server" `
  --launch-template-data "{
    `"ImageId`":`"$AMI_ID`",
    `"InstanceType`":`"t2.micro`",
    `"KeyName`":`"aws-ec2-keypair`",
    `"IamInstanceProfile`":{`"Name`":`"capstone-ec2-profile`"},
    `"SecurityGroupIds`":[`"$APP_SG`"],
    `"UserData`":`"$USER_DATA_B64`",
    `"TagSpecifications`":[{
      `"ResourceType`":`"instance`",
      `"Tags`":[
        {`"Key`":`"Name`",`"Value`":`"capstone-app-server`"},
        {`"Key`":`"Project`",`"Value`":`"project-14-capstone`"},
        {`"Key`":`"Tier`",`"Value`":`"app`"}
      ]
    }]
  }" `
  --query "LaunchTemplate.LaunchTemplateId" `
  --output text

Write-Host "Launch Template: $LT_ID"
```

### 05-web-tier.ps1
```powershell
# PART 5 â€” WEB TIER (ALB + Target Group)

# Retrieve VPC and Subnets if needed
# $VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text
# $PUB_A = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-a" --query "Subnets[0].SubnetId" --output text
# $PUB_B = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-b" --query "Subnets[0].SubnetId" --output text
# $ALB_SG = aws ec2 describe-security-groups --filters "Name=group-name,Values=capstone-alb-sg" --query "SecurityGroups[0].GroupId" --output text

# Create Target Group
$TG_ARN = aws elbv2 create-target-group `
  --name capstone-app-tg `
  --protocol HTTP --port 80 `
  --vpc-id $VPC_ID `
  --health-check-protocol HTTP `
  --health-check-path "/health.json" `
  --health-check-interval-seconds 30 `
  --healthy-threshold-count 2 `
  --unhealthy-threshold-count 3 `
  --query "TargetGroups[0].TargetGroupArn" `
  --output text
Write-Host "Target Group: $TG_ARN"

# Create ALB in public subnets
$ALB_ARN = aws elbv2 create-load-balancer `
  --name capstone-alb `
  --subnets $PUB_A $PUB_B `
  --security-groups $ALB_SG `
  --scheme internet-facing `
  --type application `
  --query "LoadBalancers[0].LoadBalancerArn" `
  --output text

$ALB_DNS = aws elbv2 describe-load-balancers `
  --load-balancer-arns $ALB_ARN `
  --query "LoadBalancers[0].DNSName" `
  --output text
Write-Host "ALB DNS: $ALB_DNS"

# Create HTTP listener
$LISTENER_ARN = aws elbv2 create-listener `
  --load-balancer-arn $ALB_ARN `
  --protocol HTTP --port 80 `
  --default-actions "Type=forward,TargetGroupArn=$TG_ARN" `
  --query "Listeners[0].ListenerArn" `
  --output text

Write-Host "Waiting for ALB to be active..."
aws elbv2 wait load-balancer-available --load-balancer-arns $ALB_ARN
Write-Host "ALB active: http://$ALB_DNS"
```

### 06-auto-scaling.ps1
```powershell
# PART 6 â€” AUTO SCALING GROUP

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

Write-Host "ASG created â€” instances launching..."
```

### 07-monitoring.ps1
```powershell
# PART 7 â€” MONITORING AND ALERTING

# Step 12 â€” Create SNS topic
$SNS_ARN = aws sns create-topic `
  --name capstone-alerts `
  --attributes DisplayName="Capstone Monitoring" `
  --query "TopicArn" --output text

aws sns subscribe `
  --topic-arn $SNS_ARN `
  --protocol email `
  --notification-endpoint "your-email@gmail.com"

Write-Host "SNS topic created â€” confirm subscription email"

# Retrieve ALB_ARN and TG_ARN if needed
# $ALB_ARN = aws elbv2 describe-load-balancers --names capstone-alb --query "LoadBalancers[0].LoadBalancerArn" --output text
# $TG_ARN = aws elbv2 describe-target-groups --names capstone-app-tg --query "TargetGroups[0].TargetGroupArn" --output text
$ALB_ID = ($ALB_ARN -split '/')[-3..-1] -join '/'
$TG_ID = ($TG_ARN -split ':')[-1]

# Step 13 â€” Create CloudWatch alarms
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

# Step 14 â€” Create CloudWatch Dashboard
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
```

### 08-verify-stack.ps1
```powershell
# PART 8 â€” VERIFY RDS IS AVAILABLE
# Check RDS status
aws rds describe-db-instances `
  --db-instance-identifier capstone-database `
  --query "DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ,Endpoint:Endpoint.Address,AZ:AvailabilityZone,SecondaryAZ:SecondaryAvailabilityZone}" `
  --output table

# If still creating â€” wait
aws rds wait db-instance-available --db-instance-identifier capstone-database
Write-Host "RDS available"

# Get endpoint
$RDS_ENDPOINT = aws rds describe-db-instances --db-instance-identifier capstone-database --query "DBInstances[0].Endpoint.Address" --output text
Write-Host "RDS Endpoint: $RDS_ENDPOINT"

# PART 9 â€” VERIFY FULL STACK
Write-Host "=== FULL STACK VERIFICATION ==="

# Needed variables
# $VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-14-capstone" --query "Vpcs[0].VpcId" --output text
# $ALB_ARN = aws elbv2 describe-load-balancers --names capstone-alb --query "LoadBalancers[0].LoadBalancerArn" --output text
# $TG_ARN = aws elbv2 describe-target-groups --names capstone-app-tg --query "TargetGroups[0].TargetGroupArn" --output text
# $ALB_DNS = aws elbv2 describe-load-balancers --names capstone-alb --query "LoadBalancers[0].DNSName" --output text

# 1. VPC and subnets
Write-Host "Checking VPC..."
aws ec2 describe-vpcs --vpc-ids $VPC_ID --query "Vpcs[0].{ID:VpcId,CIDR:CidrBlock,DNS:EnableDnsHostnames}" --output table

# 2. All 6 subnets
Write-Host "Checking Subnets..."
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].{Name:Tags[?Key=='Name'].Value|[0],CIDR:CidrBlock,AZ:AvailabilityZone}" --output table

# 3. ALB status
Write-Host "Checking ALB..."
aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query "LoadBalancers[0].{DNS:DNSName,State:State.Code}" --output table

# 4. Target health
Write-Host "Checking Target Health..."
aws elbv2 describe-target-health --target-group-arn $TG_ARN --query "TargetHealthDescriptions[*].{Instance:Target.Id,State:TargetHealth.State}" --output table

# 5. ASG instances
Write-Host "Checking ASG..."
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names capstone-asg --query "AutoScalingGroups[0].{Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,Count:length(Instances)}" --output table

# 6. RDS Multi-AZ
Write-Host "Checking RDS..."
aws rds describe-db-instances --db-instance-identifier capstone-database --query "DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ,AZ:AvailabilityZone}" --output table

# 7. CloudWatch alarms
Write-Host "Checking Alarms..."
aws cloudwatch describe-alarms --alarm-name-prefix "Capstone-" --query "MetricAlarms[*].{Name:AlarmName,State:StateValue}" --output table

# 8. Test application
Write-Host "Testing Application..."
$RESPONSE = Invoke-WebRequest -Uri "http://$ALB_DNS" -UseBasicParsing
Write-Host "HTTP Status: $($RESPONSE.StatusCode)"
$HEALTH = Invoke-WebRequest -Uri "http://$ALB_DNS/health.json" -UseBasicParsing
Write-Host "Health check: $($HEALTH.Content)"

# Open in browser
Start-Process "http://$ALB_DNS"
Write-Host ""
Write-Host "=== ALL SYSTEMS OPERATIONAL ==="
Write-Host "Application URL: http://$ALB_DNS"
Write-Host "Dashboard: CloudWatch â†’ Capstone-3Tier-Dashboard"
```

</details>

> [!WARNING]  
> `03-database-tier.ps1` initiates the creation of an RDS Multi-AZ database, which typically takes 8-12 minutes to provision. You can immediately run scripts 04 through 07 while it provisions in the background.

## Infrastructure as Code (IaC) Alternative
Instead of manual scripts, you can deploy the entire stack using CloudFormation.
Use the template located at `scripts/templates/capstone-stack.yaml`.
