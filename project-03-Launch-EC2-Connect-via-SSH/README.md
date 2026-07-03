# Project 3 — Launch EC2 & Connect via SSH

## Overview
Launched a virtual Linux server on Amazon EC2, secured it with a
key pair and security group, connected from Windows using both
PuTTY (SSH) and AWS Systems Manager Session Manager, and deployed
a live Apache web server using a user data bootstrap script.

---

## Architecture

```
Your Windows PC
      │
      ├── PuTTY SSH (port 22, your IP only) ────────┐
      │                                              │
      └── SSM Session Manager (HTTPS, no open port) ┤
                                                     ▼
                                      ┌──────────────────────────┐
                                      │   EC2 Instance           │
                                      │   Amazon Linux 2023      │
                                      │   t2.micro (1vCPU, 1GB)  │
                                      │   us-east-1              │
                                      │                          │
                                      │   Security Group         │
                                      │   ├── Port 22 → My IP    │
                                      │   └── Port 80 → 0.0.0.0  │
                                      │                          │
                                      │   Apache Web Server      │
                                      │   /var/www/html/         │
                                      └──────────────────────────┘
                                                     │
                                                     ▼
                                          Browser → http://PUBLIC_IP
```

---

## AWS Services Used

| Service | Purpose |
|---|---|
| Amazon EC2 | Virtual Linux server (t2.micro, Free Tier) |
| Amazon Machine Image (AMI) | Amazon Linux 2023 base OS |
| Key Pair | RSA key-based SSH authentication |
| Security Group | Virtual firewall — port 22 (SSH) + port 80 (HTTP) |
| IAM Role + Instance Profile | Grants EC2 permission to use SSM Session Manager |
| AWS Systems Manager (SSM) | Browser/CLI-based terminal without open SSH port |
| CloudWatch | CPU, network, and disk monitoring |
| User Data | Bootstrap script — installs Apache on first boot |

---

## Prerequisites

