# Project 9 — CI/CD Pipeline: CodeCommit + CodeBuild + CodeDeploy + CodePipeline

![AWS](https://img.shields.io/badge/AWS-Developer%20Tools%20Suite-orange?logo=amazonaws)
![Level](https://img.shields.io/badge/Level-Intermediate-blue)
![Region](https://img.shields.io/badge/Region-ap--south--1%20Mumbai-yellow)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)
![Free Tier](https://img.shields.io/badge/Cost-Free%20Tier%20Eligible-green)

Build a fully automated CI/CD pipeline that detects code changes, automatically builds and tests your application, and deploys it to an EC2 server — the same pipeline pattern used by engineering teams at every scale.

---

## Architecture Overview

```
Developer (git push)
        │
        ▼
┌─────────────────────┐
│   CodeCommit        │  Managed Git repository
│   my-web-app        │  main branch
└──────────┬──────────┘
           │ triggers automatically
           ▼
┌─────────────────────────────────────────────────────┐
│                  CodePipeline                       │
│                                                     │
│  Stage 1: Source  → pulls from CodeCommit           │
│       │                                             │
│       ▼                                             │
│  Stage 2: Build   → CodeBuild runs buildspec.yml    │
│       │            validates HTML, packages dist/   │
│       ▼                                             │
│  Stage 3: Deploy  → CodeDeploy runs appspec.yml     │
│                    lifecycle hooks on EC2           │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────┐
        │   EC2 (ap-south-1)       │
        │   Amazon Linux 2023      │
        │   t2.micro               │
        │   CodeDeploy Agent       │
        │   Apache web server      │
        └──────────────────────────┘
                       │
                       ▼
        S3 Artifact Bucket
        (pipeline stores build outputs)
```

---

## AWS Services Used

| Service | Role |
|---|---|
| CodeCommit | Managed Git repository — stores source code |
| CodeBuild | Managed build server — validates, packages |
| CodeDeploy | Deployment service — pushes to EC2 with lifecycle hooks |
| CodePipeline | Orchestrator — Source → Build → Deploy |
| EC2 | Deployment target running the web application |
| S3 | Artifact store between pipeline stages |
| IAM | Service roles for each pipeline component |

---

## Free Tier Status

| Resource | Free Tier | Region |
|---|---|---|
| CodeCommit | 5 active users free forever | ap-south-1 ✅ |
| CodeBuild | 100 build minutes/month (12 months) | ap-south-1 ✅ |
| CodeDeploy to EC2 | Always free | ap-south-1 ✅ |
| CodePipeline | 1 active pipeline free (12 months) | ap-south-1 ✅ |
| EC2 t2.micro | 750 hrs/month (12 months) | ap-south-1 ✅ |
| S3 | 5 GB free (12 months) | ap-south-1 ✅ |

**Cost estimate: $0.00** — all within free tier.

---

## Project Structure

```
project-09-cicd-pipeline/
├── README.md
├── LICENSE
├── .gitignore
├── docs/               — architecture, design, guides
├── application/        — source code pushed to CodeCommit
│   ├── index.html
│   ├── buildspec.yml
│   ├── appspec.yml
│   └── scripts/        — CodeDeploy lifecycle hooks
├── scripts/            — PowerShell deployment scripts
├── architecture/       — SVG diagrams
└── images/             — Console screenshots
```

---

## Execution Order

| Script | Part | Task |
|---|---|---|
| `01-create-iam-roles.ps1` | 1 | All 4 IAM service roles |
| `02-create-s3-bucket.ps1` | 2 | Artifact bucket with versioning |
| `03-create-codecommit.ps1` | 3 | Git repository |
| `04-launch-ec2.ps1` | 6 | EC2 with CodeDeploy agent |
| `05-create-codedeploy.ps1` | 7 | Application + deployment group |
| `06-create-codebuild.ps1` | 8 | Build project |
| `07-create-codepipeline.ps1` | 9 | Pipeline with 3 stages |
| `08-monitor-pipeline.ps1` | 10 | Watch execution status |
| `09-trigger-deployment.ps1` | 11 | Push v2.0 and verify |
| `10-cleanup.ps1` | 12 | Full teardown |

---

## Key Concepts Demonstrated

**CI/CD pipeline**: Every `git push` to the `main` branch automatically triggers Source → Build → Deploy. No manual intervention required after initial setup.

**buildspec.yml**: YAML config that tells CodeBuild what to do — install dependencies, run tests, package artifacts. The `pre_build` phase validates HTML structure; the `build` phase copies files to `dist/` with build metadata.

**appspec.yml**: YAML config that tells CodeDeploy how to deploy — which files go where, and which lifecycle hook scripts to run (BeforeInstall → AfterInstall → ApplicationStart → ValidateService).

**Tag-based deployment**: CodeDeploy finds EC2 instances by tag (`Environment=production`) rather than instance ID. Any EC2 with that tag becomes a deployment target — no hardcoded instance IDs.

**Auto-rollback**: The deployment group is configured with `auto-rollback on deployment failure`. If the `ValidateService` hook returns a non-zero exit code, CodeDeploy automatically rolls back to the previous version.

---

*Part of the AWS Cloud Projects portfolio — hands-on infrastructure built and documented end to end.*