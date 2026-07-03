# Comprehensive Troubleshooting Guide

Below is a list of common failure states encountered when provisioning and connecting to EC2 instances, along with root causes and remediation steps.

---

## 🌐 Network & Connectivity Errors

| Symptom / Error | Root Cause Analysis | Remediation Steps |
|:----------------|:--------------------|:------------------|
| **Browser spins indefinitely when trying to view the website** | The Security Group does not have an Inbound Rule allowing HTTP (Port 80). The packets are being dropped by the firewall. | Go to EC2 → Security Groups. Edit the inbound rules of your SG. Add a rule for HTTP (Port 80) from `0.0.0.0/0`. |
| **Browser says "Connection Refused" when trying to view the website** | The network traffic reached the server (Security Group is fine), but Apache is not running to accept the connection. Your User Data script likely failed or had a typo. | SSH into the instance and run `sudo systemctl status httpd`. If it's dead, run `sudo systemctl start httpd` and try the browser again. |
| **Cannot reach website via `https://`** | You did not install an SSL certificate on the server, nor did you open Port 443 in the Security Group. | Ensure your browser URL explicitly says `http://` and not `https://`. Some modern browsers force HTTPS by default. |

---

## 🔑 SSH & Authentication Errors

| Symptom / Error | Root Cause Analysis | Remediation Steps |
|:----------------|:--------------------|:------------------|
| **SSH command hangs and times out (`Operation timed out`)** | The Security Group does not allow Port 22 traffic from your current IP address. This usually happens if you change Wi-Fi networks (e.g., move from a cafe to your house) after creating the rule. | Go to EC2 → Security Groups. Edit the inbound rules. Find the SSH rule, change the Source dropdown to **My IP** again to inject your new IP, and save. |
| **`Permission denied (publickey)`** | 1. You are using the wrong `.pem` file.<br>2. You are using the wrong username (e.g., trying to log in as `root` instead of `ec2-user`). | 1. Ensure you specify `-i my-web-key.pem` exactly.<br>2. Ensure the command is `ssh -i key.pem ec2-user@IP`. |
| **`UNPROTECTED PRIVATE KEY FILE!` (Mac/Linux only)** | Your `.pem` file is readable by other users on your computer. SSH considers this compromised and refuses to use it. | Open terminal and run `chmod 400 my-web-key.pem` to lock down the file permissions. Then try SSH again. |

---

## 🏗️ Provisioning Errors

| Symptom / Error | Root Cause Analysis | Remediation Steps |
|:----------------|:--------------------|:------------------|
| **Cannot find `t2.micro` in the instance type list** | Some newer AWS regions (like `eu-north-1` or `af-south-1`) do not have older hardware like the `t2` family installed. | Select `t3.micro` instead. It is also eligible for the free tier in regions where `t2.micro` is absent. |