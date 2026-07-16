# Security Protocols

<div style="background-color: #fdfdfe; border-left: 4px solid #ff9900; padding: 15px; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
  <i>The following granular documentation is designed to provide enterprise-level clarity for deploying and managing this AWS architecture. Pay close attention to the architectural specifications and step-by-step methodologies below.</i>
</div>


## Security Architecture

This project implements a layered security model:

```text
Layer 1: ALB Security Group (alb-sg)
  → Controls who can reach the load balancer
  → HTTP:80 from 0.0.0.0/0 (public access)
  → HTTPS:443 from 0.0.0.0/0 (future)

Layer 2: EC2 Security Group (asg-ec2-sg)
  → Controls who can reach the instances
  → HTTP:80 from alb-sg ONLY (not from internet)
  → SSH:22 from MY_IP/32 (debugging only)

Layer 3: VPC Network
  → Default VPC with public subnets
  → Internet Gateway for outbound access
  → Route tables with default routes
```

---

## Security Group Design

### Why Two Security Groups?

Separating ALB and EC2 security groups is a best practice:

1. **Least privilege:** EC2 instances only accept traffic
   from the ALB, not directly from the internet.

2. **Defense in depth:** Even if someone discovers an
   instance's public IP, they cannot connect to port 80.

3. **Auditability:** Clear separation of concerns — ALB
   rules control public access, EC2 rules control internal access.

### ALB Security Group (alb-sg)

| Direction | Protocol | Port | Source | Purpose |
|---|---|---|---|---|
| Inbound | TCP | 80 | 0.0.0.0/0 | HTTP from internet |
| Inbound | TCP | 443 | 0.0.0.0/0 | HTTPS from internet |
| Outbound | All | All | 0.0.0.0/0 | Default (allow all) |

### EC2 Security Group (asg-ec2-sg)

| Direction | Protocol | Port | Source | Purpose |
|---|---|---|---|---|
| Inbound | TCP | 80 | alb-sg | HTTP from ALB only |
| Inbound | TCP | 22 | MY_IP/32 | SSH for debugging |
| Outbound | All | All | 0.0.0.0/0 | Default (allow all) |

---

## Security Group References

The EC2 security group references the ALB security group
by ID (not by CIDR). This means:

```text
Rule: Allow TCP 80 from sg-abc123 (alb-sg)

✅ Traffic from ALB (which has sg-abc123) → ALLOWED
❌ Traffic from internet (no sg-abc123) → DENIED
❌ Traffic from other instances → DENIED
```

This is more secure than CIDR-based rules because:
- ALB IP addresses can change (they are dynamic)
- Security group references are always accurate
- No need to update rules when IPs change

---

## SSH Access

SSH access is restricted to your current public IP:

```text
Rule: Allow TCP 22 from MY_IP/32

Purpose: Debugging only — connect to instances to:
  - Check Apache logs: journalctl -u httpd
  - Check user data log: cat /tmp/setup.log
  - Run stress tests: stress --cpu 1 --timeout 600
  - Verify instance metadata
```

> **Production:** Remove SSH access entirely.
> Use AWS Systems Manager Session Manager instead.
> It requires no inbound ports and logs all sessions.

---

## Key Pair

The Launch Template specifies `aws-ec2-keypair` for SSH
access. This key pair must exist in ap-south-1 before
creating the Launch Template.

```text
Key pair: aws-ec2-keypair
Type: RSA 2048-bit
Usage: SSH access to EC2 instances
Storage: Keep private key (.pem) secure locally
```

> **Production:** Use EC2 Instance Connect or SSM
> Session Manager. Key pairs are difficult to rotate
> and easy to lose.

---

## Instance Metadata

The user data script fetches instance metadata using
the Instance Metadata Service (IMDS):

```text
http://169.254.169.254/latest/meta-data/instance-id
http://169.254.169.254/latest/meta-data/placement/availability-zone
http://169.254.169.254/latest/meta-data/local-ipv4
```

> **Production:** Enforce IMDSv2 (token-based) in the
> Launch Template to prevent SSRF attacks:
>
> ```json
> "MetadataOptions": {
>   "HttpTokens": "required",
>   "HttpEndpoint": "enabled"
> }
> ```

---

## Network Security

### No Direct Instance Access

```text
Internet → ALB public IP → ALB routes to instance private IP
              (allowed)

Internet → Instance public IP → DENIED by asg-ec2-sg
              (blocked)
```

### Outbound Access

Instances have outbound internet access for:
- `yum update` and package installation
- Instance metadata service
- CloudWatch metrics reporting

> **Production:** Use NAT Gateway in private subnets
> to eliminate public IPs on instances entirely.

---

## Production Security Recommendations

| Area       | This Project              | Production                       |
| ------------| ---------------------------| ----------------------------------|
| HTTPS      | HTTP only                 | ACM certificate + HTTPS listener |
| SSH        | Key pair + IP restriction | SSM Session Manager (no port 22) |
| IMDS       | v1 (default)              | v2 (token-required)              |
| Subnets    | Public                    | Private subnets + NAT Gateway    |
| WAF        | None                      | AWS WAF on ALB                   |
| Logging    | None                      | ALB access logs to S3            |
| Encryption | None                      | TLS termination at ALB           |

---
