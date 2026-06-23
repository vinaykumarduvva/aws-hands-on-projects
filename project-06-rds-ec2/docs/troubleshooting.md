# Troubleshooting Guide — Project 6 RDS + EC2

## Issue 1 — MySQL Connection Refused

**Error:**
```
ERROR 2003 (HY000): Can't connect to MySQL server on
'myapp-database.xxx.rds.amazonaws.com' (111)
```

**Diagnosis:**
```powershell
# Check 1 — Is RDS available?
aws rds describe-db-instances `
  --db-instance-identifier myapp-database `
  --query "DBInstances[0].DBInstanceStatus" --output text
# Must return: available (not creating, backing-up, modifying)

# Check 2 — Is rds-sg allowing port 3306 from ec2-app-sg?
aws ec2 describe-security-groups --group-ids $RDS_SG `
  --query "SecurityGroups[0].IpPermissions" --output table
# Must show: FromPort=3306, UserIdGroupPairs with ec2-app-sg ID

# Check 3 — Is EC2 using ec2-app-sg?
aws ec2 describe-instances --instance-ids $APP_INSTANCE_ID `
  --query "Reservations[0].Instances[0].SecurityGroups" --output table
# Must show ec2-app-sg listed

# Check 4 — Is RDS in correct subnet group?
aws rds describe-db-instances `
  --db-instance-identifier myapp-database `
  --query "DBInstances[0].DBSubnetGroup.DBSubnetGroupName" --output text
# Must return: rds-subnet-group
```

**Fix:**
```powershell
# If rds-sg is missing the rule — add it
aws ec2 authorize-security-group-ingress `
  --group-id $RDS_SG `
  --protocol tcp --port 3306 `
  --source-group $EC2_SG
```

---

## Issue 2 — Access Denied for User Admin

**Error:**
```
ERROR 1045 (28000): Access denied for user 'admin'@'10.0.1.x'
(using password: YES)
```

**Cause:** Wrong password entered or special characters
in password breaking the CLI command.

**Fix:**
```bash
# Inside EC2 — try connecting with explicit quoting
mysql -h $RDS_ENDPOINT -P 3306 -u admin -p'MyDB#Secure2024!'

# Or use the --password flag without the = sign
mysql -h $RDS_ENDPOINT -P 3306 -u admin --password
# Then type password when prompted (safest method)
```

**Password rules for RDS:**
```
✅ Allowed special characters: ! # $ % ^ & * ( ) _ + - = [ ]
❌ Avoid: @ / " \ ` ' (these break connection strings)
Minimum: 8 characters
```

---

## Issue 3 — RDS Endpoint Not Resolving

**Error:**
```
ERROR 2005 (HY000): Unknown MySQL server host
'myapp-database.xxx.us-east-1.rds.amazonaws.com' (-2)
```

**Cause:** DNS resolution failing — usually VPC DNS not enabled.

**Diagnosis:**
```powershell
# Check VPC has DNS enabled
aws ec2 describe-vpcs --vpc-ids $VPC_ID `
  --query "Vpcs[0].{DNS:EnableDnsHostnames,Support:EnableDnsSupport}" `
  --output table
# Both must be: True

# Test DNS from inside EC2 (via PuTTY or SSM)
```

```bash
# Inside EC2 terminal
nslookup myapp-database.xxx.us-east-1.rds.amazonaws.com
# Expected: returns a private IP like 10.0.3.x
# If returns NXDOMAIN → DNS issue
```

**Fix:**
```powershell
# Enable DNS on VPC
aws ec2 modify-vpc-attribute `
  --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute `
  --vpc-id $VPC_ID --enable-dns-support
```

---

## Issue 4 — Cannot Delete RDS (Deletion Protection)

**Error:**
```
An error occurred (InvalidParameterCombination): Cannot delete
protected Cluster, please disable deletion protection first.
```

**Fix:**
```powershell
# Disable deletion protection first
aws rds modify-db-instance `
  --db-instance-identifier myapp-database `
  --no-deletion-protection `
  --apply-immediately

# Wait for modification to complete
aws rds wait db-instance-available `
  --db-instance-identifier myapp-database

# Now delete
aws rds delete-db-instance `
  --db-instance-identifier myapp-database `
  --skip-final-snapshot
```

---

## Issue 5 — RDS Stuck in Modifying State

**Symptom:**
```
aws rds describe-db-instances ... Status: modifying
```

**Cause:** RDS is applying a change. Some changes are immediate,
others apply at the next maintenance window.

**Fix:**
```powershell
# Check what events are happening
aws rds describe-events `
  --source-identifier myapp-database `
  --source-type db-instance `
  --query "Events[*].{Time:Date,Message:Message}" `
  --output table

# Force apply immediately (if change was queued for maintenance window)
aws rds modify-db-instance `
  --db-instance-identifier myapp-database `
  --apply-immediately
