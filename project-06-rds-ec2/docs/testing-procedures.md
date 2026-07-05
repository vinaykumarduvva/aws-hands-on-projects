# Testing Procedures — RDS MySQL + EC2 Two-Tier Application

## Test Matrix

| # | Test | Expected Result | Checkpoint |
|:--|:-----|:----------------|:-----------|
| 1 | VPC exists with correct CIDR | `10.0.0.0/16`, DNS hostnames enabled | Part 1 |
| 2 | All 4 subnets created | Public (auto-assign IP), Private (no public IP) | Part 1 |
| 3 | Security groups configured | `ec2-app-sg` + `rds-sg` with chained rules | Part 2 |
| 4 | RDS subnet group spans 2 AZs | Status: `Complete`, both private subnets listed | Part 3 |
| 5 | Secret stored in Secrets Manager | `rds/myapp/credentials` retrievable | Part 4 |
| 6 | RDS instance available | Status: `available`, endpoint resolvable | Part 5 |
| 7 | EC2 serving status page | HTTP 200 at public IP | Part 6 |
| 8 | EC2 connects to RDS MySQL | `mysql` prompt accessible, queries succeed | Part 7 |
| 9 | CloudWatch metrics available | CPU, connections, storage data returned | Part 8 |
| 10 | Cleanup completes cleanly | All resources deleted, no orphans | Part 10 |

---

## Test 1 — VPC Verification

```powershell
# Verify VPC exists with correct CIDR and DNS settings
aws ec2 describe-vpcs --vpc-ids $VPC_ID `
  --query "Vpcs[0].{CIDR:CidrBlock,DnsHostnames:EnableDnsHostnames,DnsSupport:EnableDnsSupport}" `
  --output table
# Expected: CIDR=10.0.0.0/16, DnsHostnames=True, DnsSupport=True
```

```bash
# Bash equivalent
aws ec2 describe-vpcs --vpc-ids "$VPC_ID" \
  --query "Vpcs[0].{CIDR:CidrBlock}" --output text
# Expected: 10.0.0.0/16
```

---

## Test 2 — Subnet Verification

```powershell
# List all subnets in VPC
aws ec2 describe-subnets `
  --filters "Name=vpc-id,Values=$VPC_ID" `
  --query "Subnets[*].{Name:Tags[?Key=='Name']|[0].Value,CIDR:CidrBlock,AZ:AvailabilityZone,PublicIP:MapPublicIpOnLaunch}" `
  --output table
# Expected: 4 subnets with correct CIDRs, public subnets have PublicIP=True
```

---

## Test 3 — Security Group Rules Verification

```powershell
# Verify ec2-app-sg inbound rules
aws ec2 describe-security-groups --group-ids $EC2_SG `
  --query "SecurityGroups[0].IpPermissions[*].{Port:FromPort,Protocol:IpProtocol,Source:IpRanges[0].CidrIp}" `
  --output table
# Expected: Port 22 from YOUR_IP/32, Port 80 from 0.0.0.0/0

# Verify rds-sg references ec2-app-sg (not CIDR)
aws ec2 describe-security-groups --group-ids $RDS_SG `
  --query "SecurityGroups[0].IpPermissions[*].{Port:FromPort,SourceSG:UserIdGroupPairs[0].GroupId}" `
  --output table
# Expected: Port 3306 with SourceSG = ec2-app-sg ID
```

---

## Test 4 — RDS Subnet Group Verification

```powershell
aws rds describe-db-subnet-groups `
  --db-subnet-group-name rds-subnet-group `
  --query "DBSubnetGroups[0].{Status:SubnetGroupStatus,Subnets:Subnets[*].SubnetIdentifier}" `
  --output table
# Expected: Status=Complete, both private subnet IDs listed
```

---

## Test 5 — Secrets Manager Verification

```powershell
# Verify secret exists and is retrievable
aws secretsmanager describe-secret `
  --secret-id "rds/myapp/credentials" `
  --query "{Name:Name,ARN:ARN}" `
  --output table
