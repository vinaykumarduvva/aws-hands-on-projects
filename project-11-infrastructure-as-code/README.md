<div align="center">
  <img src="https://raw.githubusercontent.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/main/project-11-infrastructure-as-code/architecture/architecture.svg" alt="Infrastructure as Code with AWS CloudFormation Architecture" width="820"/>
  <br/><br/>
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="36" height="36" style="vertical-align: middle"/> Project 11: Infrastructure as Code with AWS CloudFormation</h1>

  <p><i>Define and provision AWS infrastructure declaratively using CloudFormation templates. This project creates a reusable, version-controlled stack that deploys a complete VPC, EC2 instances, RDS database, and ALB — implementing infrastructure as code best practices including parameterization, mappings, conditions, outputs, and nested stacks.</i></p>

  <p>
    <img src="https://img.shields.io/badge/Level-Intermediate/Advanced-blue" alt="Level"/>
    <img src="https://img.shields.io/badge/Time-4--5%20Hours-orange" alt="Time"/>
    <img src="https://img.shields.io/badge/Cost-$0.00%20(Free%20Tier)-brightgreen" alt="Cost"/>
    <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License"/>
    <img src="https://img.shields.io/badge/Build-Passing-success" alt="Build"/>
  </p>

  <p>
    <a href="#-infrastructure-specifications">Infrastructure</a> · 
    <a href="#-key-components">Components</a> · 
    <a href="#-core-features">Features</a> · 
    <a href="#-setup--installation">Setup</a> · 
    <a href="#-documentation-suite">Docs</a>
  </p>

  <p><b>🔗 <a href="#">Live Demo</a></b> &nbsp;·&nbsp; <b>📹 <a href="#">Video Walkthrough</a></b></p>

</div>

<br/>

<div align="center">

## 🏗️ Architecture Overview

<img src="https://raw.githubusercontent.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/main/project-11-infrastructure-as-code/architecture/architecture.svg" alt="Infrastructure as Code with AWS CloudFormation — System Architecture" width="800"/>

<p><i>▲ High-level architecture diagram showing the interaction between CloudFormation, VPC, EC2, RDS, ALB services</i></p>

</div>

## 📐 Infrastructure Specifications

| Resource | Configuration |
|:---------|:--------------|
| **CloudFormation Stack** | Root stack with 3 nested stacks: Network, Compute, Database |
| **Template Format** | YAML with AWSTemplateFormatVersion: 2010-09-09; Description and Metadata sections |
| **Parameters** | EnvironmentType (dev/staging/prod), InstanceType, DBInstanceClass, KeyName, CIDR ranges |
| **Mappings** | AMI IDs per region; instance type → EBS size; environment → capacity settings |
| **Conditions** | CreateProdResources (Multi-AZ RDS, larger instances); CreateDevResources (t2.micro, single-AZ) |
| **Outputs** | VPC ID, ALB DNS name, RDS endpoint, SSH command — exported for cross-stack references |
| **Change Sets** | Preview-before-apply workflow for all stack updates |
| **Drift Detection** | Scheduled drift detection to identify out-of-band resource modifications |
| **Region** | ap-south-1 (parameterized for multi-region deployment) |

## 🧩 Key Components

### Root Stack Template
Master template orchestrating nested stacks with cross-stack parameter passing

### Network Stack (Nested)
VPC, subnets, IGW, NAT, route tables — reusable network foundation

### Compute Stack (Nested)
Launch template, ASG, ALB, target group — condition-driven sizing per environment

### Database Stack (Nested)
RDS MySQL, DB subnet group, parameter group — multi-AZ conditional on environment

### Parameters & Mappings
Externalized configuration enabling single template for dev/staging/prod environments

### Outputs & Exports
Cross-stack references enabling loose coupling between network, compute, and database

## ⚡ Core Features

- **Declarative Infrastructure** – Entire stack defined in version-controlled YAML; reproducible and auditable
- **Environment Parameterization** – Single template deploys dev (t2.micro, single-AZ) or prod (t3.large, multi-AZ)
- **Nested Stack Architecture** – Modular templates for network, compute, and database with independent lifecycle
- **Change Set Workflow** – Preview all resource additions, modifications, and replacements before execution
- **Drift Detection** – Identify resources modified outside CloudFormation (manual console changes)
- **Rollback Protection** – Automatic rollback on stack creation/update failure; preserves last-known-good state
- **Cross-Stack References** – Exported outputs enable loose coupling between independently managed stacks

