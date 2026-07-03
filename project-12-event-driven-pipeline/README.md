<div align="center">
  <img src="https://raw.githubusercontent.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/main/project-12-event-driven-pipeline/architecture/architecture.svg" alt="Project 12 Architecture" width="800">
  <br/>
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="32" height="32" style="vertical-align: middle"/> Project 12: Event-Driven Pipeline</h1>
  <p><b>Beginner/Intermediate &nbsp; • &nbsp; 4-5 Hours &nbsp; • &nbsp; Cost: $0.00 (Free Tier)</b></p>
  <p>
    <a href="#purpose">Purpose</a> • 
    <a href="#architecture">Architecture</a> • 
    <a href="#deployment">Deployment</a> • 
    <a href="#docs">Docs</a>
  </p>
</div>

<br/>
## 🚀 Essentials
**Description:** Event-Driven Pipeline – a hands‑on lab that demonstrates S3, SQS, Lambda integration on AWS.

**Badges:** | Build Status | License |
|---|---|
| ![Build Status](https://img.shields.io/badge/build‑passing-brightgreen) | ![License](https://img.shields.io/badge/license-MIT-blue) |

**Live Demo:** (coming soon – host on AWS Console or provide a static URL)
## 🛠️ Setup & Installation
**Prerequisites:**
- AWS CLI v2 installed and configured
- Appropriate IAM permissions for the services listed
- Python 3.9+ (if using Lambda layer scripts)

**Installation Steps:**
```bash
# Clone the repository
git clone https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects.git
cd project-12-event-driven-pipeline
# Run the provided automation scripts (choose PowerShell or Bash)
# For Bash (Linux/macOS)
./scripts/bash/01-create-s3.sh   # example step
```

**Environment Variables:** (example placeholders)
```bash
export AWS_REGION=ap-south-1
export PROJECT_TAG=project-12
```

**Run Commands:**
```bash
# Deploy the full stack
./scripts/bash/05-deploy-all.sh
```
## 📖 Usage & Features
**Core Features:**
- End‑to‑end provisioning of S3, SQS, Lambda
- Automated teardown scripts for clean‑up
- Inline documentation and comments

**Code Example:**
```bash
# List created resources
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=project-12
```

**Visual Preview:**
![Architecture Diagram](https://raw.githubusercontent.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/main/project-12-event-driven-pipeline/architecture/architecture.svg)
## 🤝 Contribution & Maintenance
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
---
<div align="center">
  <b>[⬅️ Previous Project](../project-11-) &nbsp; | &nbsp; </b>
</div>
