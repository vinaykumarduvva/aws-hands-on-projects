# Project 9 — CI/CD Pipeline: Project Overview

[![AWS](https://img.shields.io/badge/AWS-CodePipeline%20%7C%20CodeBuild%20%7C%20CodeDeploy-orange?style=flat&logo=amazon-aws)](https://aws.amazon.com/codepipeline/)
[![Level](https://img.shields.io/badge/Level-Intermediate-yellow?style=flat)](../README.md)
[![Region](https://img.shields.io/badge/Region-ap--south--1-blue?style=flat)](https://aws.amazon.com/about-aws/global-infrastructure/)
[![Free Tier](https://img.shields.io/badge/Cost-Free%20Tier-brightgreen?style=flat)](https://aws.amazon.com/free/)

---

## What Was Built

A fully automated CI/CD pipeline using the AWS Developer
Tools suite that detects every code change, automatically
builds and validates the application, then deploys it to
an EC2 server — zero manual steps after the initial setup.

Every `git push` to the main branch triggers the complete
pipeline automatically within seconds.

---

## Why This Project Matters

CI/CD is not optional in modern software engineering.
It is the baseline expectation at every company that
ships software. This project demonstrates:

- **Automation:** Code ships without human intervention
- **Consistency:** Every deployment follows the same process
- **Speed:** Changes reach production in minutes not hours
- **Safety:** Automated validation and rollback on failure
- **Auditability:** Every deployment tracked with full history

---

## AWS Services Used

| Service | Category | Role in This Project |
|---|---|---|
| CodeCommit | Source Control | Managed Git repo — stores all app code |
| CodeBuild | Build | Compiles, validates, and packages the app |
| CodeDeploy | Deploy | Installs the app on EC2 with lifecycle hooks |
| CodePipeline | Orchestration | Connects all stages — triggers on code push |
| EC2 | Compute | Deployment target running the web application |
| S3 | Storage | Artifact bucket between pipeline stages |
| IAM | Security | Service roles for each pipeline component |
| CloudWatch | Monitoring | Build logs, deployment logs, pipeline metrics |
| CloudWatch Events | Triggers | Detects CodeCommit push and triggers pipeline |

---

## Region

**ap-south-1 (Mumbai)** — all resources deployed here.

> Exception: Billing alarms only work in us-east-1.
> All other project resources stay in ap-south-1.

---

## Free Tier Breakdown

| Service | Free Allowance | Usage | Cost |
|---|---|---|---|
| CodeCommit | 5 active users free forever | 1 user | $0.00 |
| CodeBuild | 100 min/month free (12 mo) | ~5 min/build | $0.00 |
| CodeDeploy to EC2 | Always free | All deployments | $0.00 |
| CodePipeline | 1 pipeline free (12 mo) | 1 pipeline | $0.00 |
| EC2 t2.micro | 750 hrs/month free (12 mo) | ~2 hrs | $0.00 |
| S3 artifact bucket | 5 GB free (12 mo) | < 1 MB | $0.00 |
| **Total** | | | **$0.00** |

---

## Project Outcomes

After completing this project you can:

- Create and manage a Git repository in CodeCommit
- Write a `buildspec.yml` with multi-phase build instructions
- Write an `appspec.yml` with lifecycle deployment hooks
- Configure CodeBuild to validate and package an application
- Configure CodeDeploy to deploy to EC2 with rollback
- Wire all stages together in CodePipeline
- Trigger a deployment simply by pushing code to Git
- Monitor every stage via console and CLI
- Understand how CI/CD works conceptually and practically

---

## Pipeline Execution Summary

```
Total pipeline time (typical): 3-4 minutes

Stage 1 Source:  ~10 seconds  (CodeCommit fetch)
Stage 2 Build:   ~90 seconds  (CodeBuild validation + package)
Stage 3 Deploy:  ~60 seconds  (CodeDeploy lifecycle hooks)

Trigger: git push to main branch
Result:  Updated web app live on EC2
```

---

## Repository Contents

```
project-09-cicd/
│
├── README.md
├── index.html              ← Web application source
├── buildspec.yml           ← CodeBuild instructions
├── appspec.yml             ← CodeDeploy instructions
│
├── scripts/
│   ├── before_install.sh   ← Pre-deployment hook
│   ├── after_install.sh    ← Post-copy hook
│   ├── start_application.sh← Service start hook
│   └── validate_service.sh ← Health check hook
│
├── docs/
│   ├── project-overview.md ← This file
│   ├── architecture.md
│   ├── pipeline-stages.md
│   ├── buildspec-explained.md
│   ├── appspec-explained.md
│   ├── deployment-workflow.md
│   ├── security.md
│   ├── troubleshooting.md
│   └── cleanup-guide.md
│
├── architecture/
│   ├── cicd-architecture.svg
│   ├── pipeline-flow.svg
│   ├── deployment-flow.svg
│   └── codedeploy-lifecycle.svg
│
└── images/
    ├── 01-codecommit-repo.png
    ├── 02-codebuild-project.png
    ├── 03-codedeploy-app.png
    ├── 04-pipeline-created.png
    ├── 05-pipeline-running.png
    ├── 06-source-succeeded.png
    ├── 07-build-succeeded.png
    ├── 08-deploy-succeeded.png
    ├── 09-app-live-v1.png
    ├── 10-code-push-trigger.png
    └── 11-app-live-v2.png
```

---

## Key Concepts Demonstrated

### Continuous Integration (CI)
Every code push triggers an automated build that:
- Installs dependencies
- Validates code quality
- Runs tests
- Packages the artifact

If any step fails → pipeline stops → developer is notified.
Broken code never reaches production.

### Continuous Delivery (CD)
Every successful build automatically deploys to production:
- CodeDeploy runs lifecycle hooks
- Health checks validate the deployment
- Auto-rollback fires if validation fails

### Infrastructure as Code
The entire pipeline behavior is defined in files:
- `buildspec.yml` → how to build
- `appspec.yml` → how to deploy
- These files live in Git alongside the application code

---

## Real-World Context

This pipeline pattern is used by engineering teams at every
scale — from 2-person startups to Fortune 500 companies.

**At a startup:**
Single pipeline, deploy to one server, ship 10x per day.

**At an enterprise:**
Multiple pipelines per microservice, multiple environments
(dev → staging → production), approval gates between stages,
Slack notifications on every deployment.

The AWS Developer Tools suite is the most common CI/CD
stack for teams already on AWS. Knowing CodePipeline end-to-end
is a differentiator for Solutions Architect and DevOps roles.

---