```

---

## Issue 6 — Secrets Manager Access Denied from EC2

**Error:**
```bash
# Inside EC2
aws secretsmanager get-secret-value --secret-id rds/myapp/credentials
# Returns: AccessDeniedException
```

**Diagnosis:**
```powershell
# Check if IAM profile is attached
aws ec2 describe-iam-instance-profile-associations `
  --filters "Name=instance-id,Values=$APP_INSTANCE_ID" `
  --query "IamInstanceProfileAssociations[0].{Profile:IamInstanceProfile.Arn,State:State}" `
  --output table

# Check role has correct policy
aws iam list-role-policies --role-name ec2-app-role `
  --query "PolicyNames" --output table
# Must show: secrets-manager-access listed
```

**Fix:**
```powershell
# Attach profile if missing
aws ec2 associate-iam-instance-profile `
  --instance-id $APP_INSTANCE_ID `
  --iam-instance-profile Name=ec2-app-profile

# Wait 2 minutes for profile to propagate
Start-Sleep -Seconds 120
```

---

## Issue 7 — DocumentDB Error During RDS Creation

**Error popup:**
```
Failed to fetch a list of Amazon DocumentDB clusters.
The AWS Access Key Id needs a subscription for the service.
```

**What this means:**
This is a **harmless background error**. The RDS console
tries to list DocumentDB clusters (a separate NoSQL service)
in the background. Your Free Tier account has never used
DocumentDB so the API call fails.

**Impact:** Zero. Your MySQL RDS will create successfully.

**Action required:** Close the popup and continue filling
in the RDS creation form normally.

---

## Issue 8 — RDS Subnet Group Creation Fails

**Error:**
```
An error occurred (DBSubnetGroupNotAllowedFault):
DbSubnetGroup doesn't meet availability zone coverage requirement.
```

**Cause:** Subnet group doesn't span at least 2 AZs.

**Fix:**
```powershell
# Verify subnets are in different AZs
aws ec2 describe-subnets `
  --subnet-ids $PRI_SUBNET_A $PRI_SUBNET_B `
  --query "Subnets[*].{SubnetId:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock}" `
  --output table
# Must show two different AZs (e.g. us-east-1a and us-east-1b)

# If they are in same AZ — create a new subnet in a different AZ
aws ec2 create-subnet `
  --vpc-id $VPC_ID `
  --cidr-block 10.0.5.0/24 `
  --availability-zone us-east-1b `
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-b}]"
```

---

## Issue 9 — RDS Taking Too Long to Create

**Normal:** RDS creation takes 5–10 minutes.

**If taking longer than 15 minutes:**
```powershell
# Check RDS events for errors
aws rds describe-events `
  --source-identifier myapp-database `
  --source-type db-instance `
  --duration 60 `
  --query "Events[*].{Time:Date,Category:EventCategories[0],Message:Message}" `
  --output table
```

Common causes:
- Service limit exceeded → check RDS quota in Service Quotas console
- AZ capacity issue → try changing AZ in RDS settings

---

## Useful Diagnostic Commands

```powershell
# Full RDS instance details
aws rds describe-db-instances `
  --db-instance-identifier myapp-database `
  --query "DBInstances[0].{
    Status:DBInstanceStatus,
    Class:DBInstanceClass,
    Engine:Engine,
    Version:EngineVersion,
    Endpoint:Endpoint.Address,
    Port:Endpoint.Port,
    AZ:AvailabilityZone,
    MultiAZ:MultiAZ,
    Public:PubliclyAccessible,
    Storage:AllocatedStorage,
    Encrypted:StorageEncrypted,
    Backup:BackupRetentionPeriod
  }" --output table

# List all RDS snapshots
aws rds describe-db-snapshots `
  --db-instance-identifier myapp-database `
  --query "DBSnapshots[*].{ID:DBSnapshotIdentifier,Status:Status,Created:SnapshotCreateTime,Size:AllocatedStorage}" `
  --output table

# Check RDS security groups
aws rds describe-db-instances `
  --db-instance-identifier myapp-database `
  --query "DBInstances[0].VpcSecurityGroups" --output table

# List all secrets
aws secretsmanager list-secrets `
  --query "SecretList[*].{Name:Name,ARN:ARN}" --output table

# Get secret value (from EC2 with correct IAM role)
aws secretsmanager get-secret-value `
  --secret-id "rds/myapp/credentials" `
  --query "SecretString" --output text

# Check EC2 IAM profile
aws ec2 describe-iam-instance-profile-associations `
  --filters "Name=instance-id,Values=$APP_INSTANCE_ID" `
  --output table

# Verify RDS endpoint from EC2 via SSM
aws ssm start-session --target $APP_INSTANCE_ID
# Then inside terminal: nslookup YOUR_RDS_ENDPOINT
```