## 🛠️ Setup & Installation

### Prerequisites

- AWS CLI v2 configured with IAM credentials (from Project 01)
- Understanding of VPC, EC2, RDS concepts (Projects 03, 05, 06)
- YAML syntax familiarity
- cfn-lint installed for template validation (`pip install cfn-lint`)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects.git
cd project-11-infrastructure-as-code

# 2. Configure environment variables
cp .env.example .env
# Edit .env with your specific values (see Environment Variables below)
```

### Environment Variables

Create a `.env` file in the project root:

```bash
export AWS_REGION="ap-south-1"
export STACK_NAME="my-iac-stack"
export ENVIRONMENT="dev"
export KEY_NAME="my-ec2-keypair"
export DB_PASSWORD="ChangeMe123!"
```

### Run Commands

Choose your platform and execute the scripts in order:

<table>
<tr><th>Step</th><th>Script</th><th>Description</th></tr>
<tr><td>🐧</td><td><code>scripts/bash/01-validate-template.sh</code></td><td>Runs cfn-lint and aws cloudformation validate-template on all templates</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/01-validate-template.ps1</code></td><td>Runs cfn-lint and aws cloudformation validate-template on all templates</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/02-deploy-stack.sh</code></td><td>Creates or updates the root stack with parameters for the target environment</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/02-deploy-stack.ps1</code></td><td>Creates or updates the root stack with parameters for the target environment</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/03-create-change-set.sh</code></td><td>Generates and reviews a change set before applying stack modifications</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/03-create-change-set.ps1</code></td><td>Generates and reviews a change set before applying stack modifications</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/04-detect-drift.sh</code></td><td>Initiates drift detection and reports any out-of-band resource changes</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/04-detect-drift.ps1</code></td><td>Initiates drift detection and reports any out-of-band resource changes</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/05-delete-stack.sh</code></td><td>Deletes the entire stack including all nested stacks and resources</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/05-delete-stack.ps1</code></td><td>Deletes the entire stack including all nested stacks and resources</td></tr>
</table>

## 📚 Documentation Suite

| Document | Description |
|:---------|:------------|
| 📄 [Project Overview](docs/project-overview.md) | Comprehensive project context, goals, and learning outcomes |
| 🏗️ [Architecture Details](docs/architecture.md) | Deep-dive into system design, data flow, and component interactions |
| 🚀 [Deployment Guide](docs/deployment-guide.md) | Step-by-step deployment procedures for dev, staging, and production |
| 🔐 [Security Protocols](docs/security-protocols.md) | IAM policies, encryption, network security, and compliance controls |
| 🧪 [Testing Procedures](docs/testing-procedures.md) | Validation scripts, smoke tests, and integration test suites |
| 🛠️ [Troubleshooting](docs/troubleshooting.md) | Common issues, error codes, debugging steps, and resolution guides |

## 🤝 Contribution & Maintenance

### Testing

- `aws cloudformation describe-stacks --stack-name $STACK_NAME` – Verify CREATE_COMPLETE status
- `aws cloudformation detect-stack-drift --stack-name $STACK_NAME` – Run drift detection
- Deploy with `ENVIRONMENT=dev` → verify t2.micro and single-AZ RDS
- Deploy with `ENVIRONMENT=prod` → verify t3.large and multi-AZ RDS
- Make a console change → re-run drift detection → verify drift is reported

### Deployment

For full production deployment procedures, see the [Deployment Guide](docs/deployment-guide.md).

### Contributing

1. **Fork** the repository and create a feature branch (`git checkout -b feature/amazing-feature`)
2. **Commit** your changes (`git commit -m "Add amazing feature"`)
3. **Push** to the branch (`git push origin feature/amazing-feature`)
4. **Open** a Pull Request with a detailed description
5. Ensure all scripts exist in **both** `scripts/powershell/` and `scripts/bash/`

### License

This project is licensed under the **MIT License** — see the [LICENSE](../LICENSE) file for details.

### Contact & Credits

- **Author:** Vinay Kumar
- **GitHub:** [@vinay1515](https://github.com/vinay1515)
- **Repository:** [Vinay_kumar_AWS_Beginner_level_projects](https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects)

---

<div align="center">
  <b>[⬅️ Previous: Project 10](../project-10-auto-scaling-alb) &nbsp;|&nbsp; [Next: Project 12 ➡️](../project-12-event-driven-pipeline)</b>
</div>
