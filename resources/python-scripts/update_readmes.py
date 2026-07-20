import os
import re
import shutil

ROOT_DIR = r"e:\AWS Hands-on Projects"

PROJECT_META = {
    "01": {"title": "AWS Account Setup & IAM Foundations", "time": "1-2 Hours", "services": ["IAM", "SNS", "CloudWatch"]},
    "02": {"title": "Static Website on S3 + CloudFront", "time": "2-3 Hours", "services": ["S3", "CloudFront"]},
    "03": {"title": "Launch EC2 & Connect via SSH", "time": "2-3 Hours", "services": ["EC2", "VPC", "SSM"]},
    "04": {"title": "S3 Versioning, Lifecycle & Replication", "time": "2-3 Hours", "services": ["S3"]},
    "05": {"title": "Custom VPC: Subnets, IGW, NAT", "time": "3-4 Hours", "services": ["VPC", "EC2"]},
    "06": {"title": "RDS MySQL + EC2 Two-Tier App", "time": "3-4 Hours", "services": ["RDS", "EC2"]},
    "07": {"title": "CloudWatch Alarms + SNS Alerts", "time": "2-3 Hours", "services": ["CloudWatch", "SNS"]},
    "08": {"title": "Serverless REST API", "time": "3-4 Hours", "services": ["API Gateway", "Lambda", "DynamoDB"]},
    "09": {"title": "CI/CD Pipeline", "time": "4-5 Hours", "services": ["CodeCommit", "CodeBuild", "CodeDeploy"]},
    "10": {"title": "Auto Scaling Group + ALB", "time": "4-5 Hours", "services": ["EC2", "ALB", "ASG"]},
    "11": {"title": "Infrastructure as Code", "time": "4-5 Hours", "services": ["CloudFormation"]},
    "12": {"title": "Event-Driven Pipeline", "time": "4-5 Hours", "services": ["S3", "SQS", "Lambda"]}
}

def generate_readme(num, meta):
    title = f"Project {num}: {meta['title']}"
    img_url = f"https://raw.githubusercontent.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/main/project-{num}-{meta['title'].replace(' ', '-').lower()}/architecture/architecture.svg"
    # Header
    header = f'''<div align="center">
  <img src="{img_url}" alt="Project {num} Architecture" width="800">
  <br/>
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="32" height="32" style="vertical-align: middle"/> {title}</h1>
  <p><b>Beginner/Intermediate &nbsp; • &nbsp; {meta['time']} &nbsp; • &nbsp; Cost: $0.00 (Free Tier)</b></p>
  <p>
    <a href="#purpose">Purpose</a> • 
    <a href="#architecture">Architecture</a> • 
    <a href="#deployment">Deployment</a> • 
    <a href="#docs">Docs</a>
  </p>
</div>

<br/>
'''
    # Essentials
    essentials = f'''## 🚀 Essentials
**Description:** {meta['title']} – a hands‑on lab that demonstrates {', '.join(meta['services'])} integration on AWS.

**Badges:** | Build Status | License |
|---|---|
| ![Build Status](https://img.shields.io/badge/build‑passing-brightgreen) | ![License](https://img.shields.io/badge/license-MIT-blue) |

**Live Demo:** (coming soon – host on AWS Console or provide a static URL)
'''
    # Setup & Installation
    setup = f'''## 🛠️ Setup & Installation
**Prerequisites:**
- AWS CLI v2 installed and configured
- Appropriate IAM permissions for the services listed
- Python 3.9+ (if using Lambda layer scripts)

**Installation Steps:**
```bash
# Clone the repository
git clone https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects.git
cd project-{num}-{meta['title'].replace(' ', '-').lower()}
# Run the provided automation scripts (choose PowerShell or Bash)
# For Bash (Linux/macOS)
./scripts/bash/01-create-s3.sh   # example step
```

**Environment Variables:** (example placeholders)
```bash
export AWS_REGION=ap-south-1
export PROJECT_TAG=project-{num}
```

**Run Commands:**
```bash
# Deploy the full stack
./scripts/bash/05-deploy-all.sh
```
'''
    # Usage & Features
    usage = f'''## 📖 Usage & Features
**Core Features:**
- End‑to‑end provisioning of {', '.join(meta['services'])}
- Automated teardown scripts for clean‑up
- Inline documentation and comments

**Code Example:**
```bash
# List created resources
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=project-{num}
```

**Visual Preview:**
![Architecture Diagram]({img_url})
'''
    # Contribution & Maintenance
    contrib = '''## 🤝 Contribution & Maintenance
**Testing Instructions:**
```bash
# Run unit tests (if any)
pytest tests/
```

**Deployment Guide:**
- Follow the Deployment Guide in `docs/deployment-guide.md` for production.

**Contributing Guidelines:**
- Fork the repo, create a feature branch, and submit a PR.
- Follow the existing code style and linting rules.
- Ensure all new scripts are added to both `scripts/powershell/` and `scripts/bash/`.

**License:** MIT License (see LICENSE file).

**Contact / Credits:**
- Author: Vinay Kumar (GitHub: [vinay1515](https://github.com/vinay1515))
- For questions, open an issue or reach out via email.
'''
    # Navigation Footer
    prev_link = f"[⬅️ Previous Project](../project-{int(num)-1:02d}-{'placeholder' if int(num)==1 else ''})" if int(num) > 1 else ""
    next_link = f"[Next Project ➡️](../project-{int(num)+1:02d}-{'placeholder' if int(num)==12 else ''})" if int(num) < 12 else ""
    footer = f'''---
<div align="center">
  <b>{prev_link} &nbsp; | &nbsp; {next_link}</b>
</div>
'''
    return header + essentials + setup + usage + contrib + footer

def main():
    for num, meta in PROJECT_META.items():
        proj_dir = f"project-{num}-{meta['title'].replace(' ', '-').lower()}"
        path = os.path.join(ROOT_DIR, proj_dir)
        readme_path = os.path.join(path, "README.md")
        if not os.path.isdir(path):
            continue
        new_content = generate_readme(num, meta)
        with open(readme_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Updated {readme_path}")

if __name__ == "__main__":
    main()
