# Architecture Details & System Design

This document outlines the network and security architecture required to safely provision a public-facing web server in AWS and connect to it for administration.

## 🏗️ System Overview & Network Flow

```mermaid
flowchart TD
    subgraph "The Public Internet"
        Admin([Administrator\n(Your Laptop)])
        Users([Web Users])
    end

    subgraph "AWS Cloud - Region (e.g., us-east-1)"
        subgraph "Default Virtual Private Cloud (VPC)"
            subgraph "Public Subnet"
                subgraph "Security Group (Firewall)"
                    EC2[Amazon EC2 Instance\n(Amazon Linux 2023)\nPublic IP Attached]
                    Apache{Apache Web Server\n(Port 80)}
                    SSHD{SSH Daemon\n(Port 22)}
                end
            end
        end
    end

    Admin -- "1. SSH over TCP Port 22\n(Uses .pem Private Key)" --> SSHD
    Users -- "2. HTTP over TCP Port 80\n(Plaintext Web Traffic)" --> Apache
    
    SSHD -.-> EC2
    Apache -.-> EC2
```

---

## 🧩 Architectural Components & Technical Deep Dive

### 1. The Default VPC (Virtual Private Cloud)
When you create a new AWS account, AWS automatically provisions a "Default VPC" in every region. This VPC is pre-configured with a public subnet and an Internet Gateway (IGW). This architecture relies on the Default VPC to simplify deployment. When the EC2 instance launches, it is assigned a Public IPv4 address that routes through the IGW directly to the internet.

### 2. The Amazon Machine Image (AMI)
An AMI is a master template of a virtual machine's root drive. We use the **Amazon Linux 2023** AMI for this project.
- **Why AL2023?** It is an RPM-based OS maintained directly by AWS. It is highly optimized for the EC2 hypervisor, boots extremely fast, and has the AWS CLI pre-installed.

### 3. Security Groups (Stateful Firewalls)
A Security Group acts as a virtual firewall operating at the instance level (Network Layer 4).
- **Inbound Rules:** By default, Security Groups deny *all* inbound traffic. We must explicitly open Port 22 (SSH) and Port 80 (HTTP). 
- **The "0.0.0.0/0" Anti-Pattern:** Opening Port 22 to `0.0.0.0/0` (the entire internet) is a massive security risk. Bots will constantly attempt to brute-force your server. In this architecture, we strictly limit Port 22 to your specific Home IP address (e.g., `203.0.113.45/32`). Port 80, however, must be open to `0.0.0.0/0` so the public can see the website.
- **Stateful Nature:** Security Groups are stateful. If you send a request out to the internet (e.g., `yum install httpd`), the response is automatically allowed back in, regardless of inbound rules.

### 4. Asymmetric Cryptography (SSH Key Pairs)
AWS does not allow password-based login to Linux instances by default.
- **The Public Key:** When the EC2 instance boots, AWS injects the public half of your key pair into the `~/.ssh/authorized_keys` file of the `ec2-user`.
- **The Private Key (`.pem`):** You download the private half to your local machine. When your terminal connects to Port 22, it proves its identity using this private key. If the keys match cryptographically, you are granted root-equivalent access.

### 5. Instance User Data
User Data is a script that runs exactly once, during the final stages of the very first boot cycle. It runs as the `root` user. In this architecture, we use a bash script to update the OS (`yum update`), install Apache (`yum install httpd`), start the service (`systemctl start httpd`), and write a simple HTML file to `/var/www/html/index.html`.