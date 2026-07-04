import os

# Project 3
p3_dir = r"e:\AWS Hands-on Projects\project-03-Launch-EC2-Connect-via-SSH\scripts"
os.makedirs(p3_dir, exist_ok=True)

with open(os.path.join(p3_dir, "02-create-security-group.ps1"), "w") as f:
    f.write("""$VPC_ID = aws ec2 describe-vpcs `
  --filters "Name=isDefault,Values=true" `
  --query "Vpcs[0].VpcId" --output text

$MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" `
  -UseBasicParsing).Content.Trim()

$SG_ID = aws ec2 create-security-group `
  --group-name ec2-web-sg `
  --description "Allow SSH and HTTP access" `
  --vpc-id $VPC_ID `
  --query "GroupId" --output text

aws ec2 authorize-security-group-ingress `
  --group-id $SG_ID --protocol tcp --port 22 --cidr "$MY_IP/32"

aws ec2 authorize-security-group-ingress `
  --group-id $SG_ID --protocol tcp --port 80 --cidr "0.0.0.0/0"
Write-Host -ForegroundColor Green "Created SG: $SG_ID"
""")

with open(os.path.join(p3_dir, "03-launch-instance.ps1"), "w") as f:
    f.write("""$SG_ID = aws ec2 describe-security-groups --group-names ec2-web-sg --query "SecurityGroups[0].GroupId" --output text
$AMI_ID = aws ec2 describe-images `
  --owners amazon `
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" `
  --query "sort_by(Images,&CreationDate)[-1].ImageId" --output text

$INSTANCE_ID = aws ec2 run-instances `
  --image-id $AMI_ID `
  --instance-type t2.micro `
  --key-name aws-ec2-keypair `
  --security-group-ids $SG_ID `
  --associate-public-ip-address `
  --user-data file://scripts/userdata.sh `
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=my-first-ec2}]" `
  --query "Instances[0].InstanceId" --output text

aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID

$PUBLIC_IP = aws ec2 describe-instances `
  --instance-ids $INSTANCE_ID `
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text

Write-Host -ForegroundColor Green "Instance ready at: http://$PUBLIC_IP"
""")

with open(os.path.join(p3_dir, "04-connect-ssm.ps1"), "w") as f:
    f.write("""aws iam create-role `
  --role-name ec2-ssm-role `
  --assume-role-policy-document '{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Principal":{"Service":"ec2.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy `
  --role-name ec2-ssm-role `
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

aws iam create-instance-profile --instance-profile-name ec2-ssm-profile
aws iam add-role-to-instance-profile `
  --instance-profile-name ec2-ssm-profile --role-name ec2-ssm-role

$INSTANCE_ID = aws ec2 describe-instances --filters "Name=tag:Name,Values=my-first-ec2" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text

aws ec2 associate-iam-instance-profile `
  --instance-id $INSTANCE_ID `
  --iam-instance-profile Name=ec2-ssm-profile

Write-Host -ForegroundColor Green "SSM Role created and attached. It takes a few minutes for SSM agent to register."
Write-Host "Connect with: aws ssm start-session --target $INSTANCE_ID"
""")

with open(os.path.join(p3_dir, "05-cleanup.ps1"), "w") as f:
    f.write("""$INSTANCE_ID = aws ec2 describe-instances --filters "Name=tag:Name,Values=my-first-ec2" --query "Reservations[0].Instances[0].InstanceId" --output text
$SG_ID = aws ec2 describe-security-groups --group-names ec2-web-sg --query "SecurityGroups[0].GroupId" --output text

aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
aws ec2 delete-security-group --group-id $SG_ID
aws ec2 delete-key-pair --key-name aws-ec2-keypair

aws iam remove-role-from-instance-profile `
  --instance-profile-name ec2-ssm-profile --role-name ec2-ssm-role
aws iam detach-role-policy `
  --role-name ec2-ssm-role `
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam delete-instance-profile --instance-profile-name ec2-ssm-profile
aws iam delete-role --role-name ec2-ssm-role

Write-Host -ForegroundColor Green "Cleanup complete"
""")

# Project 4
p4_dir = r"e:\AWS Hands-on Projects\project-04-s3-versioning\scripts"
os.makedirs(p4_dir, exist_ok=True)