# Expected: Name=rds/myapp/credentials

# Verify secret value (careful — prints password)
aws secretsmanager get-secret-value `
  --secret-id "rds/myapp/credentials" `
  --query "SecretString" --output text
# Expected: JSON with username, password, engine, port, dbname
```

---

## Test 6 — RDS Instance Verification

```powershell
aws rds describe-db-instances `
  --db-instance-identifier myapp-database `
  --query "DBInstances[0].{Status:DBInstanceStatus,Engine:Engine,Class:DBInstanceClass,Endpoint:Endpoint.Address,Public:PubliclyAccessible}" `
  --output table
# Expected: Status=available, Engine=mysql, Class=db.t3.micro, Public=False
```

---

## Test 7 — EC2 Web Server Verification

```powershell
# Get public IP
$APP_PUBLIC_IP = aws ec2 describe-instances `
  --instance-ids $APP_INSTANCE_ID `
  --query "Reservations[0].Instances[0].PublicIpAddress" `
  --output text

# Test HTTP (from PowerShell)
Invoke-WebRequest -Uri "http://$APP_PUBLIC_IP" -UseBasicParsing | Select-Object StatusCode
# Expected: StatusCode=200
```

```bash
# Test HTTP (from Bash)
curl -s -o /dev/null -w "%{http_code}" http://$APP_PUBLIC_IP
# Expected: 200
```

---

## Test 8 — EC2 to RDS Connectivity

SSH into EC2, then run:

```bash
# Verify MySQL client installed
mysql --version
# Expected: mysql  Ver 8.0.x

# Connect to RDS
mysql -h YOUR_RDS_ENDPOINT -P 3306 -u admin -p
# Enter password: MyDB#Secure2024!
# Expected: MySQL monitor prompt

# Once connected, verify RDS
SELECT @@hostname;
# Expected: RDS instance identifier (not localhost)

SELECT VERSION();
# Expected: 8.0.x

USE appdb;
SELECT * FROM users;
# Expected: 3 rows (if table was created)

EXIT;
```

---

## Test 9 — CloudWatch Metrics Verification

```powershell
# CPU utilization should be near 0% for idle instance
aws cloudwatch get-metric-statistics `
  --namespace AWS/RDS `
  --metric-name CPUUtilization `
  --dimensions Name=DBInstanceIdentifier,Value=myapp-database `
  --start-time (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ssZ") `
  --end-time (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ") `
  --period 300 --statistics Average `
  --query "Datapoints | length(@)" --output text
# Expected: > 0 (data points exist)
```

---

## Test 10 — Negative Tests (Security Validation)

### Test that RDS is NOT publicly accessible

From your local machine (not EC2):
```bash
# This should fail/timeout
mysql -h YOUR_RDS_ENDPOINT -P 3306 -u admin -p
# Expected: ERROR — connection refused or timeout
```

### Test that only ec2-app-sg can reach RDS

If you launched another EC2 instance in the same VPC but with a different security group:
```bash
# From EC2 with different SG
mysql -h YOUR_RDS_ENDPOINT -P 3306 -u admin -p
# Expected: ERROR — connection refused (SG blocks it)
```

---

## Test 11 — Cleanup Verification

```powershell
# RDS should be gone
aws rds describe-db-instances `
  --db-instance-identifier myapp-database 2>&1 | Select-String "DBInstanceNotFound"
# Expected: line containing "DBInstanceNotFound"

# EC2 should be terminated
aws ec2 describe-instances `
  --instance-ids $APP_INSTANCE_ID `
  --query "Reservations[0].Instances[0].State.Name" --output text
# Expected: terminated

# VPC should be gone
aws ec2 describe-vpcs --vpc-ids $VPC_ID 2>&1
# Expected: InvalidVpcID.NotFound error

# Secret should be gone
aws secretsmanager describe-secret `
  --secret-id "rds/myapp/credentials" 2>&1
# Expected: ResourceNotFoundException
```