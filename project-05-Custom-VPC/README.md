<div align="center">
  <img src="https://raw.githubusercontent.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/main/project-05-Custom-VPC/architecture/architecture.svg" alt="Project 05 Architecture" width="800">
  <br/>
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="32" height="32" style="vertical-align: middle"/> Project 05: Custom VPC: Subnets, IGW, NAT</h1>
  <p><b>Beginner/Intermediate &nbsp; • &nbsp; 3-4 Hours &nbsp; • &nbsp; Cost: $0.00 (Free Tier)</b></p>
  <p>
    <a href="#purpose">Purpose</a> • 
    <a href="#architecture">Architecture</a> • 
    <a href="#deployment">Deployment</a> • 
    <a href="#docs">Docs</a>
  </p>
</div>

<br/>

## 🎯 Purpose
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

This project transforms standard infrastructure concepts into a high-end, production-ready implementation, providing extensive hands-on experience with VPC, EC2.

## 🚀 Learning Objectives
- Master **VPC** configuration and best practices.
- Implement secure, scalable infrastructure using AWS native tools.
- Understand the integration points between various AWS services.
- Automate deployment using cross-platform scripts.

## 📚 Documentation Suite
Dive deep into the specific mechanics of this project:
- 📄 [Project Overview](docs/project-overview.md)
- 🏗️ [Architecture Details](docs/architecture.md)
- 🚀 [Deployment Guide](docs/deployment-guide.md)
- 🔐 [Security Protocols](docs/security-protocols.md)
- 🧪 [Testing Procedures](docs/testing-procedures.md)
- 🛠️ [Troubleshooting](docs/troubleshooting.md)

## 💻 Automation Scripts
This project contains ready-to-run automation scripts for both **PowerShell** and **Bash**.
- 🖥️ **Windows Users:** Use `scripts/powershell/`
- 🐧 **Linux/Mac Users:** Use `scripts/bash/`

---
<div align="center">
  <b>[⬅️ Previous Project](../project-04-s3-versioning) &nbsp; | &nbsp; [Next Project ➡️](../project-06-rds-ec2)</b>
</div>
