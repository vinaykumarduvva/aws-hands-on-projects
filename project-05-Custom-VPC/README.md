# Project 5 — Custom VPC: Subnets, Internet Gateway, Route Tables & NAT Gateway

[![AWS](https://img.shields.io/badge/AWS-VPC-orange?style=flat&logo=amazon-aws)](https://aws.amazon.com/vpc/)
[![Level](https://img.shields.io/badge/Level-Beginner%20→%20Intermediate-yellow?style=flat)](../README.md)
[![Free Tier](https://img.shields.io/badge/Cost-~%240.05-brightgreen?style=flat)](https://aws.amazon.com/free/)
[![Region](https://img.shields.io/badge/Region-us--east--1-blue?style=flat)](https://aws.amazon.com/about-aws/global-infrastructure/)

---

## Overview

Built a production-grade custom AWS VPC from scratch with public and private
subnets across two Availability Zones, an Internet Gateway for public internet
access, a NAT Gateway for secure outbound-only internet from private subnets,
and verified the complete bastion host connectivity pattern.

This is the networking foundation that every intermediate and advanced AWS
project builds on — every real company runs their workloads inside a
custom VPC exactly like this one.

> **Real-world context:** When a Solutions Architect designs any cloud
> system, the VPC architecture is always the first decision made.
> Public/private subnet separation, NAT Gateway placement, and route
> table design are core SA interview topics at every company.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CUSTOM VPC — 10.0.0.0/16                         │
│                    Region: us-east-1                                │
│                                                                     │
│  ┌─────────────────────────┐    ┌─────────────────────────┐        │
│  │  Availability Zone A    │    │  Availability Zone B    │        │
│  │  us-east-1a             │    │  us-east-1b             │        │
│  │                         │    │                         │        │
│  │  ┌───────────────────┐  │    │  ┌───────────────────┐  │        │
│  │  │  PUBLIC SUBNET A  │  │    │  │  PUBLIC SUBNET B  │  │        │
│  │  │  10.0.1.0/24      │  │    │  │  10.0.2.0/24      │  │        │
│  │  │                   │  │    │  │                   │  │        │
│  │  │  Bastion Host     │  │    │  │  (Future: ALB)    │  │        │
│  │  │  Public IP ✅     │  │    │  │                   │  │        │
│  │  │  NAT Gateway      │  │    │  │                   │  │        │
│  │  └───────────────────┘  │    │  └───────────────────┘  │        │
│  │                         │    │                         │        │
│  │  ┌───────────────────┐  │    │  ┌───────────────────┐  │        │
│  │  │  PRIVATE SUBNET A │  │    │  │  PRIVATE SUBNET B │  │        │
│  │  │  10.0.3.0/24      │  │    │  │  10.0.4.0/24      │  │        │
│  │  │                   │  │    │  │                   │  │        │
│  │  │  Private Instance │  │    │  │  (Future: RDS)    │  │        │
│  │  │  No Public IP ✅  │  │    │  │                   │  │        │
│  │  └───────────────────┘  │    │  └───────────────────┘  │        │
│  └─────────────────────────┘    └─────────────────────────┘        │
│                                                                     │
│  Internet Gateway (IGW) ←→ Public Internet                         │
│  NAT Gateway (in Public Subnet A) → Private outbound only          │
└─────────────────────────────────────────────────────────────────────┘
```

> See `diagrams/vpc-architecture.png` for the full visual diagram.

---

## 🗺️ Architecture / Resource Map
![VPC Resource Map](./resource-map.png)

---

## AWS Services Used

| Service | Purpose | Cost |
|---|---|---|
| VPC | Private isolated network | Always free |
| Subnets (×4) | Network subdivisions across 2 AZs | Always free |
| Internet Gateway | Connects VPC to public internet | Always free |
| Route Tables (×2) | Traffic routing rules | Always free |
| NAT Gateway | Outbound internet for private subnets | ~$0.045/hr ⚠️ |
| Elastic IP | Static public IP for NAT Gateway | Free when attached |
| Security Groups (×2) | Instance-level firewall (stateful) | Always free |
| EC2 t2.micro (×2) | Bastion + private test instances | Free tier |

---

## CIDR Block Design

| Resource | CIDR Block | AZ | Type | IPs Available |
|---|---|---|---|---|
| VPC | 10.0.0.0/16 | us-east-1 | — | 65,536 |
| Public Subnet A | 10.0.1.0/24 | us-east-1a | Public | 251 |
| Public Subnet B | 10.0.2.0/24 | us-east-1b | Public | 251 |
| Private Subnet A | 10.0.3.0/24 | us-east-1a | Private | 251 |
| Private Subnet B | 10.0.4.0/24 | us-east-1b | Private | 251 |

> AWS reserves 5 IPs per subnet: .0 (network), .1 (VPC router),
> .2 (DNS), .3 (future use), .255 (broadcast). Hence 256 - 5 = 251.

---

## Route Table Design

### Public Route Table — `public-route-table`
| Destination | Target | Purpose |
|---|---|---|
| 10.0.0.0/16 | local | Internal VPC traffic |
| 0.0.0.0/0 | igw-xxxxxxxx | Internet access via IGW |

Associated with: `public-subnet-a`, `public-subnet-b`

### Private Route Table — `private-route-table`
| Destination | Target | Purpose |
|---|---|---|
| 10.0.0.0/16 | local | Internal VPC traffic |
| 0.0.0.0/0 | nat-xxxxxxxx | Outbound internet via NAT |

Associated with: `private-subnet-a`, `private-subnet-b`

---

## Security Group Design

### bastion-sg
| Direction | Port | Protocol | Source | Purpose |
|---|---|---|---|---|
| Inbound | 22 | TCP | My IP /32 | SSH from my PC only |
| Outbound | All | All | 0.0.0.0/0 | Default allow all |

### private-sg
| Direction | Port | Protocol | Source | Purpose |
|---|---|---|---|---|
| Inbound | 22 | TCP | bastion-sg | SSH from bastion only |
| Outbound | All | All | 0.0.0.0/0 | Default allow all |

> Security group chaining: `private-sg` references `bastion-sg`
> as the source — not an IP range. This means only instances
> attached to `bastion-sg` can SSH into private instances.
> This is the production bastion host pattern.

---

## Prerequisites

- AWS account with IAM admin user (Project 1 ✅)
- AWS CLI v2 configured on Windows (Project 1 ✅)
- PuTTY installed with key pair ready (Project 3 ✅)
- `aws-ec2-keypair.ppk` saved at `C:\Users\YourName\aws-keys\`
- `ec2-ssm-profile` IAM instance profile exists (Project 3 ✅)

Verify:
```powershell
aws sts get-caller-identity
aws configure get region
aws ec2 describe-key-pairs --key-names aws-ec2-keypair `
  --query "KeyPairs[0].KeyName" --output text
```

---

## Repository Structure

```
project-05-custom-vpc/
│
├── README.md                          ← This file
│
├── scripts/
│   ├── 01-create-vpc.ps1              ← VPC + subnets + IGW
│   ├── 02-create-route-tables.ps1     ← Route tables + associations
│   ├── 03-create-nat-gateway.ps1      ← NAT Gateway + EIP
│   ├── 04-create-security-groups.ps1  ← bastion-sg + private-sg
│   ├── 05-launch-instances.ps1        ← Bastion + private EC2
│   └── 06-cleanup.ps1                 ← Full teardown in order
│
├── cloudformation/
│   └── vpc-stack.yaml                 ← Full IaC version of this VPC
│
├── diagrams/
│   └── vpc-architecture.png           ← Architecture diagram
│
├── docs/
│   ├── networking-concepts.md         ← VPC concepts cheat sheet
│   ├── security-group-notes.md        ← SG vs NACL comparison
│   └── troubleshooting.md             ← Common issues and fixes
│
└── images/
    ├── 01-vpc-created.png
    ├── 02-subnets-created.png
    ├── 03-igw-attached.png
    ├── 04-route-tables.png
    ├── 05-nat-gateway-available.png
    ├── 06-security-groups.png
    ├── 07-bastion-running.png
    ├── 08-private-instance-no-public-ip.png
    ├── 09-putty-connected-bastion.png
    ├── 10-nat-test-curl-output.png
    └── 11-cleanup-complete.png
```

---

## Full Setup Guide

### Part 1 — Create VPC

```powershell
$VPC_ID = aws ec2 create-vpc `
  --cidr-block 10.0.0.0/16 `
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=my-custom-vpc}]" `
  --query "Vpc.VpcId" --output text

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

Write-Host "VPC ID: $VPC_ID"
```

### Part 2 — Create Subnets

```powershell
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

# Enable auto-assign public IP on public subnets
aws ec2 modify-subnet-attribute `
  --subnet-id $PUB_SUBNET_A --map-public-ip-on-launch
aws ec2 modify-subnet-attribute `
  --subnet-id $PUB_SUBNET_B --map-public-ip-on-launch
```

### Part 3 — Internet Gateway

```powershell
$IGW_ID = aws ec2 create-internet-gateway `
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-vpc-igw}]" `
  --query "InternetGateway.InternetGatewayId" --output text

aws ec2 attach-internet-gateway `
  --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
```

### Part 4 — Route Tables

```powershell
# Public route table
$PUB_RT_ID = aws ec2 create-route-table `
  --vpc-id $VPC_ID `
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=public-route-table}]" `
  --query "RouteTable.RouteTableId" --output text

aws ec2 create-route `
  --route-table-id $PUB_RT_ID `
  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

aws ec2 associate-route-table --route-table-id $PUB_RT_ID --subnet-id $PUB_SUBNET_A
aws ec2 associate-route-table --route-table-id $PUB_RT_ID --subnet-id $PUB_SUBNET_B

# Private route table
$PRI_RT_ID = aws ec2 create-route-table `
  --vpc-id $VPC_ID `
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=private-route-table}]" `
  --query "RouteTable.RouteTableId" --output text

aws ec2 associate-route-table --route-table-id $PRI_RT_ID --subnet-id $PRI_SUBNET_A
aws ec2 associate-route-table --route-table-id $PRI_RT_ID --subnet-id $PRI_SUBNET_B
```

### Part 5 — NAT Gateway

```powershell
$EIP_ALLOC = aws ec2 allocate-address `
  --domain vpc --query "AllocationId" --output text

$NAT_GW_ID = aws ec2 create-nat-gateway `
  --subnet-id $PUB_SUBNET_A `
  --allocation-id $EIP_ALLOC `
  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=my-nat-gateway}]" `
  --query "NatGateway.NatGatewayId" --output text

aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

aws ec2 create-route `
  --route-table-id $PRI_RT_ID `
  --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID
```

### Part 6 — Security Groups

```powershell
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
```

### Part 7 — Launch EC2 Instances

```powershell
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

aws ec2 wait instance-running --instance-ids $BASTION_ID $PRIVATE_ID
```

---

## Connectivity Verification Results

### Test 1 — Bastion SSH ✅
```bash
[ec2-user@ip-10-0-1-XXX ~]$ curl -s https://checkip.amazonaws.com
54.XXX.XXX.XXX   # ← bastion public IP returned
```

### Test 2 — Private instance has no public IP ✅
```
Name              PrivateIP    PublicIP   Subnet
bastion-host      10.0.1.X     54.X.X.X   public-subnet-a
private-instance  10.0.3.X     None       private-subnet-a
```

### Test 3 — Private instance reaches internet via NAT ✅
```bash
sh-5.2$ curl -s https://checkip.amazonaws.com
3.XXX.XXX.XXX   # ← NAT Gateway Elastic IP returned (not private IP)
```

### Test 4 — Private instance has no public IP ✅
```bash
sh-5.2$ curl http://169.254.169.254/latest/meta-data/public-ipv4
# Returns empty — no public IP assigned
```

---

## Cleanup — Full Teardown

```powershell
# Run in this exact order — dependencies matter

# 1. Terminate instances
aws ec2 terminate-instances --instance-ids $BASTION_ID $PRIVATE_ID
aws ec2 wait instance-terminated --instance-ids $BASTION_ID $PRIVATE_ID

# 2. Delete NAT Gateway immediately (stops billing)
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_ID
Start-Sleep -Seconds 60

# 3. Release Elastic IP
aws ec2 release-address --allocation-id $EIP_ALLOC

# 4. Delete security groups
aws ec2 delete-security-group --group-id $PRIVATE_SG
aws ec2 delete-security-group --group-id $BASTION_SG

# 5. Delete subnets
aws ec2 delete-subnet --subnet-id $PUB_SUBNET_A
aws ec2 delete-subnet --subnet-id $PUB_SUBNET_B
aws ec2 delete-subnet --subnet-id $PRI_SUBNET_A
aws ec2 delete-subnet --subnet-id $PRI_SUBNET_B

# 6. Delete route tables
aws ec2 delete-route-table --route-table-id $PUB_RT_ID
aws ec2 delete-route-table --route-table-id $PRI_RT_ID

# 7. Detach and delete IGW
aws ec2 detach-internet-gateway `
  --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# 8. Delete VPC
aws ec2 delete-vpc --vpc-id $VPC_ID
```

---

## Cost Breakdown

| Resource | Rate | Duration | Cost |
|---|---|---|---|
| VPC + Subnets + IGW + RT | Free | Always | $0.00 |
| EC2 t2.micro × 2 | Free tier | ~1 hour | $0.00 |
| NAT Gateway | $0.045/hr | ~30 min | ~$0.02 |
| NAT Gateway data | $0.045/GB | < 1 MB | ~$0.00 |
| Elastic IP | Free when attached | — | $0.00 |
| **Total** | | | **~$0.02** |

---

## Key Concepts Learned

| Concept | Explanation |
|---|---|
| **VPC** | Your private network in AWS. Completely isolated from other AWS customers. |
| **CIDR block** | The IP range of your network. /16 = 65,536 IPs. /24 = 256 IPs. |
| **Public subnet** | Has a route to IGW. Instances can get public IPs. |
| **Private subnet** | No route to IGW. Instances have private IPs only. |
| **Internet Gateway** | Enables bidirectional internet for public subnets. One per VPC. |
| **NAT Gateway** | Enables outbound-only internet for private subnets. Lives in public subnet. |
| **Route table** | Set of rules that control where traffic is directed. |
| **Security group** | Stateful instance-level firewall. Return traffic auto-allowed. |
| **Bastion host** | Public EC2 used as a jump box to reach private instances via SSH. |
| **Security group chaining** | Private SG allows traffic only from bastion SG — not a CIDR range. |

---

## What I Would Do Differently in Production

- Deploy **NAT Gateway in both AZs** (one per AZ) for high availability —
  a single NAT Gateway is a single point of failure
- Use **VPC Endpoints** for S3 and DynamoDB so private instances
  access these services without going through NAT at all (saves cost)
- Enable **VPC Flow Logs** to CloudWatch for full network traffic
  visibility and security auditing
- Replace the bastion host with **AWS Systems Manager Session Manager**
  entirely — no open port 22, no key management
- Use **AWS Transit Gateway** when connecting multiple VPCs instead
  of individual VPC peering connections
- Apply **Network ACLs** as a second layer of defense on private subnets
  in addition to security groups
- Use **Terraform or CloudFormation** to manage VPC as code so it
  can be recreated identically in any region in minutes

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| Cannot delete VPC | Resources still inside it | Delete in order: EC2 → NAT GW → subnets → RTs → IGW → VPC |
| NAT Gateway stuck Pending | Normal startup time | Wait 2 min, check `describe-nat-gateways` |
| Private instance no internet | NAT route missing | Check 0.0.0.0/0 → NAT GW in private route table |
| Bastion SSH timeout | IP changed or SG rule wrong | Update bastion-sg rule with current IP |
| SSM won't connect | Profile not attached | Wait 3 min after attaching ec2-ssm-profile |
| EIP not releasing | NAT GW still exists | Wait for NAT GW state = deleted then release EIP |
| SG delete fails | Instance still attached | Terminate instances first, wait for terminated state |

---

## Resume Bullets

- Designed and deployed a production-grade custom AWS VPC with public
  and private subnets across two Availability Zones, following
  AWS Well-Architected Framework networking best practices
- Configured Internet Gateway, dual route tables, and NAT Gateway
  enabling public internet access for public subnets while restricting
  private subnets to outbound-only connectivity — verified via curl
  returning the NAT Gateway EIP from a private instance
- Implemented the bastion host security pattern using security group
  chaining to restrict private instance SSH access exclusively through
  a hardened jump host, eliminating direct internet exposure
- Managed the complete VPC lifecycle via AWS CLI v2 on Windows
  including creation, connectivity testing, and full ordered teardown

---

## Next Project

**Project 6 — RDS MySQL + EC2 Two-Tier Application**

Deploy a managed MySQL database in the private subnets of this
VPC architecture and connect it to an EC2 application server
in the public subnet — building a real two-tier application.

Services: RDS · EC2 · VPC · Security Groups · Parameter Store

---

## Further Reading

- [VPC User Guide — AWS Docs](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [NAT Gateway — AWS Docs](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [VPC CIDR Blocks](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-cidr-blocks.html)
- [Security Groups vs NACLs](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Security.html)
- [AWS Well-Architected — Network](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/network-protection.html)

---

*Part of the [AWS Cloud Engineering Bootcamp](../README.md)*
*14 projects · Beginner → Advanced · AWS Free Tier*