
<div align="center">
  <svg width="800" height="150" xmlns="http://www.w3.org/2000/svg">
    <style>
      .bg { fill: url(#grad); stroke: #e1e4e8; stroke-width: 2px; rx: 12px; }
      .title { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 28px; font-weight: 800; fill: #ffffff; }
      .subtitle { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 16px; font-weight: 500; fill: #e1e4e8; }
      .glow { animation: pulse 3s infinite alternate; }
      @keyframes pulse {
        0% { opacity: 0.8; filter: drop-shadow(0 0 4px rgba(255,153,0,0.4)); }
        100% { opacity: 1; filter: drop-shadow(0 0 12px rgba(255,153,0,0.9)); }
      }
      @media (prefers-color-scheme: dark) {
        .bg { stroke: #30363d; }
      }
    </style>
    <defs>
      <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" style="stop-color:#232f3e;stop-opacity:1" />
        <stop offset="100%" style="stop-color:#ff9900;stop-opacity:1" />
      </linearGradient>
    </defs>
    <rect width="100%" height="100%" class="bg" />
    <text x="50%" y="45%" dominant-baseline="middle" text-anchor="middle" class="title glow">EC2 Launch & SSH</text>
    <text x="50%" y="70%" dominant-baseline="middle" text-anchor="middle" class="subtitle">design-specifications.md</text>
  </svg>
</div>



<div align="center" style="margin: 30px 0; padding: 15px; border: 1px solid #e1e4e8; border-radius: 8px; background-color: #f6f8fa;">
  <table style="width: 100%; text-align: center; border: none; background: transparent;">
    <tr style="border: none;">
      <td style="width: 33%; border: none;"><a href='../../project-02-s3-static-website/README.md' style='font-size: 16px; text-decoration: none;'>⏪ <b>Previous: S3 Static Website</b></a></td>
      <td style="width: 33%; border: none;"><a href="../README.md" style="font-size: 16px; text-decoration: none;">🏠 <b>Project Home</b></a></td>
      <td style="width: 33%; border: none;"><a href='../../project-04-s3-versioning/README.md' style='font-size: 16px; text-decoration: none;'><b>Next: S3 Versioning</b> ⏩</a></td>
    </tr>
  </table>
</div>


<br>

<div style="background-color: #fdfdfe; border-left: 4px solid #ff9900; padding: 15px; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
  <i>The following granular documentation is designed to provide enterprise-level clarity for deploying and managing this AWS architecture. Pay close attention to the architectural specifications and step-by-step methodologies below.</i>
</div>

<br>

## 🛡️ Enterprise Security Group Specifications (Firewall Rules)

In AWS, a **Security Group** acts as a virtual firewall operating at the instance level (Network Layer 4). It strictly dictates what traffic can reach the Elastic Network Interface (ENI) attached to your EC2 instance.

**Security Group Name:** `ec2-web-sg`
**VPC:** Default VPC

| Direction | Port Range | Protocol | Source / Destination | Business Purpose |
|---|---|---|---|---|
| **Inbound** | 22 | TCP | `<Your-Public-IP>/32` | **Administration:** Restricts SSH access exclusively to your current physical location, mitigating global brute-force attacks. |
| **Inbound** | 80 | TCP | `0.0.0.0/0` | **Public Web Traffic:** Allows any anonymous user on the internet to view the Apache website over unencrypted HTTP. |
| **Outbound** | All | All | `0.0.0.0/0` | **Egress Traffic:** Allows the server to initiate connections outward (e.g., to download OS updates via `yum` or clone repos via `git`). |

### 🧠 Architectural Concept: Stateful Firewalls
Security groups are **stateful**. This means if you send a request from your EC2 instance out to the internet (e.g., running `curl https://google.com`), the response traffic from Google is *automatically* allowed back in, regardless of your inbound rules. 
*(Contrast this with Network ACLs, which operate at the subnet level and are stateless, requiring explicit return rules).*

---

## 🔐 Identity & Access Management: The EC2 Instance Profile

If your EC2 instance needs to interact with other AWS services (like reading from an S3 bucket or communicating with AWS Systems Manager), it requires AWS credentials.

### The Anti-Pattern: Hardcoded Access Keys
Never run `aws configure` inside an EC2 instance or hardcode an `Access Key ID` and `Secret Access Key` into a script. If a hacker breaches your web server (e.g., via a PHP vulnerability), they can easily steal those plaintext keys and compromise your entire AWS account.

### The Enterprise Standard: IAM Roles & Instance Profiles
Instead, we attach an **IAM Role** to the EC2 instance using a container called an **Instance Profile**.

```json
{
  "RoleName": "ec2-ssm-role",
  "TrustedEntity": {
    "Service": "ec2.amazonaws.com"
  },
  "AttachedPolicy": "AmazonSSMManagedInstanceCore"
}
```

**How it works under the hood:**
1. The Trust Policy allows the EC2 hypervisor (`ec2.amazonaws.com`) to assume the role on behalf of the virtual machine.
2. AWS automatically generates temporary, cryptographically signed credentials (valid for a few hours).
3. AWS injects these temporary credentials into the instance's localized metadata service (`http://169.254.169.254/latest/meta-data/`).
4. The AWS CLI or SDKs running on the server automatically fetch and use these credentials transparently. The keys rotate automatically, completely neutralizing the risk of long-term credential theft.

---

<br>


<div align="center" style="margin: 30px 0; padding: 15px; border: 1px solid #e1e4e8; border-radius: 8px; background-color: #f6f8fa;">
  <table style="width: 100%; text-align: center; border: none; background: transparent;">
    <tr style="border: none;">
      <td style="width: 33%; border: none;"><a href='../../project-02-s3-static-website/README.md' style='font-size: 16px; text-decoration: none;'>⏪ <b>Previous: S3 Static Website</b></a></td>
      <td style="width: 33%; border: none;"><a href="../README.md" style="font-size: 16px; text-decoration: none;">🏠 <b>Project Home</b></a></td>
      <td style="width: 33%; border: none;"><a href='../../project-04-s3-versioning/README.md' style='font-size: 16px; text-decoration: none;'><b>Next: S3 Versioning</b> ⏩</a></td>
    </tr>
  </table>
</div>

