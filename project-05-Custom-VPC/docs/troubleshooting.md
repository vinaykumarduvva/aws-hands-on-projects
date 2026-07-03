# Troubleshooting Guide — Project 5 VPC

## Issue 1 — Cannot Delete VPC

**Error message:**
```
An error occurred (DependencyViolation) when calling the DeleteVpc
operation: The vpc 'vpc-xxxxxxxx' has dependencies and cannot be deleted.
```

**Cause:**
Resources still exist inside the VPC. VPC cannot be deleted
until all dependent resources are removed first.

**Fix — delete in this exact order:**
```powershell
# 1. EC2 instances
aws ec2 terminate-instances --instance-ids $BASTION_ID $PRIVATE_ID
aws ec2 wait instance-terminated --instance-ids $BASTION_ID $PRIVATE_ID

# 2. NAT Gateway
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_ID
Start-Sleep -Seconds 60

# 3. Elastic IP
aws ec2 release-address --allocation-id $EIP_ALLOC

# 4. Security groups (delete in reverse dependency order)
aws ec2 delete-security-group --group-id $PRIVATE_SG
aws ec2 delete-security-group --group-id $BASTION_SG

# 5. Subnets
aws ec2 delete-subnet --subnet-id $PUB_SUBNET_A
aws ec2 delete-subnet --subnet-id $PUB_SUBNET_B
aws ec2 delete-subnet --subnet-id $PRI_SUBNET_A
aws ec2 delete-subnet --subnet-id $PRI_SUBNET_B

# 6. Route tables (cannot delete main route table)
aws ec2 delete-route-table --route-table-id $PUB_RT_ID
aws ec2 delete-route-table --route-table-id $PRI_RT_ID

# 7. Internet Gateway (must detach before delete)
aws ec2 detach-internet-gateway `
  --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# 8. VPC (finally)
aws ec2 delete-vpc --vpc-id $VPC_ID
```

---

## Issue 2 — NAT Gateway Stuck in Pending State

**Symptom:**
```powershell
aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GW_ID `
  --query "NatGateways[0].State" --output text
# Returns: pending (for more than 5 minutes)
```

**Cause:**
NAT Gateway normally takes 1–2 minutes. Pending beyond 5 minutes
usually means the Elastic IP association failed or a quota was hit.

**Fix:**
```powershell
# Check detailed state and failure reason
aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GW_ID `
  --query "NatGateways[0].{State:State,FailureCode:FailureCode,FailureMessage:FailureMessage}" `
  --output table

# Check EIP quota (max 5 per region by default)
aws ec2 describe-addresses --query "Addresses[*].AllocationId" --output table

# If failed — delete and recreate
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_ID
Start-Sleep -Seconds 60
# Then recreate with a new EIP allocation
```

---

## Issue 3 — Private Instance Cannot Reach Internet

**Symptom:**
```bash
# Inside private instance via SSM
curl https://checkip.amazonaws.com
# Hangs or returns: curl: (6) Could not resolve host
```

**Diagnosis steps:**

```powershell
# Step 1 — Check private route table has NAT route
aws ec2 describe-route-tables --route-table-ids $PRI_RT_ID `
  --query "RouteTables[0].Routes" --output table
# Must show: 0.0.0.0/0 → nat-xxxxxxxx

# Step 2 — Confirm private subnet is associated with private route table
aws ec2 describe-route-tables --route-table-ids $PRI_RT_ID `
  --query "RouteTables[0].Associations[*].SubnetId" --output table
# Must show your private subnet IDs

# Step 3 — Check NAT Gateway is available
aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GW_ID `
  --query "NatGateways[0].State" --output text
# Must show: available

# Step 4 — Confirm NAT Gateway is in a PUBLIC subnet
aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GW_ID `
  --query "NatGateways[0].SubnetId" --output text
# Compare this to your public subnet IDs
```

**Most common causes and fixes:**

| Root cause | Fix |
|---|---|
| NAT route missing from private RT | `aws ec2 create-route --route-table-id $PRI_RT_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID` |
| Private subnet not associated with private RT | Re-associate subnet in console or CLI |
| NAT Gateway in wrong subnet | Must be in public subnet — delete and recreate in correct subnet |
| NAT Gateway not available | Wait or check for failure message |

---

## Issue 4 — Bastion SSH Connection Timeout

**Symptom:**
PuTTY shows "Connection timed out" or hangs indefinitely.

**Diagnosis:**
```powershell
# Check 1 — Is instance running and healthy?
aws ec2 describe-instances --instance-ids $BASTION_ID `
  --query "Reservations[0].Instances[0].{State:State.Name,Status:State.Code}" `
  --output table

# Check 2 — Does bastion have a public IP?
aws ec2 describe-instances --instance-ids $BASTION_ID `
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text

# Check 3 — What is your current IP?
(Invoke-WebRequest -Uri "https://checkip.amazonaws.com" `
  -UseBasicParsing).Content.Trim()

# Check 4 — What IP is in the security group rule?
aws ec2 describe-security-groups --group-ids $BASTION_SG `
  --query "SecurityGroups[0].IpPermissions[0].IpRanges[0].CidrIp" `
  --output text
```

**Fix — update SSH rule if your IP changed:**
```powershell
$OLD_IP = "54.OLD.IP.HERE"
$NEW_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" `
  -UseBasicParsing).Content.Trim()

# Remove old rule
aws ec2 revoke-security-group-ingress `
  --group-id $BASTION_SG `
  --protocol tcp --port 22 --cidr "$OLD_IP/32"

# Add new rule
aws ec2 authorize-security-group-ingress `
  --group-id $BASTION_SG `
  --protocol tcp --port 22 --cidr "$NEW_IP/32"

