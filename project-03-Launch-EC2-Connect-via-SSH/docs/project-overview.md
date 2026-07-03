# Comprehensive Project Overview: Launching EC2 & Connecting via SSH

## 🎯 Executive Summary & Purpose
The Amazon Elastic Compute Cloud (EC2) is the foundational building block of the modern internet. While serverless technologies like Lambda and S3 are growing, the vast majority of enterprise applications, databases, and legacy systems still run on virtual machines.

The purpose of this project is to provision your first virtual Linux server on AWS and establish a secure, encrypted connection to it. You will learn to navigate the complexities of:
- **Compute Provisioning:** Selecting the correct Amazon Machine Image (AMI), instance family, and instance size (`t2.micro`).
- **Network Security:** Configuring Security Groups (virtual firewalls) to strictly control inbound and outbound traffic.
- **Cryptographic Authentication:** Generating and utilizing asymmetric key pairs (RSA `.pem` files) to securely SSH into the Linux server without passwords.
- **Application Deployment:** Using a Bash script in the EC2 "User Data" field to automatically install and launch an Apache Web Server (`httpd`) the moment the server boots.

Mastering EC2 and SSH is an absolute prerequisite for any career in Cloud Engineering, DevOps, or Backend Software Development.

---

## 📚 Detailed Learning Objectives
Upon completing this module, you will be able to:
1. **Understand EC2 Architecture:** Differentiate between Instance Types (e.g., compute-optimized vs. memory-optimized) and Storage types (EBS vs. Instance Store).
2. **Master Security Groups:** Write strict firewall rules that allow TCP Port 22 (SSH) only from your specific IP address, while allowing TCP Port 80 (HTTP) from the world.
3. **Manage SSH Key Pairs:** Understand the difference between public and private keys, and how to securely store a `.pem` file on a Windows or Mac machine.
4. **Automate Bootstrapping:** Inject Bash scripts into the EC2 User Data to install software (Apache/PHP) without manual intervention.
5. **Connect via Multiple Protocols:** Access the server using traditional terminal SSH (PuTTY/OpenSSH) and AWS Systems Manager Session Manager (SSM) — a secure, browser-based alternative.

---

## 🛠️ AWS Services & Technologies Utilized
| Service | Primary Role in this Project | Key Concepts Explored |
|---------|------------------------------|-----------------------|
| **Amazon EC2** | Virtual Compute Server | AMIs, Instance Types, User Data Bootstrapping |
| **Amazon VPC** | Network Boundary | Default VPC, Subnets, Public IP Assignment |
| **Security Groups** | Virtual Firewall | Inbound/Outbound Rules, Stateful vs. Stateless |
| **Key Pairs** | Authentication | Asymmetric Cryptography (RSA/ED25519) |

---

## 📦 Deep Dive: The EC2 Instance Lifecycle
Understanding the state of your EC2 instance is critical for cost management:
- **Running:** The instance is powered on. You are billed by the second for compute (CPU/RAM).
- **Stopped:** The instance is powered off. The compute hardware is released back to AWS. **You are NOT billed for compute,** but you are still billed a few cents for the Elastic Block Store (EBS) hard drive that holds your data.
- **Terminated:** The instance is permanently destroyed, along with its root EBS volume. You are no longer billed for anything.

---

## ✅ Cost Control & Financial Governance
This project utilizes the `t2.micro` or `t3.micro` instance type, which is eligible for the AWS Free Tier.

| Resource Category | Free Tier Allowance (First 12 Months) | Expected Usage in Project |
|-------------------|---------------------------------------|---------------------------|
| **EC2 Linux t2.micro** | 750 Hours per month | A few hours max. |
| **EBS General Purpose SSD (gp2/gp3)** | 30 GB per month | 8 GB allocated for the root volume. |
| **Public IPv4 Address** | AWS charges $0.005/hr for public IPs. | ~$0.02 total (Free tier covers 750 hours of public IP if attached to a free tier EC2). |

> [!WARNING]
> If your account is older than 12 months, the Free Tier for EC2 has expired. Running a `t2.micro` costs approximately $8.50 per month. Always `Terminate` your instance when finished with this lab.