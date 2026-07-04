<div align="center">
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" alt="AWS Logo" style="height: 1.5em; vertical-align: middle; margin-right: 8px;"/> Project 01: AWS Account Setup & IAM Foundations</h1>

  <p><i>Establish a hardened AWS account baseline by configuring Identity and Access Management (IAM) with least-privilege policies, multi-factor authentication (MFA), and granular role-based access control. This project lays the security foundation that every subsequent project in this portfolio depends on.</i></p>

  <p>
    <img src="https://img.shields.io/badge/Level-Beginner-blue" alt="Level"/>
    <img src="https://img.shields.io/badge/Time-1--2%20Hours-orange" alt="Time"/>
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

</div>

<br/>

<div align="center">

## 🏗️ Architecture Overview

<img src="./architecture\architectural-diagram.svg" alt="AWS Account Setup & IAM Foundations — System Architecture" width="800"/>

<p><i>▲ High-level architecture diagram showing the interaction between IAM, SNS, CloudWatch services</i></p>

</div>

## 📐 Infrastructure Specifications

| Resource             | Configuration                                                                                        |
| :---------------------| :-----------------------------------------------------------------------------------------------------|
| **IAM Users**        | Admin user with console + programmatic access; developer user with scoped permissions                |
| **IAM Groups**       | `Admins` (full access), `Developers` (EC2/S3/Lambda read-write), `ReadOnly` (view-only)              |
| **IAM Policies**     | Custom JSON policies enforcing least-privilege; AWS-managed `AdministratorAccess` for bootstrap only |
| **IAM Roles**        | Cross-service role for Lambda → S3 access; EC2 instance profile for SSM Session Manager              |
| **MFA**              | Virtual MFA device enforced on root and all IAM users via `aws:MultiFactorAuthPresent` condition key |
| **Password Policy**  | 14-char minimum, uppercase + lowercase + number + symbol, 90-day rotation, no reuse of last 5        |
| **SNS Topic**        | Billing alarm notification topic (`billing-alerts`) with email subscription                          |
| **CloudWatch Alarm** | EstimatedCharges ≥ $5 threshold → SNS notification                                                   |
| **Region**           | us-east-1 (required for billing metrics); global for IAM                                             |

## 🧩 Key Components

### IAM Identity Center
Centralized user management and single sign-on for multi-account environments

### IAM Policies (JSON)
Fine-grained permission documents attached to users, groups, and roles

### IAM Roles & Instance Profiles
Temporary-credential delegation for services like EC2, Lambda, and CodeBuild

### MFA Enforcement
Condition keys in policies that deny all actions unless MFA is present

### CloudWatch Billing Alarm
Metric alarm on `AWS/Billing` → `EstimatedCharges` with SNS action

### SNS Email Subscription
Fan-out notification channel for billing alerts and operational events

## ⚡ Core Features

- **Least-Privilege Policy Engine** – Custom IAM policies scoped to exact API actions and resource ARNs
- **MFA-Gated Access** – Policies with `Condition: { Bool: { aws:MultiFactorAuthPresent: true } }`
- **Automated Billing Guard** – CloudWatch alarm triggers SNS email when spend exceeds $5 threshold
- **Role-Based Access Control** – Separate IAM groups for Admins, Developers, and Read-Only auditors
- **Password Policy Hardening** – Programmatic enforcement of complexity, rotation, and reuse rules
- **Cross-Service Roles** – Preconfigured IAM roles for Lambda, EC2, and CI/CD pipeline assumptions
- **Audit-Ready Logging** – CloudTrail integration for full API call history across the account

## 🛠️ Setup & Installation

### Prerequisites

- AWS account with root access (initial setup only)
- AWS CLI v2 (`aws --version` ≥ 2.x)
- A valid email address for SNS billing alert subscription
- A virtual MFA app (Google Authenticator, Authy, or 1Password)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects.git
cd project-01-iam-setup

# 2. Configure environment variables
cp .env.example .env
# Edit .env with your specific values (see Environment Variables below)
```

### Environment Variables

Create a `.env` file in the project root:

```bash
export AWS_REGION="us-east-1"
export AWS_PROFILE="default"
export ALERT_EMAIL="your-email@example.com"
export BILLING_THRESHOLD="5"
```

### Run Commands

Choose your platform and execute the scripts in order:

<table>
<tr><th>Order</th><th>Step</th><th>Bash Script (🐧)</th><th>PowerShell Script (🖥️)</th><th>Description</th></tr>
<tr><td>1</td><td>Setup IAM User</td><td><code>scripts/bash/setup-iam-user.sh</code></td><td><code>scripts/powershell/setup-iam-user.ps1</code></td><td>Creates IAM user, group, and policies</td></tr>
<tr><td>2</td><td>Setup Billing Alarm</td><td><code>scripts/bash/setup-billing-alarm.sh</code></td><td><code>scripts/powershell/setup-billing-alarm.ps1</code></td><td>Creates SNS topic and CloudWatch billing alarm</td></tr>
<tr><td>3</td><td>Verify Setup</td><td><code>scripts/bash/verify_setup.sh</code></td><td><code>scripts/powershell/verify_setup.ps1</code></td><td>Validates the creation of all resources</td></tr>
</table>

### 🧹 Cleanup

**Note:** Since this project sets up the foundational IAM access for subsequent projects in this portfolio, you typically **do not** want to clean this up immediately. However, if you need to tear down the environment, you can remove the resources using the AWS CLI:

```bash
# 1. Delete CloudWatch Alarm
aws cloudwatch delete-alarms --alarm-names "AccountBillingAlarm"

# 2. Delete SNS Topic (Replace <AccountID> with your AWS Account ID)
aws sns delete-topic --topic-arn "arn:aws:sns:us-east-1:<AccountID>:billing-alerts"

# 3. Clean up IAM User (Requires detaching policies and deleting access keys first)
aws iam detach-user-policy --user-name <YourUserName> --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam delete-login-profile --user-name <YourUserName>
aws iam delete-access-key --user-name <YourUserName> --access-key-id <YourAccessKeyId>
aws iam delete-user --user-name <YourUserName>
```

## 📚 Documentation Suite

| Document | Description |
|:---------|:------------|
| 📄 [Project Overview](docs/project-overview.md) | Comprehensive project context, goals, and learning outcomes |
| 🏗️ [Architecture Details](docs/architecture.md) | Deep-dive into system design, data flow, and component interactions |
| 🚀 [Deployment Guide](docs/deployment-guide.md) | Step-by-step deployment procedures for dev, staging, and production |
| 🔐 [Security Protocols](docs/security-protocols.md) | IAM policies, encryption, network security, and compliance controls |
| 🧪 [Testing Procedures](docs/testing-procedures.md) | Validation scripts, smoke tests, and integration test suites |
| 🛠️ [Troubleshooting](docs/troubleshooting.md) | Common issues, error codes, debugging steps, and resolution guides |
| 🧹 [Cleanup Guide](docs/cleanup-guide.md) | Instructions for tearing down AWS resources to avoid charges |

## 🤝 Contribution & Maintenance

### Testing

- `aws iam get-account-authorization-details` – Verify all users, groups, and policies exist
- `aws iam get-account-password-policy` – Confirm password policy matches specification
- `aws sns list-subscriptions-by-topic` – Ensure email subscription is confirmed
- `aws cloudwatch describe-alarms --alarm-names billing-alarm` – Validate alarm state is OK
- Attempt an API call without MFA and confirm `AccessDenied` response

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
  <b><a href="../project-02-s3-static-website">Next: Project 02 ➡️</a></b>
</div>
