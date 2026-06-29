# Design Specifications

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