Write-Host "Updated SSH rule: $NEW_IP/32"
```

---

## Issue 5 — SSM Session Manager Connect Button Greyed Out

**Symptom:**
EC2 console → Connect → Session Manager → Connect button is greyed out
or shows "Session Manager is not connected to this instance."

**Diagnosis:**
```powershell
# Check 1 — Is IAM profile attached?
aws ec2 describe-iam-instance-profile-associations `
  --filters "Name=instance-id,Values=$PRIVATE_ID" `
  --query "IamInstanceProfileAssociations[*].{Profile:IamInstanceProfile.Arn,State:State}" `
  --output table

# Check 2 — Does the profile have the right policy?
aws iam list-attached-role-policies --role-name ec2-ssm-role `
  --query "AttachedPolicies[*].PolicyName" --output table
# Must show: AmazonSSMManagedInstanceCore

# Check 3 — Is SSM agent running?
# (Only checkable after connecting via another method)
# Inside the instance: sudo systemctl status amazon-ssm-agent
```

**Fix:**
```powershell
# Attach SSM profile if missing
aws ec2 associate-iam-instance-profile `
  --instance-id $PRIVATE_ID `
  --iam-instance-profile Name=ec2-ssm-profile

Write-Host "Profile attached. Wait 3 minutes then try again."
Start-Sleep -Seconds 180
```

---

## Issue 6 — Elastic IP Not Releasing

**Error:**
```
An error occurred (InvalidIPAddress.InUse) when calling the
ReleaseAddress operation: Address is in use.
```

**Cause:**
The EIP is still associated with the NAT Gateway which has not
fully deleted yet.

**Fix:**
```powershell
# Check NAT Gateway state
aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GW_ID `
  --query "NatGateways[0].State" --output text

# Wait until state is 'deleted' then release
# This can take 1-2 minutes after delete command

# Keep checking every 30 seconds
do {
  $STATE = aws ec2 describe-nat-gateways `
    --nat-gateway-ids $NAT_GW_ID `
    --query "NatGateways[0].State" --output text
  Write-Host "NAT Gateway state: $STATE"
  if ($STATE -ne "deleted") { Start-Sleep -Seconds 30 }
} while ($STATE -ne "deleted")

# Now release the EIP
aws ec2 release-address --allocation-id $EIP_ALLOC
Write-Host "EIP released"
```

---

## Issue 7 — Security Group Delete Fails

**Error:**
```
An error occurred (DependencyViolation) when calling the
DeleteSecurityGroup operation: resource sg-xxxxxxxx has a
dependent object.
```

**Cause:**
An EC2 instance is still using this security group — even if
the instance is in the "shutting-down" state it still holds
the SG reference until fully terminated.

**Fix:**
```powershell
# Wait for instances to be fully terminated
aws ec2 wait instance-terminated `
  --instance-ids $BASTION_ID $PRIVATE_ID
Write-Host "Instances terminated - safe to delete SGs"

# Now delete security groups
# Delete private-sg BEFORE bastion-sg
# (private-sg references bastion-sg as a source)
aws ec2 delete-security-group --group-id $PRIVATE_SG
aws ec2 delete-security-group --group-id $BASTION_SG
```

---

## Issue 8 — Route Table Delete Fails

**Error:**
```
An error occurred (DependencyViolation) when calling the
DeleteRouteTable operation: the routeTable has dependencies
and cannot be deleted.
```

**Cause:**
A subnet is still associated with this route table.

**Fix:**
```powershell
# Find and remove subnet associations first
$ASSOCIATIONS = aws ec2 describe-route-tables `
  --route-table-ids $PUB_RT_ID `
  --query "RouteTables[0].Associations[?Main!=`true`].RouteTableAssociationId" `
  --output text

foreach ($ASSOC in $ASSOCIATIONS.Split()) {
  if ($ASSOC) {
    aws ec2 disassociate-route-table --association-id $ASSOC
    Write-Host "Disassociated: $ASSOC"
  }
}

# Then delete the route table
aws ec2 delete-route-table --route-table-id $PUB_RT_ID
```

---

## Useful Diagnostic Commands

```powershell
# Full VPC resource inventory — find everything in your VPC
aws ec2 describe-instances `
  --filters "Name=vpc-id,Values=$VPC_ID" `
  --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,IP:PrivateIpAddress}" `
  --output table

# Check all route tables in VPC
aws ec2 describe-route-tables `
  --filters "Name=vpc-id,Values=$VPC_ID" `
  --query "RouteTables[*].{Name:Tags[?Key=='Name'].Value|[0],ID:RouteTableId,Routes:Routes[*].DestinationCidrBlock}" `
  --output table

# Check all security groups in VPC
aws ec2 describe-security-groups `
  --filters "Name=vpc-id,Values=$VPC_ID" `
  --query "SecurityGroups[*].{Name:GroupName,ID:GroupId}" `
  --output table

# Check all subnets in VPC
aws ec2 describe-subnets `
  --filters "Name=vpc-id,Values=$VPC_ID" `
  --query "Subnets[*].{Name:Tags[?Key=='Name'].Value|[0],ID:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone}" `
  --output table

# Check NAT Gateway status
aws ec2 describe-nat-gateways `
  --filter "Name=vpc-id,Values=$VPC_ID" `
  --query "NatGateways[*].{ID:NatGatewayId,State:State,Subnet:SubnetId}" `
  --output table

# Verify IGW attachment
aws ec2 describe-internet-gateways `
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" `
  --query "InternetGateways[*].{ID:InternetGatewayId,State:Attachments[0].State}" `
  --output table
```