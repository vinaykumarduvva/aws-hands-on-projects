<div align="center">
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="36" height="36" style="vertical-align: middle"/> Project 11: Infrastructure as Code with AWS CloudFormation</h1>

  <p><i>Define and provision AWS infrastructure declaratively using CloudFormation templates. This project creates a reusable, version-controlled stack that deploys a complete VPC, EC2 instances, and ALB — implementing infrastructure as code best practices including parameterization, dynamic referencing, change sets, and auto-scaling policies.</i></p>

  <p>
    <img src="https://img.shields.io/badge/Level-Intermediate/Advanced-blue" alt="Level"/>
    <img src="https://img.shields.io/badge/Time-4--5%20Hours-orange" alt="Time"/>
    <img src="https://img.shields.io/badge/Cost-$0.00%20(Free%20Tier)-brightgreen" alt="Cost"/>
    <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License"/>
    <img src="https://img.shields.io/badge/Build-Passing-success" alt="Build"/>
  </p>

  <p>
    <a href="#-infrastructure-specifications">Infrastructure</a> · 
    <a href="#-core-features">Features</a> · 
    <a href="#-setup--installation">Setup</a> · 
    <a href="#-documentation-suite">Docs</a>
  </p>

</div>

<br/>

<div align="center">

## 🏗️ Architecture Overview

<img src="./architecture/architecture.svg" alt="Infrastructure as Code with AWS CloudFormation — System Architecture" width="800"/>

<p><i>▲ High-level architecture diagram showing the interaction between CloudFormation, VPC, EC2, and ALB services</i></p>

</div>

## 📐 Infrastructure Specifications

| Resource | Configuration |
|:---------|:--------------|
| **CloudFormation Stack** | Monolithic stack encapsulating the full architecture from Project 10 |
| **Template Format** | YAML with AWSTemplateFormatVersion: 2010-09-09; Description section |
| **Parameters** | ProjectName, EnvironmentType, InstanceType, KeyPairName, Min/Max/Desired capacity limits, and CIDR ranges |
| **Dynamic References** | SSM Parameter Store resolution for fetching the latest Amazon Linux 2023 AMI at runtime |
| **Intrinsic Functions** | Heavy utilization of `!Ref`, `!Sub`, `!GetAtt`, and `Fn::Base64` for dynamic resource linking |
| **Outputs** | Exported ALB DNS URL for immediate application access after deployment |
| **Change Sets** | Preview-before-apply workflow for all stack updates, preventing accidental resource replacement |
| **Drift Detection** | Tracking physical resources in AWS to identify out-of-band/manual modifications |
| **Region** | ap-south-1 (Mumbai) |

## ⚡ Core Features

- **Declarative Infrastructure** – The entire architecture (VPC, Subnets, IGW, Route Tables, ALB, Target Groups, Launch Templates, ASG, and Scaling Policies) is defined in a single, version-controlled YAML file.
- **Dynamic Parameterization** – Change the size of the infrastructure or the instance types simply by passing different parameters at deployment, without editing the code.
- **Idempotent Deployments** – Running the same template repeatedly yields the exact same predictable state.
- **Change Set Workflow** – Preview all resource additions, modifications, and replacements before execution.
- **Drift Detection** – Identify resources that have been modified manually outside of the CloudFormation stack.
- **Atomic Operations & Rollbacks** – Automatic rollback on stack creation or update failure; preserves the last-known-good state ensuring zero downtime on failed updates.
- **Clean Teardown** – Wipe out every single resource created by the stack with a single delete command, eliminating orphaned resources.

## 🛠️ Setup & Installation

### Prerequisites

- AWS CLI v2 configured with IAM credentials (from Project 01)
- Understanding of VPC, EC2, and ALB concepts (Projects 03, 05, 10)
- YAML syntax familiarity
- `cfn-lint` installed for template validation (optional but recommended: `pip install cfn-lint`)

### Deployment & Execution

Unlike previous projects that required 50+ manual console clicks or imperative scripts, this project relies on native CloudFormation CLI commands. 

There are no wrapper scripts or `.env` files. You will run the raw `aws cloudformation` commands directly to master the declarative workflow.

**For full, step-by-step deployment, update, and teardown instructions, please follow the [Deployment Guide](docs/deployment-guide.md).**

### 📸 Screenshots & Validation
Throughout the documentation and `images/` directory, you will find screenshots captured during the deployment process. These visual artifacts serve as verification that the UI steps were successfully executed and validate the final architecture.

## 📚 Documentation Suite

| Document | Description |
|:---------|:------------|
| 📄 [Project Overview](docs/project-overview.md) | Comprehensive project context, goals, and the business problem solved by IaC |
| 🏗️ [Architecture Details](docs/architecture.md) | Deep-dive into system design, CloudFormation provisioning flow, and state management |
| 🚀 [Deployment Guide](docs/deployment-guide.md) | Step-by-step CLI procedures for validating, creating, and updating stacks via Change Sets |
| 🔐 [Security Protocols](docs/security-protocols.md) | IAM policies, Security Group chaining, and NoEcho parameters |
| 🧪 [Testing Procedures](docs/testing-procedures.md) | Testing Drift Detection and Automatic Rollback scenarios |
| 🛠️ [Troubleshooting](docs/troubleshooting.md) | Common CFN issues (`ROLLBACK_COMPLETE`, `CREATE_FAILED`), debugging steps, and `cfn-lint` usage |
| 🧹 [Cleanup Guide](docs/cleanup-guide.md) | How to safely and completely destroy the stack |
| 📋 [Launch Templates](docs/launch-template.md) | Deep dive into `AWS::EC2::LaunchTemplate` and UserData encoding |
| ⚖️ [Load Balancer](docs/load-balancer-design.md) | Deep dive into `AWS::ElasticLoadBalancingV2` ALBs, Listeners, and Target Groups |
| 📈 [Scaling Policies](docs/scaling-policies.md) | Deep dive into `TargetTrackingScaling` policies mapped to ASGs |
| 🔍 [Health Checks](docs/health-checks.md) | Deep dive into ELB health checking integration |

## 🤝 Contribution & Maintenance

### Testing
- `aws cloudformation validate-template --template-body file://templates/main-stack.yaml`
- Make a console change → re-run drift detection → verify drift is reported

### Contributing

1. **Fork** the repository and create a feature branch (`git checkout -b feature/amazing-feature`)
2. **Commit** your changes (`git commit -m "Add amazing feature"`)
3. **Push** to the branch (`git push origin feature/amazing-feature`)
4. **Open** a Pull Request with a detailed description

### License

This project is licensed under the **MIT License** — see the [LICENSE](../LICENSE) file for details.

### Contact & Credits

- **Author:** Vinay Kumar
- **GitHub:** [@vinay1515](https://github.com/vinay1515)
- **Repository:** [Vinay_kumar_AWS_Beginner_level_projects](https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects)

---

<div align="center">
  <b><a href="../project-10-auto-scaling-alb">⬅️ Previous: Project 10</a> &nbsp;|&nbsp; <a href="../project-12-event-driven-pipeline">Next: Project 12 ➡️</a></b>
</div>