with open(os.path.join(p4_dir, "01-create-source-bucket.ps1"), "w") as f:
    f.write("""$SOURCE_BUCKET = "s3-versioning-lab-yourname"
$SOURCE_REGION = "ap-south-1"

aws s3api create-bucket `
  --bucket $SOURCE_BUCKET `
  --region $SOURCE_REGION `
  --create-bucket-configuration LocationConstraint=$SOURCE_REGION

aws s3api put-bucket-versioning `
  --bucket $SOURCE_BUCKET `
  --versioning-configuration Status=Enabled

$status = aws s3api get-bucket-versioning --bucket $SOURCE_BUCKET | ConvertFrom-Json
Write-Host -ForegroundColor Green "Created Source Bucket with Versioning: $($status.Status)"
""")

with open(os.path.join(p4_dir, "02-test-versioning.ps1"), "w") as f:
    f.write("""$SOURCE_BUCKET = "s3-versioning-lab-yourname"
"Version 1 - original content. Created: $(Get-Date)" | Out-File -FilePath "document.txt" -Encoding utf8
aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt
"Version 2 - updated content. Updated: $(Get-Date)" | Out-File -FilePath "document.txt" -Encoding utf8
aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt
"Version 3 - final content. Finalized: $(Get-Date)" | Out-File -FilePath "document.txt" -Encoding utf8
aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt

aws s3api list-object-versions `
  --bucket $SOURCE_BUCKET --prefix document.txt `
  --query "Versions[*].{VersionId:VersionId,IsLatest:IsLatest}" `
  --output table

Write-Host -ForegroundColor Green "Versioning tested. Three versions uploaded."
""")

with open(os.path.join(p4_dir, "03-create-lifecycle-policy.ps1"), "w") as f:
    f.write("""$SOURCE_BUCKET = "s3-versioning-lab-yourname"

aws s3api put-bucket-lifecycle-configuration `
  --bucket $SOURCE_BUCKET `
  --lifecycle-configuration file://scripts/lifecycle-policy.json

Write-Host -ForegroundColor Green "Applied lifecycle policy."
""")

with open(os.path.join(p4_dir, "04-cross-region-replication.ps1"), "w") as f:
    f.write("""$SOURCE_BUCKET = "s3-versioning-lab-yourname"
$DEST_BUCKET   = "s3-versioning-lab-yourname-replica"
$DEST_REGION   = "ap-south-2"

aws s3api create-bucket `
  --bucket $DEST_BUCKET `
  --region $DEST_REGION `
  --create-bucket-configuration LocationConstraint=$DEST_REGION

aws s3api put-bucket-versioning `
  --bucket $DEST_BUCKET `
  --versioning-configuration Status=Enabled

aws iam create-role `
  --role-name s3-replication-role `
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "s3.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam put-role-policy `
  --role-name s3-replication-role `
  --policy-name s3-replication-permissions `
  --policy-document file://scripts/replication-policy.json

$ROLE_ARN = aws iam get-role `
  --role-name s3-replication-role `
  --query "Role.Arn" --output text

Start-Sleep -Seconds 10

aws s3api put-bucket-replication `
  --bucket $SOURCE_BUCKET `
  --replication-configuration "{
    `"Role`": `"$ROLE_ARN`",
    `"Rules`": [{
      `"ID`": `"replicate-to-ap-south-2`",
      `"Status`": `"Enabled`",
      `"Filter`": {`"Prefix`":`"`"},
      `"Destination`": {
        `"Bucket`": `"arn:aws:s3:::$DEST_BUCKET`",
        `"StorageClass`": `"STANDARD`"
      },
      `"DeleteMarkerReplication`": {
        `"Status`": `"Enabled`"
      }
    }]
  }"
  
Write-Host -ForegroundColor Green "Cross-Region Replication Setup Complete"
""")

with open(os.path.join(p4_dir, "05-test-replication.ps1"), "w") as f:
    f.write("""$SOURCE_BUCKET = "s3-versioning-lab-yourname"
$DEST_BUCKET   = "s3-versioning-lab-yourname-replica"
$DEST_REGION   = "ap-south-2"

"CRR Test — uploaded $(Get-Date)" | Out-File -FilePath "crr-test.txt" -Encoding utf8
aws s3 cp crr-test.txt s3://$SOURCE_BUCKET/crr-test.txt
Write-Host "Uploaded. Waiting 30 seconds for replication..."
Start-Sleep -Seconds 30

aws s3api head-object `
  --bucket $DEST_BUCKET `
  --key crr-test.txt `
  --region $DEST_REGION

aws s3 ls s3://$DEST_BUCKET --region $DEST_REGION

Write-Host -ForegroundColor Green "Test replication complete"
""")

