# Troubleshooting Guide — RDS MySQL + EC2 Two-Tier Application

## Quick Reference

| Problem | Cause | Fix |
|:--------|:------|:----|
| MySQL connection refused | RDS still starting or SG wrong | Wait for `Available` status; verify `rds-sg` allows 3306 from `ec2-app-sg` |
| Access denied for user 'admin' | Wrong password | Double-check password — watch for special characters (`@`, `/`, `"`, `\`) |
| RDS endpoint not resolving | DNS not enabled on VPC | Verify VPC has `enableDnsHostnames = true` |
| Cannot delete RDS | Deletion protection enabled | RDS console → Modify → disable deletion protection first |
| `aws rds wait` times out | RDS taking longer than usual | Check RDS Events tab in console for errors |
| Secrets Manager access denied | IAM role not attached | Attach `ec2-app-profile` to the instance |
| RDS creation fails | Subnet group spans wrong subnets | Verify subnet group uses private subnets only |
| EC2 status page not loading | Security group missing HTTP rule | Add inbound rule for port 80 from `0.0.0.0/0` |
| DependencyViolation on cleanup | Wrong deletion order | Follow the exact 10-step cleanup sequence |
| `mysql` command not found on EC2 | User data didn't run | SSH in and run `sudo yum install -y mysql` manually |

---

## Detailed Troubleshooting

### 1. MySQL Connection Refused from EC2

**Symptoms:**
```
ERROR 2003 (HY000): Can't connect to MySQL server on 'myapp-database.xxxxx.rds.amazonaws.com' (110)
```

**Root causes & fixes:**

| Check | Command | Expected |
|:------|:--------|:---------|
| RDS status | `aws rds describe-db-instances --db-instance-identifier myapp-database --query "DBInstances[0].DBInstanceStatus" --output text` | `available` |
| RDS SG allows 3306 from EC2 SG | `aws ec2 describe-security-groups --group-ids $RDS_SG --query "SecurityGroups[0].IpPermissions"` | Source group = ec2-app-sg ID |
| EC2 has correct SG | `aws ec2 describe-instances --instance-ids $APP_INSTANCE_ID --query "Reservations[0].Instances[0].SecurityGroups"` | `ec2-app-sg` listed |
| EC2 and RDS in same VPC | Compare VPC IDs from both describe commands | Same VPC ID |
| DNS resolution working | From EC2: `nslookup YOUR_RDS_ENDPOINT` | Returns private IP |

---

### 2. Access Denied for User 'admin'

**Symptoms:**
```
ERROR 1045 (28000): Access denied for user 'admin'@'10.0.1.x' (using password: YES)
```

**Fixes:**
1. Verify the password matches exactly: `MyDB#Secure2024!`
2. Ensure no copy-paste artifacts (hidden characters, trailing spaces)
3. Try entering the password interactively (don't pass with `-p'password'`)
4. Check that the password doesn't contain `@`, `/`, `"`, or `\`

```bash
# Connect interactively — enter password when prompted
mysql -h YOUR_RDS_ENDPOINT -P 3306 -u admin -p
```

If you need to reset the password:
```powershell
aws rds modify-db-instance `
  --db-instance-identifier myapp-database `
  --master-user-password "NewSecurePass2024!" `
  --apply-immediately
```

---

### 3. RDS Endpoint Not Resolving

**Symptoms:**
```
Could not resolve host: myapp-database.xxxxx.rds.amazonaws.com
```

**Fixes:**

```powershell
# Verify DNS hostnames are enabled on VPC
aws ec2 describe-vpc-attribute `
  --vpc-id $VPC_ID `
  --attribute enableDnsHostnames
# Expected: "Value": true

# Enable if disabled
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
```

---

### 4. Cannot Delete RDS Instance

**Symptoms:**
```
An error occurred (InvalidParameterCombination): Cannot delete a DB instance with deletion protection enabled.
```

**Fix:**
```powershell
# Disable deletion protection first
aws rds modify-db-instance `
  --db-instance-identifier myapp-database `
  --no-deletion-protection `
  --apply-immediately

# Wait a moment, then delete
aws rds delete-db-instance `
  --db-instance-identifier myapp-database `
  --skip-final-snapshot `
  --delete-automated-backups
```

---

### 5. `aws rds wait` Times Out

**Symptoms:**
```
Waiter DBInstanceAvailable failed: Max attempts exceeded
```

**Fixes:**
1. Check the RDS Events tab in the console for error messages
2. The wait command has a default timeout — just run it again:
```powershell
aws rds wait db-instance-available `
  --db-instance-identifier myapp-database
```
3. Check status manually:
```powershell
aws rds describe-db-instances `
  --db-instance-identifier myapp-database `
  --query "DBInstances[0].DBInstanceStatus" `
  --output text
```

---

### 6. Secrets Manager Access Denied from EC2

**Symptoms:**
```
An error occurred (AccessDeniedException) when calling the GetSecretValue operation
```

**Fixes:**

| Check | Command | Expected |
|:------|:--------|:---------|
| IAM role attached | `aws ec2 describe-iam-instance-profile-associations --filters "Name=instance-id,Values=$APP_INSTANCE_ID"` | `ec2-app-profile` listed |
| Inline policy exists | `aws iam get-role-policy --role-name ec2-app-role --policy-name secrets-manager-access` | Policy JSON returned |
| Wait for propagation | IAM changes take 1-2 minutes to take effect | Wait and retry |

If the IAM role is not attached:
```powershell
aws ec2 associate-iam-instance-profile `
  --instance-id $APP_INSTANCE_ID `
  --iam-instance-profile Name=ec2-app-profile
```

---

### 7. RDS Creation Fails

**Symptoms:**
```
An error occurred (DBSubnetGroupDoesNotCoverEnoughAZs)
```

**Fix:** The subnet group must span at least 2 AZs with subnets in each:
```powershell
aws rds describe-db-subnet-groups `
  --db-subnet-group-name rds-subnet-group `
  --query "DBSubnetGroups[0].Subnets[*].{AZ:SubnetAvailabilityZone.Name,ID:SubnetIdentifier}"
# Expected: 2 entries in different AZs
```

---

### 8. EC2 Status Page Not Loading

**Symptoms:** Browser shows connection timeout when visiting `http://PUBLIC_IP`

**Checks:**
```powershell
# 1. Verify EC2 has public IP
aws ec2 describe-instances --instance-ids $APP_INSTANCE_ID `
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text

# 2. Verify security group allows HTTP
aws ec2 describe-security-groups --group-ids $EC2_SG `
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`80\`]"

# 3. Verify EC2 is in public subnet with IGW route
aws ec2 describe-route-tables `
  --filters "Name=association.subnet-id,Values=$PUB_SUBNET_A" `
  --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].GatewayId"
```

If Apache didn't start (user data failed):
```bash
# SSH into EC2 and fix manually
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo '<html><body><h1>App Server Running</h1></body></html>' | sudo tee /var/www/html/index.html
```

---

### 9. DependencyViolation During Cleanup

**Symptoms:**
```
An error occurred (DependencyViolation) when calling the DeleteSecurityGroup operation
```

**Fix:** Resources must be deleted in the correct order. Follow the exact sequence:

1. EC2 (terminate and wait)
2. RDS (delete and wait)
3. RDS subnet group
4. Secrets Manager secret
5. Security groups
6. IAM role/profile
7. Subnets
8. Route tables
9. IGW (detach then delete)
10. VPC

---

### 10. Variables Lost Between PowerShell Sessions

If you close your PowerShell window and lose `$VPC_ID`, `$RDS_SG`, etc.:

```powershell
# Re-fetch all variables by tag names
$VPC_ID = aws ec2 describe-vpcs `
  --filters "Name=tag:Name,Values=my-custom-vpc" `
  --query "Vpcs[0].VpcId" --output text

$EC2_SG = aws ec2 describe-security-groups `
  --filters "Name=group-name,Values=ec2-app-sg" "Name=vpc-id,Values=$VPC_ID" `
  --query "SecurityGroups[0].GroupId" --output text

$RDS_SG = aws ec2 describe-security-groups `
  --filters "Name=group-name,Values=rds-sg" "Name=vpc-id,Values=$VPC_ID" `
  --query "SecurityGroups[0].GroupId" --output text

$APP_INSTANCE_ID = aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=app-server" "Name=instance-state-name,Values=running" `
  --query "Reservations[0].Instances[0].InstanceId" --output text

$RDS_ENDPOINT = aws rds describe-db-instances `
  --db-instance-identifier myapp-database `
  --query "DBInstances[0].Endpoint.Address" --output text

Write-Host "VPC: $VPC_ID"
Write-Host "EC2 SG: $EC2_SG"
Write-Host "RDS SG: $RDS_SG"
Write-Host "EC2: $APP_INSTANCE_ID"
Write-Host "RDS: $RDS_ENDPOINT"
```

See the [Cleanup Guide](cleanup-guide.md) for the full variable recovery script.