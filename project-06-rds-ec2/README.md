<div align="center">
  <img src="https://raw.githubusercontent.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/main/project-06-rds-ec2/architecture/architecture.svg" alt="Project 06 Architecture" width="800">
  <br/>
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="32" height="32" style="vertical-align: middle"/> Project 06: RDS MySQL + EC2 Two-Tier App</h1>
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
Deployed a production-style two-tier AWS architecture — an EC2
application server in a public subnet connecting to a managed
RDS MySQL database in private subnets, with credentials stored
securely in AWS Secrets Manager. The database is completely
isolated from the internet and accessible only through
security group chaining from the app server.

> **Real-world context:** This two-tier pattern (web/app tier +
> database tier) is the foundation of almost every web application
> running on AWS. Solutions Architects design this daily.
> Separating compute and data tiers is a core AWS best practice.

---

This project transforms standard infrastructure concepts into a high-end, production-ready implementation, providing extensive hands-on experience with RDS, EC2.

## 🚀 Learning Objectives
- Master **RDS** configuration and best practices.
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
  <b>[⬅️ Previous Project](../project-05-Custom-VPC) &nbsp; | &nbsp; [Next Project ➡️](../project-07-cloudwatch-monitoring)</b>
</div>