with open(os.path.join(p4_dir, "06-cleanup.ps1"), "w") as f:
    f.write("""$SOURCE_BUCKET = "s3-versioning-lab-yourname"
$DEST_BUCKET   = "s3-versioning-lab-yourname-replica"
$SOURCE_REGION = "ap-south-1"
$DEST_REGION   = "ap-south-2"

$ALL_VERSIONS = aws s3api list-object-versions `
  --bucket $SOURCE_BUCKET | ConvertFrom-Json

foreach ($v in $ALL_VERSIONS.Versions) {
  aws s3api delete-object `
    --bucket $SOURCE_BUCKET `
    --key $v.Key `
    --version-id $v.VersionId | Out-Null
}

foreach ($m in $ALL_VERSIONS.DeleteMarkers) {
  aws s3api delete-object `
    --bucket $SOURCE_BUCKET `
    --key $m.Key `
    --version-id $m.VersionId | Out-Null
}

aws s3api delete-bucket --bucket $SOURCE_BUCKET --region $SOURCE_REGION

$DEST_VERSIONS = aws s3api list-object-versions `
  --bucket $DEST_BUCKET --region $DEST_REGION | ConvertFrom-Json

foreach ($v in $DEST_VERSIONS.Versions) {
  aws s3api delete-object `
    --bucket $DEST_BUCKET `
    --key $v.Key `
    --version-id $v.VersionId `
    --region $DEST_REGION | Out-Null
}
foreach ($m in $DEST_VERSIONS.DeleteMarkers) {
  aws s3api delete-object `
    --bucket $DEST_BUCKET `
    --key $m.Key `
    --version-id $m.VersionId `
    --region $DEST_REGION | Out-Null
}

aws s3api delete-bucket --bucket $DEST_BUCKET --region $DEST_REGION

aws iam delete-role-policy `
  --role-name s3-replication-role `
  --policy-name s3-replication-permissions
aws iam delete-role --role-name s3-replication-role

Write-Host -ForegroundColor Green "Project 4 cleanup complete"
""")

# Project 5
p5_dir = r"e:\AWS Hands-on Projects\project-05-Custom-VPC\scripts"
os.makedirs(p5_dir, exist_ok=True)

with open(os.path.join(p5_dir, "01-create-vpc.ps1"), "w") as f:
    f.write("""$VPC_ID = aws ec2 create-vpc `
  --cidr-block 10.0.0.0/16 `
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=my-custom-vpc}]" `
  --query "Vpc.VpcId" --output text

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

$PUB_SUBNET_A = aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 `
  --availability-zone us-east-1a `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-a}]" `
  --query "Subnet.SubnetId" --output text

$PUB_SUBNET_B = aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 `
  --availability-zone us-east-1b `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-b}]" `
  --query "Subnet.SubnetId" --output text

$PRI_SUBNET_A = aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 `
  --availability-zone us-east-1a `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-a}]" `
  --query "Subnet.SubnetId" --output text

$PRI_SUBNET_B = aws ec2 create-subnet `
  --vpc-id $VPC_ID --cidr-block 10.0.4.0/24 `
  --availability-zone us-east-1b `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-b}]" `
  --query "Subnet.SubnetId" --output text

aws ec2 modify-subnet-attribute --subnet-id $PUB_SUBNET_A --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $PUB_SUBNET_B --map-public-ip-on-launch

Write-Host -ForegroundColor Green "VPC and Subnets created. VPC ID: $VPC_ID"
""")

with open(os.path.join(p5_dir, "02-create-route-tables.ps1"), "w") as f:
    f.write("""$VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Name,Values=my-custom-vpc" --query "Vpcs[0].VpcId" --output text
$PUB_SUBNET_A = aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-subnet-a" --query "Subnets[0].SubnetId" --output text
$PUB_SUBNET_B = aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-subnet-b" --query "Subnets[0].SubnetId" --output text
$PRI_SUBNET_A = aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-subnet-a" --query "Subnets[0].SubnetId" --output text
$PRI_SUBNET_B = aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-subnet-b" --query "Subnets[0].SubnetId" --output text

$IGW_ID = aws ec2 create-internet-gateway `
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-vpc-igw}]" `
  --query "InternetGateway.InternetGatewayId" --output text

aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

$PUB_RT_ID = aws ec2 create-route-table `
  --vpc-id $VPC_ID `
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=public-route-table}]" `
  --query "RouteTable.RouteTableId" --output text

aws ec2 create-route `
  --route-table-id $PUB_RT_ID `
  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

aws ec2 associate-route-table --route-table-id $PUB_RT_ID --subnet-id $PUB_SUBNET_A
aws ec2 associate-route-table --route-table-id $PUB_RT_ID --subnet-id $PUB_SUBNET_B

$PRI_RT_ID = aws ec2 create-route-table `
  --vpc-id $VPC_ID `
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=private-route-table}]" `
  --query "RouteTable.RouteTableId" --output text

aws ec2 associate-route-table --route-table-id $PRI_RT_ID --subnet-id $PRI_SUBNET_A
aws ec2 associate-route-table --route-table-id $PRI_RT_ID --subnet-id $PRI_SUBNET_B

Write-Host -ForegroundColor Green "Internet Gateway and Route Tables created."
""")

