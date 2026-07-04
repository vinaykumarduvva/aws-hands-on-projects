## VPC Fundamentals

### What is a VPC?
A Virtual Private Cloud is your own logically isolated section
of the AWS cloud. Think of it as your private data center inside AWS.

- You define the IP address range (CIDR block)
- You control all inbound and outbound traffic
- No other AWS customer can see inside your VPC
- One VPC can span multiple Availability Zones
- One AWS region can have multiple VPCs (default limit: 5)

### Default VPC vs Custom VPC

| Feature       | Default VPC             | Custom VPC           |
| ---------------| -------------------------| ----------------------|
| Created by    | AWS automatically       | You create it        |
| CIDR          | 172.31.0.0/16 (fixed)   | You choose           |
| Subnets       | One per AZ, all public  | You design           |
| IGW           | Already attached        | You attach           |
| Use case      | Quick testing           | Production workloads |
| Best practice | Never use in production | Always use this      |

---

## CIDR Blocks Explained

CIDR = Classless Inter-Domain Routing
Notation: IP_ADDRESS/PREFIX_LENGTH

The prefix length determines how many IPs are in the range:

| CIDR | Total IPs | Usable IPs (AWS) | Common Use |
|---|---|---|---|
| /16 | 65,536 | 65,531 | Entire VPC |
| /24 | 256 | 251 | Single subnet |
| /28 | 16 | 11 | Smallest AWS subnet |
| /32 | 1 | 1 | Single IP address (SG rules) |

### Our VPC CIDR Design
```
10.0.0.0/16    ← Entire VPC (65,536 IPs)
├── 10.0.1.0/24  ← Public Subnet A  (256 IPs)
├── 10.0.2.0/24  ← Public Subnet B  (256 IPs)
├── 10.0.3.0/24  ← Private Subnet A (256 IPs)
└── 10.0.4.0/24  ← Private Subnet B (256 IPs)
    10.0.5.0 → 10.0.255.0 ← Reserved for future subnets
```

### AWS Reserved IPs Per Subnet (why 256 becomes 251)
For subnet 10.0.1.0/24:
- 10.0.1.0   → Network address (reserved)
- 10.0.1.1   → VPC router (reserved)
- 10.0.1.2   → DNS server (reserved)
- 10.0.1.3   → Future use (reserved)
- 10.0.1.255 → Broadcast (reserved)
- 10.0.1.4 → 10.0.1.254 → YOUR usable IPs (251 addresses)

---

## Internet Gateway (IGW)

### What it does
- Connects your VPC to the public internet
- Horizontally scaled, redundant, and highly available (AWS manages it)
- No bandwidth limits
- Enables both inbound and outbound internet traffic

### Rules
- One IGW per VPC
- Must be explicitly attached to a VPC
- Not enough alone — also need a route table entry
- Free of charge

### How traffic flows through IGW
```
EC2 instance (10.0.1.5)
    │
    ▼
Route table: 0.0.0.0/0 → igw-xxxxxxxx
    │
    ▼
Internet Gateway
    │
    ▼
Public Internet
    │
    ▼ (return traffic)
Internet Gateway
    │
    ▼
Route table: local → 10.0.0.0/16
    │
    ▼
EC2 instance (10.0.1.5)
```

---

## NAT Gateway

### What it does
Allows instances in PRIVATE subnets to initiate outbound
connections to the internet while preventing inbound
connections from the internet.

NAT = Network Address Translation
- Takes private IP (10.0.3.x) and translates to its own EIP
- Internet sees the NAT Gateway's IP, not the private instance's IP
- Return traffic is sent back to NAT, which forwards to private instance
- NO inbound connections possible (internet cannot initiate to private IP)

### NAT Gateway vs NAT Instance

| Feature | NAT Gateway (AWS managed) | NAT Instance (EC2) |
|---|---|---|
| Management | AWS manages it | You manage it |
| Availability | Highly available per AZ | Single point of failure |
| Bandwidth | Up to 100 Gbps | Limited by instance type |
| Cost | $0.045/hr + data | EC2 cost only |
| Security groups | Cannot attach | Can attach |
| Recommended | ✅ Yes | ❌ Legacy only |

### NAT Gateway placement rule
NAT Gateway MUST live in a PUBLIC subnet.
It needs an Elastic IP (public IP) to talk to the internet.

```
Private Instance (10.0.3.x) — no public IP
    │ outbound request to 8.8.8.8
    ▼
Private Route Table: 0.0.0.0/0 → NAT Gateway
    │
    ▼
NAT Gateway (in public-subnet-a, has EIP: 3.x.x.x)
    │ translates 10.0.3.x → 3.x.x.x
    ▼
Public Route Table: 0.0.0.0/0 → IGW
    │
    ▼
Internet (sees request from 3.x.x.x — the NAT Gateway EIP)
```

---

## Route Tables

### How routing decisions are made
AWS uses longest prefix match — the most specific route wins.

Example — traffic from a private instance going to 8.8.8.8:
```
Route table has:
  10.0.0.0/16 → local       (matches 10.x addresses)
  0.0.0.0/0   → nat-gateway (matches everything else)

8.8.8.8 does NOT match 10.0.0.0/16
8.8.8.8 DOES match 0.0.0.0/0
Result → traffic goes to NAT Gateway ✅
```

