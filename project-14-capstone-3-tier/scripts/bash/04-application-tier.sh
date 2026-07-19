#!/bin/bash
set -e
set -u

echo "=> PART 4 - APPLICATION TIER (ASG + Launch Template)"

echo "=> Step 9 - Create IAM role for EC2"
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

echo "=> Step 10 - Get latest AMI"
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
  --region ap-south-1 \
  --query "sort_by(Images,&CreationDate)[-1].ImageId" \
  --output text)
echo "AMI: $AMI_ID"

echo "=> Step 11 - Create Launch Template"
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
  <title>Capstone - 3-Tier HA App</title>
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
    <span class="badge">Project 14 - Capstone Architecture</span>
    <h1>3-Tier Highly Available Application</h1>
    <div class="tier">
      <span class="tier-label">WEB TIER</span>
      <span class="tier-detail">Application Load Balancer - ap-south-1</span>
    </div>
    <div class="tier">
      <span class="tier-label">APP TIER</span>
      <span class="tier-detail">EC2 Auto Scaling Group - min:2 max:4</span>
    </div>
    <div class="tier">
      <span class="tier-label">DB TIER</span>
      <span class="tier-detail">RDS MySQL Multi-AZ - $DB_NAME</span>
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
    <div class="healthy">All Three Tiers Healthy - Production Ready</div>
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
