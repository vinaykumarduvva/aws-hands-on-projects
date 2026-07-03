# Comprehensive Deployment Guide

This guide details the complete process for provisioning a secure EC2 instance, attaching firewall rules, injecting bootstrap scripts, and connecting via SSH.

---

## 🚀 PRE-FLIGHT CHECKS

Run these commands in PowerShell to confirm your environment is ready:
```powershell
# Confirm you are authenticated
aws sts get-caller-identity

# Confirm your default region
aws configure get region

# Check for existing Key Pairs
aws ec2 describe-key-pairs
```

---

## 🔑 PART 1 — GENERATE THE SSH KEY PAIR

We must create the cryptographic keys before launching the server.

### Console Execution
1. Navigate to the **EC2 Dashboard**.
2. In the left menu, scroll down to **Network & Security** → **Key Pairs**.
3. Click **Create key pair**.
4. **Name:** `my-web-key`
5. **Key pair type:** `RSA`
6. **Private key file format:** `.pem` (Choose `.ppk` *only* if you are using an older version of PuTTY on Windows).
7. Click **Create key pair**.
8. **CRITICAL:** Your browser will download `my-web-key.pem`. Move this file to a secure, permanent location on your hard drive (e.g., `~/.ssh/` on Mac/Linux or `C:\Users\YourName\.ssh\` on Windows). You cannot download this file a second time.

---

## 🛡️ PART 2 — CONFIGURE THE SECURITY GROUP (FIREWALL)

We must define the network boundary before attaching it to the instance.

### Console Execution
1. In the left menu, go to **Network & Security** → **Security Groups**.
2. Click **Create security group**.
3. **Security group name:** `web-server-sg`
4. **Description:** `Allow SSH from my IP and HTTP from anywhere`
5. **VPC:** Leave as the default VPC.
6. **Inbound rules:**
   - Click **Add rule**.
   - **Type:** `SSH` (Port 22).
   - **Source:** Select **My IP**. (AWS will automatically inject your current public IP address).
   - Click **Add rule** again.
   - **Type:** `HTTP` (Port 80).
   - **Source:** Select **Anywhere-IPv4** (`0.0.0.0/0`).
7. Click **Create security group**.

---

## 🏗️ PART 3 — LAUNCH THE EC2 INSTANCE

We will now combine the Key Pair, Security Group, and an AMI to spawn the virtual machine.

### Console Execution
1. In the left menu, go to **Instances** → **Instances**.
2. Click **Launch instances**.
3. **Name and tags:** Type `My-First-Web-Server`.
4. **Application and OS Images (AMI):** Select the **Amazon Linux** tab. Ensure `Amazon Linux 2023 AMI` is selected and it says "Free tier eligible".
5. **Instance type:** Ensure `t2.micro` (or `t3.micro`) is selected.
6. **Key pair (login):** Select the `my-web-key` you created in Part 1 from the dropdown.
7. **Network settings:** 
   - Click **Edit**.
   - Ensure **Auto-assign public IP** is set to **Enable**.
   - Under Firewall, choose **Select existing security group**.
   - Check the box next to `web-server-sg`.
8. **Advanced details (User Data):**
   - Scroll all the way to the bottom and expand **Advanced details**.
   - Scroll to the bottom again to the **User data** text box.
   - Paste the following bash script exactly as shown:
```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello from my first AWS EC2 Web Server!</h1><p>Bootstrapping successful.</p>" > /var/www/html/index.html
```
9. Click **Launch instance** on the right sidebar.
10. Click the instance ID link (e.g., `i-0abcd1234efgh5678`) to view it in the dashboard. Wait until the **Instance state** turns green (`Running`) and the **Status check** says `2/2 checks passed`.

---

## 🌐 PART 4 — VALIDATE THE WEB SERVER

1. Select your running instance in the EC2 dashboard.
2. In the bottom details pane, copy the **Public IPv4 address** (e.g., `54.123.45.67`).
3. Open a new tab in your web browser.
4. Type `http://54.123.45.67` (ensure it is `http://` and not `https://`).
5. You should see your "Hello from my first AWS EC2 Web Server!" message. The User Data script worked!

---

## 💻 PART 5 — CONNECT VIA SSH (TERMINAL)

### For Windows 10/11, Mac, or Linux (Using built-in SSH client)
1. Open PowerShell or Terminal.
2. Navigate to the folder where you saved `my-web-key.pem`.
   ```powershell
   cd C:\Users\YourName\.ssh
   ```
3. Secure the key file (Mac/Linux only):
   ```bash
   chmod 400 my-web-key.pem
   ```
4. Run the SSH command. The default username for Amazon Linux is `ec2-user`. Replace the IP with your instance's Public IP.
   ```powershell
   ssh -i my-web-key.pem ec2-user@54.123.45.67
   ```
5. Type `yes` when prompted about the authenticity of the host.
6. You are now logged into the server! You will see the Amazon Linux ASCII art logo.

> [!TIP]
> **Enterprise Alternative:** In modern enterprise environments, opening Port 22 is often strictly prohibited. Instead, engineers use **AWS Systems Manager (SSM) Session Manager** to connect via the browser securely without keys or open ports. You can test this by selecting your instance in the console, clicking **Connect**, choosing the **Session Manager** tab, and clicking Connect.