with open(os.path.join(p5_dir, "03-create-nat-gateway.ps1"), "w") as f:
    f.write("""$PUB_SUBNET_A = aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-subnet-a" --query "Subnets[0].SubnetId" --output text
$PRI_RT_ID = aws ec2 describe-route-tables --filters "Name=tag:Name,Values=private-route-table" --query "RouteTables[0].RouteTableId" --output text

$EIP_ALLOC = aws ec2 allocate-address `
  --domain vpc --query "AllocationId" --output text

$NAT_GW_ID = aws ec2 create-nat-gateway `
  --subnet-id $PUB_SUBNET_A `
  --allocation-id $EIP_ALLOC `
  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=my-nat-gateway}]" `
  --query "NatGateway.NatGatewayId" --output text

Write-Host "Waiting for NAT Gateway to become available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

aws ec2 create-route `
  --route-table-id $PRI_RT_ID `
  --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID

Write-Host -ForegroundColor Green "NAT Gateway created and configured."
""")

with open(os.path.join(p5_dir, "04-create-security-groups.ps1"), "w") as f:
    f.write("""$VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Name,Values=my-custom-vpc" --query "Vpcs[0].VpcId" --output text

$MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" `
  -UseBasicParsing).Content.Trim()

$BASTION_SG = aws ec2 create-security-group `
  --group-name bastion-sg `
  --description "Allow SSH from my IP only" `
  --vpc-id $VPC_ID --query "GroupId" --output text

aws ec2 authorize-security-group-ingress `
  --group-id $BASTION_SG --protocol tcp --port 22 --cidr "$MY_IP/32"

$PRIVATE_SG = aws ec2 create-security-group `
  --group-name private-sg `
  --description "Allow SSH from bastion only" `
  --vpc-id $VPC_ID --query "GroupId" --output text

aws ec2 authorize-security-group-ingress `
  --group-id $PRIVATE_SG --protocol tcp --port 22 `
  --source-group $BASTION_SG

Write-Host -ForegroundColor Green "Security groups bastion-sg and private-sg created."
""")

with open(os.path.join(p5_dir, "05-launch-instances.ps1"), "w") as f:
    f.write("""$VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Name,Values=my-custom-vpc" --query "Vpcs[0].VpcId" --output text
$PUB_SUBNET_A = aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-subnet-a" --query "Subnets[0].SubnetId" --output text
$PRI_SUBNET_A = aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-subnet-a" --query "Subnets[0].SubnetId" --output text
$BASTION_SG = aws ec2 describe-security-groups --filters "Name=group-name,Values=bastion-sg" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text
$PRIVATE_SG = aws ec2 describe-security-groups --filters "Name=group-name,Values=private-sg" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text

$AMI_ID = aws ec2 describe-images --owners amazon `
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" `
  --query "sort_by(Images,&CreationDate)[-1].ImageId" --output text

$BASTION_ID = aws ec2 run-instances `
  --image-id $AMI_ID --instance-type t2.micro `
  --key-name aws-ec2-keypair --subnet-id $PUB_SUBNET_A `
  --security-group-ids $BASTION_SG --associate-public-ip-address `
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=bastion-host}]" `
  --query "Instances[0].InstanceId" --output text

$PRIVATE_ID = aws ec2 run-instances `
  --image-id $AMI_ID --instance-type t2.micro `
  --key-name aws-ec2-keypair --subnet-id $PRI_SUBNET_A `
  --security-group-ids $PRIVATE_SG --no-associate-public-ip-address `
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=private-instance}]" `
  --query "Instances[0].InstanceId" --output text

Write-Host "Waiting for instances to be running..."
aws ec2 wait instance-running --instance-ids $BASTION_ID $PRIVATE_ID
Write-Host -ForegroundColor Green "Instances running: $BASTION_ID, $PRIVATE_ID"
""")

print("Successfully wrote all scripts.")