Example — traffic going to another instance at 10.0.1.5:
```
10.0.1.5 DOES match 10.0.0.0/16 (local)
Result → traffic stays inside VPC via local route ✅
```

### Route table association rules
- Every subnet must be associated with exactly ONE route table
- One route table can be associated with multiple subnets
- If no explicit association — subnet uses the VPC main route table
- Main route table should never have a 0.0.0.0/0 → IGW route
  (that would make all unassociated subnets accidentally public)

---

## Security Groups vs Network ACLs

| Feature | Security Group | Network ACL |
|---|---|---|
| Level | Instance level | Subnet level |
| State | Stateful | Stateless |
| Rules | Allow only | Allow AND Deny |
| Return traffic | Automatic | Must explicitly allow |
| Order | All rules evaluated | Rules evaluated by number |
| Default | Deny all inbound | Allow all in and out |
| Applies to | ENI (network card) | Subnet boundary |

### Stateful vs Stateless explained

**Security Group (stateful):**
```
You allow inbound port 80 (HTTP)
A request comes in on port 80 ✅
The response goes out on a random high port (e.g. 49152)
Security group automatically allows the response ✅
You only need ONE inbound rule — response is automatic
```

**Network ACL (stateless):**
```
You allow inbound port 80 (HTTP)
A request comes in on port 80 ✅
The response tries to go out on port 49152
NACL checks outbound rules — no matching rule ❌
You need BOTH an inbound rule AND an outbound ephemeral port rule
```

### When to use NACLs
- As a second layer of defense on top of security groups
- When you need to explicitly DENY a specific IP (SGs cannot deny)
- For subnet-wide rules that apply to everything in the subnet

### Our security group design
```
bastion-sg:
  Inbound:  Port 22 ← My IP /32 only
  Outbound: All traffic (default)

private-sg:
  Inbound:  Port 22 ← bastion-sg (security group ID, not CIDR)
  Outbound: All traffic (default)

Why reference the SG instead of an IP?
  If the bastion is stopped and restarted, its private IP changes.
  But it keeps the same security group.
  The rule still works without any updates.
  This is security group chaining — the production pattern.
```

---

## Bastion Host Pattern

### What is a bastion host?
A hardened EC2 instance in a public subnet that serves as
the only entry point to reach instances in private subnets.
Also called a jump host or jump box.

```
Internet
   │
   │ SSH port 22
   ▼
Bastion Host (public subnet, public IP)
   │
   │ SSH port 22 (private IP only)
   ▼
Private Instance (private subnet, NO public IP)
```

### Why not just open SSH directly to private instances?
- Private instances have no public IP — unreachable by design
- Even with EIP, directly exposed SSH is a security risk
- The bastion is the single hardened point you secure tightly
- All SSH traffic is logged on the bastion (audit trail)
- If compromised, only the bastion is exposed — not all instances

### Modern alternative — Session Manager
AWS Systems Manager Session Manager replaces the bastion pattern:
- No open port 22 needed anywhere
- No key pair management
- Full session logging to CloudWatch and S3
- Access controlled via IAM policies
- Works through HTTPS (port 443 outbound) — firewall friendly

---

## Availability Zone Design

### Why two AZs?
```
Single AZ deployment:
  AZ-A fails → entire application goes down ❌

Multi-AZ deployment:
  AZ-A fails → AZ-B still serving traffic ✅
```

### Our two-AZ design
```
us-east-1a          us-east-1b
├── public-subnet-a  ├── public-subnet-b
│   └── Bastion      │   └── (future ALB node)
└── private-subnet-a └── private-subnet-b
    └── App server       └── (future RDS standby)
```

### High availability NAT Gateway rule
One NAT Gateway per AZ for true HA:
```
If NAT GW in AZ-A fails:
  Bad:  Private instances in AZ-B still route to AZ-A NAT → fails
  Good: Private instances in AZ-B use their own NAT in AZ-B → works
```

We used one NAT Gateway for cost savings in this lab.
Production should always use one NAT Gateway per AZ.

---

## IP Address Types in AWS

| Type | Example | Persists on stop? | Cost |
|---|---|---|---|
| Private IP | 10.0.1.5 | Yes | Free |
| Public IP (dynamic) | 54.123.45.67 | No — changes on restart | Free |
| Elastic IP (EIP) | 3.123.45.67 | Yes — static | Free when attached |
| IPv6 | 2600:1f18:... | Yes | Free |

### When to use Elastic IP
- NAT Gateway always requires an EIP
- When you need a permanent public IP that survives restarts
- When external systems whitelist your IP (firewall rules)
- When you run DNS records pointing to an EC2 instance

### EIP cost warning
An EIP costs ~$0.005/hr when NOT attached to a running instance.
Always release EIPs after deleting NAT Gateways and EC2 instances.

---

## VPC Limits to Know (Service Quotas)

| Resource                 | Default Limit            |
| --------------------------| --------------------------|
| VPCs per region          | 5                        |
| Subnets per VPC          | 200                      |
| IGWs per region          | 5                        |
| NAT Gateways per AZ      | 5                        |
| Route tables per VPC     | 200                      |
| Security groups per VPC  | 2,500                   |
| Rules per security group | 60 inbound + 60 outbound |
| EIPs per region          | 5                        |

All limits can be increased by requesting a Service Quota increase
in the AWS console (Service Quotas → AWS Services → Amazon VPC).
