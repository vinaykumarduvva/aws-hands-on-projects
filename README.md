# ☁️ AWS Cloud Engineering Projects

A hands-on portfolio of AWS projects built from scratch using Free Tier resources,
documenting my journey from complete beginner to job-ready Cloud Engineer.
Each project includes full console + CLI instructions, architecture notes,
IAM policies, cleanup steps, and real-world context.

> 🎯 Target roles: AWS Solutions Architect · Cloud Support Engineer
> 📅 Timeline: 12-week intensive bootcamp
> 💰 Cost target: $0–$5/month (Free Tier focused)

---

## 👤 About Me

Hi, I'm Vinay Kumar Duvva — a self-taught cloud engineering student building real, production-style AWS infrastructure from the ground up.
This repo documents every project I complete, including what broke,
how I fixed it, and what I learned.

📍 Location: Hyderabad, India.

🔗 LinkedIn: https://www.linkedin.com/in/vinay-kumar-duvva/

📧 Contact: duvvavinaykumar@gmail.com

---

## 🗺️ Roadmap Overview

<img width="1220" height="1550" alt="image" src="https://github.com/user-attachments/assets/6b08d752-7cf1-472d-9efa-fb886a509a9b" />

---

| # | Project | Tier | Services | Status |
|---|---|---|---|---|
| 01 | [AWS Account Setup & IAM Foundations](https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/tree/main/project-01-iam-setup) | 🟢 Beginner | IAM, CloudWatch, SNS, CLI | ✅ Done |
| 02 | [Static Website on S3 + CloudFront](https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/tree/main/project-02-s3-static-website) | 🟢 Beginner | S3, CloudFront, Route 53 | ✅ Done |
| 03 | [Launch EC2 & Connect via SSH](project-3-Launch-EC2-Connect-via-SSH) | 🟢 Beginner | EC2, VPC, SG, SSM, IAM | ✅ Done |
| 04 | [S3 Versioning, Lifecycle & Replication](project-04-s3-versioning) | 🟢 Beginner | S3 | ✅ Done |
| 05 | [Custom VPC: Subnets, IGW, NAT](project-05-Custom-VPC) | 🟢 Beginner | VPC, EC2 | ✅ Done |
| 06 | [RDS MySQL + EC2 Two-Tier App](project-06-rds-ec2) | 🟢 Beginner | RDS, EC2, VPC, Secrets Manager | ✅ Done |
| 07 | [CloudWatch Alarms + SNS Alerts](project-07-cloudwatch-monitoring) | 🟢 Beginner | CloudWatch, SNS | ✅ Done |
| 08 | [Serverless REST API](project-08-serverless-rest-api) | 🟡 Intermediate | Lambda, API Gateway, DynamoDB | ✅ Done |
| 09 | [CI/CD Pipeline](https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/tree/main/project-09-cicd-pipeline) | 🟡 Intermediate | CodeCommit, CodeBuild, CodeDeploy | ✅ Done |
| 10 | Auto Scaling Group + ALB | 🟡 Intermediate | EC2, ALB, ASG | ⏳ Upcoming |
| 11 | Infrastructure as Code | 🟡 Intermediate | CloudFormation | ⏳ Upcoming |
| 12 | Event-Driven Pipeline | 🟡 Intermediate | S3, SQS, Lambda | ⏳ Upcoming |
| 13 | Containerized App on ECS Fargate | 🔴 Advanced | ECS, ECR, Fargate, ALB | ⏳ Upcoming |
| 14 | Capstone: 3-Tier HA Architecture | 🔴 Advanced | VPC, ALB, ASG, RDS Multi-AZ | ⏳ Upcoming |

---

## 🛠️ Tools & Technologies

| Category | Tools |
|---|---|
| Cloud Platform | Amazon Web Services (AWS) |
| CLI | AWS CLI v2 (Windows PowerShell) |
| IaC | AWS CloudFormation, (Terraform in capstone) |
| Containers | Docker, Amazon ECS Fargate, ECR |
| Languages | Bash, PowerShell, Python (Lambda), YAML |
| Version Control | Git, GitHub |
| Monitoring | CloudWatch, CloudTrail, SNS |

---

## 💡 AWS Services Covered

`IAM` `S3` `CloudFront` `EC2` `VPC` `RDS` `CloudWatch` `SNS`
`Lambda` `API Gateway` `DynamoDB` `CodeCommit` `CodeBuild`
`CodeDeploy` `CodePipeline` `ALB` `Auto Scaling` `CloudFormation`
`SQS` `ECS` `ECR` `Fargate` `Route 53` `CloudTrail`

---

## 💰 Cost Philosophy

Every project in this repo is designed to run on the **AWS Free Tier**.
Each project README includes:
- ✅ Free Tier compatibility status
- 💵 Best-case and worst-case cost estimates
- 🧹 Full cleanup instructions to avoid surprise charges

**Total spend across all 14 projects: target $0–$10**

---

## 🏆 Certifications Goal

- [ ] AWS Certified Cloud Practitioner (CLF-C02)
- [ ] AWS Certified Solutions Architect – Associate (SAA-C03)

---

## 📈 Skills Progress

| Skill | Level |
|---|---|
| IAM & Security | ⭐⭐⭐⭐☆ |
| Storage (S3) | ⭐⭐⭐☆☆ |
| Compute (EC2) | ⭐⭐⭐⭐☆ |
| Networking (VPC) | ⭐⭐⭐☆☆ |
| Monitoring & Observability | ⭐⭐⭐☆☆ |
| Serverless | ⭐⭐⭐☆☆ |
| Containers | ⭐☆☆☆☆ |
| IaC | ⭐☆☆☆☆ |
| DevOps / CI/CD | ⭐⭐⭐☆☆ |

*(Updated after each project)*

---

## 🔖 How to Use This Repo

Each project folder is self-contained and includes:
1. **README.md** — full setup guide (console + CLI)
2. **screenshots/** — proof of working setup
3. **scripts/** or **templates/** — reusable code and configs
4. **docs/** — architecture notes, IAM policies, troubleshooting logs

You can follow along in order (recommended for beginners)
or jump to any project if you have the prerequisites.

---

## ⚠️ Security Notice

- No AWS credentials, access keys, or secrets are stored in this repo
- `.gitignore` excludes all `*.csv`, `*.pem`, and `credentials` files
- All sensitive values use placeholder format: `<YOUR_ACCOUNT_ID>`

---

## 📜 License

MIT — feel free to fork, adapt, and build on this for your own learning journey.