- AWS account with IAM admin user configured (Project 1)
- AWS CLI v2 installed and configured on Windows (Project 1)
- Basic familiarity with PowerShell terminal
- PuTTY installed ([putty.org](https://www.putty.org))
- Default VPC present in us-east-1

Verify prerequisites:
```powershell
aws sts get-caller-identity
aws configure get region
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" `
  --query "Vpcs[*].VpcId" --output text
```

---

## Files in This Project

```
project-03-ec2-ssh/
├── README.md                  ← This file
├── scripts/
│   └── userdata.sh            ← Bootstrap script (Apache install)
├── docs/
│   |── security-group-rules.md
|   ├── iam-policy-notes.md
|   └── troubleshooting-instrustions.md
└── images/
    ├── 01-instance-running.png
    ├── 02-security-group-rules.png
    ├── 03-putty-connected.png
    ├── 04-apache-running.png
    ├── 05-web-server-browser.png
    ├── 06-session-manager.png
    └── 07-instance-terminated.png
```

---

## User Data Bootstrap Script

Saved at `scripts/userdata.sh` — runs automatically on first boot:

```bash
#!/bin/bash
# Runs as root on first boot via EC2 User Data
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<html>
<head><title>My EC2 Web Server</title></head>
<body style='font-family:Arial;text-align:center;padding:60px;background:#f0f2f5'>
<h1 style='color:#232f3e'>EC2 Web Server is Running</h1>
<p style='color:#555'>Hosted on Amazon EC2 t2.micro - Amazon Linux 2023</p>
<p style='color:#555'>Project 3 - AWS Cloud Engineering Bootcamp</p>
</body>
</html>" > /var/www/html/index.html
```

---

## IAM Role — ec2-ssm-role

Created to allow Session Manager access without open SSH port.

```json
{
  "RoleName": "ec2-ssm-role",
  "TrustedEntity": "ec2.amazonaws.com",
  "AttachedPolicy": "AmazonSSMManagedInstanceCore",
  "Purpose": "Allows EC2 instance to communicate with SSM endpoints
               for Session Manager browser terminal access"
}
```

**Why a role and not access keys?**
EC2 instances must never have hardcoded access keys.
An IAM role attached via instance profile gives the instance
temporary, auto-rotating credentials automatically.
This is the correct pattern for all AWS compute services.

---

## Security Group Rules

Group name: `ec2-web-sg`

| Direction | Port | Protocol | Source | Purpose |
|---|---|---|---|---|
| Inbound | 22 | TCP | My IP /32 | SSH via PuTTY |
| Inbound | 80 | TCP | 0.0.0.0/0 | Apache web server |
| Outbound | All | All | 0.0.0.0/0 | Default allow all |

**Key concept — security groups are stateful:**
Only inbound rules are needed. Return traffic for established
connections is automatically allowed without an explicit
outbound rule. This is different from network ACLs (stateless).

---

## Setup Guide

### Part 1 — Create key pair

**Console:**
EC2 → Key Pairs → Create key pair
- Name: `aws-ec2-keypair`
- Type: RSA
- Format: `.ppk` (PuTTY format)
- Save the downloaded `.ppk` to `C:\Users\YourName\aws-keys\`

**CLI:**
```powershell
aws ec2 create-key-pair `
  --key-name aws-ec2-keypair `
  --key-type RSA `
  --key-format ppk `
  --query "KeyMaterial" `
  --output text | Out-File `
  -FilePath "C:\Users\$env:USERNAME\aws-keys\aws-ec2-keypair.ppk" `
  -Encoding ascii
```

---

### Part 2 — Create security group

```powershell
$VPC_ID = aws ec2 describe-vpcs `
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
```

---

### Part 3 — Launch instance

```powershell
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

Write-Host "Instance ready at: http://$PUBLIC_IP"
```

---

### Part 4 — Connect via PuTTY

1. Open PuTTY
2. Host Name: `ec2-user@YOUR_PUBLIC_IP`
3. Port: `22`
4. Connection → SSH → Auth → Credentials → browse to `.ppk` file
5. Session → Save as `my-first-ec2` → Open
6. Accept fingerprint on first connection

---

### Part 5 — Connect via Session Manager

**Attach IAM role first:**
```powershell
aws iam create-role `
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

aws ec2 associate-iam-instance-profile `
  --instance-id $INSTANCE_ID `
  --iam-instance-profile Name=ec2-ssm-profile
```

**Connect:**
```powershell
# Via console: EC2 → Instance → Connect → Session Manager → Connect
# Via CLI:
aws ssm start-session --target $INSTANCE_ID
```

---

## Verification Commands

Run these inside the EC2 terminal after connecting:

```bash
# Confirm OS
cat /etc/os-release

# Confirm Apache is running
sudo systemctl status httpd

# Confirm web page exists
cat /var/www/html/index.html

# Confirm port 80 is listening
sudo ss -tlnp | grep :80

# Check resources
free -h && df -h && nproc

# View user data execution log
cat /var/log/cloud-init-output.log
```

**Expected output in browser:**
Navigate to `http://YOUR_PUBLIC_IP` → EC2 web server page loads.

---

## Key CLI Commands Reference

```powershell
# Check instance state
aws ec2 describe-instances --instance-ids $INSTANCE_ID `
  --query "Reservations[0].Instances[0].{State:State.Name,IP:PublicIpAddress}" `
  --output table

# Stop instance (no compute charge when stopped)
aws ec2 stop-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID

# Start instance
aws ec2 start-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Reboot instance
aws ec2 reboot-instances --instance-ids $INSTANCE_ID

# Terminate instance (permanent — cannot undo)
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
```

---

## Cleanup (full teardown)

```powershell
# 1. Terminate instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID

# 2. Delete security group
aws ec2 delete-security-group --group-id $SG_ID

# 3. Delete key pair from AWS (keep local .ppk file)
aws ec2 delete-key-pair --key-name aws-ec2-keypair

# 4. Remove IAM role and profile
aws iam remove-role-from-instance-profile `
  --instance-profile-name ec2-ssm-profile --role-name ec2-ssm-role
aws iam detach-role-policy `
  --role-name ec2-ssm-role `
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam delete-instance-profile --instance-profile-name ec2-ssm-profile
aws iam delete-role --role-name ec2-ssm-role

# 5. Verify cleanup
aws ec2 describe-instances --instance-ids $INSTANCE_ID `
  --query "Reservations[0].Instances[0].State.Name" --output text
# Expected: terminated
```

---

## Troubleshooting

| Problem | Likely Cause | Fix |
|---|---|---|
| PuTTY — Connection refused | Instance not ready or port 22 blocked | Wait for 2/2 status checks; verify SG has port 22 rule |
| PuTTY — Connection timed out | Wrong IP or SG not attached | Check public IP in console; confirm ec2-web-sg is attached |
| PuTTY — No supported auth methods | Wrong key file | Re-browse to correct `.ppk` file in PuTTY Auth settings |
| Browser — Apache page not loading | Port 80 missing or Apache not started | Check SG inbound rules; SSH in and run `sudo systemctl start httpd` |
| SSM Connect button greyed out | Role not attached or agent not ready | Wait 5 min after attaching role |
| Public IP changed | Expected — dynamic IP on every start | Note new IP from console after each start; use Elastic IP to fix |

---

## Cost Estimate

| Resource | Free Tier | This Project |
|---|---|---|
| EC2 t2.micro | 750 hrs/month free (12 months) | ~2–3 hrs = $0.00 |
| EBS 8 GB gp3 | 30 GB/month free (12 months) | 8 GB = $0.00 |
| Data transfer | 1 GB/month free | Minimal = $0.00 |
| **Total** | | **$0.00** |

> Always stop or terminate the instance when not in use.
> A running t2.micro costs ~$0.0116/hr outside Free Tier.

---

## Key Concepts Learned

| Concept | What it means |
|---|---|
| AMI | Pre-built OS image — the template your instance boots from |
| Instance type | Hardware spec — t2.micro = 1 vCPU + 1 GB RAM |
| Key pair | Public key stored on server + private key on your PC = secure login |
| Security group | Stateful virtual firewall — inbound rules only needed |
| User data | Shell script that runs as root on first boot only |
| IAM instance profile | The container that attaches an IAM role to an EC2 instance |
| Stop vs Terminate | Stop = pause (data kept). Terminate = permanent delete |
| Session Manager | SSM-based terminal — no open ports, no key pair needed |

---

## What I Would Do Differently in Production

- Use **Session Manager only** — remove port 22 from security group entirely
- Use **Elastic IP** so the public IP does not change on restart
- Enable **detailed CloudWatch monitoring** (1-minute intervals vs 5-minute)
- Use an **IAM role with least-privilege** instead of full SSM managed policy
- Store the web content in **S3 and sync on boot** instead of hardcoding in user data
- Use a **Launch Template** instead of manually configuring at launch time

---

## Next Project

**Project 4 — S3 Versioning, Lifecycle Policies & Replication**
- Enable versioning on an S3 bucket
- Recover deleted and overwritten files
- Automate storage class transitions with lifecycle rules
- Set up cross-region replication for disaster recovery

---