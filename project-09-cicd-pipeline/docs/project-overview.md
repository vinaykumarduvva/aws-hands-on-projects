# Comprehensive Project Overview: CI/CD Pipeline with AWS Developer Tools

## 🎯 Executive Summary & Purpose
Build a fully automated CI/CD pipeline that detects code changes, automatically builds and tests your application, and deploys it to an EC2 server — the same pipeline pattern used by engineering teams at every scale to ship code reliably and repeatedly.

The purpose of this project is to establish a production-grade delivery pipeline by:
- **Creating a CodeCommit Repository:** Hosting application source code in a fully-managed Git repository with IAM-based access control.
- **Configuring CodeBuild:** Defining a `buildspec.yml` that installs runtimes, validates HTML syntax, packages application files, and generates build metadata.
- **Setting up CodeDeploy:** Defining an `appspec.yml` that maps source files to EC2 destinations, sets Apache file permissions, and runs lifecycle hook scripts (stop → install → start → validate).
- **Wiring CodePipeline:** Connecting Source (CodeCommit) → Build (CodeBuild) → Deploy (CodeDeploy) into a single automated workflow triggered on every `git push` to the `main` branch.
- **Deploying to EC2:** Launching an Amazon Linux 2023 instance with the CodeDeploy agent pre-installed, serving the application via Apache httpd.

## 📚 Detailed Learning Objectives
Upon completing this module, you will be able to:
1. **Understand CI/CD Concepts:** Grasp the difference between Continuous Integration (automated build + test) and Continuous Deployment (automated release to production).
2. **Author buildspec.yml:** Write declarative build specifications with install, pre_build, build, and post_build phases.
3. **Author appspec.yml:** Write deployment specifications with file mappings, permissions, and lifecycle hooks (BeforeInstall, AfterInstall, ApplicationStart, ValidateService).
4. **Create IAM Service Roles:** Build least-privilege trust policies for CodeBuild, CodeDeploy, CodePipeline, and EC2 instance profiles.
5. **Configure CodePipeline:** Connect source, build, and deploy stages with S3 artifact passing between each stage.
6. **Trigger Automated Deployments:** Push code to CodeCommit and watch the entire pipeline execute without manual steps.
7. **Debug Pipeline Failures:** Read CloudWatch build logs, CodeDeploy deployment logs, and understand rollback behavior.

## 🛠️ AWS Services & Technologies Utilized
| Service | Primary Role in this Project |
|---------|------------------------------|
| **AWS CodeCommit** | Managed Git repository — stores application source code with branch-based workflow |
| **AWS CodeBuild** | Managed build server — validates HTML, packages artifacts in isolated Docker containers |
| **AWS CodeDeploy** | Deployment service — pushes code to EC2 with lifecycle hooks and automatic rollback |
| **AWS CodePipeline** | Orchestrator — connects Source → Build → Deploy stages into a single automated workflow |
| **Amazon EC2** | Deployment target — Amazon Linux 2023 `t2.micro` running Apache httpd web server |
| **Amazon S3** | Artifact store — CodePipeline stores build outputs between stages with versioning |
| **AWS IAM** | Service roles — separate least-privilege roles for each pipeline component |
| **CloudWatch Logs** | Build logs — CodeBuild writes execution logs to `/aws/codebuild/my-web-app-build` |

## ✅ Cost Control & Financial Governance
This project is designed to be entirely within the AWS Free Tier:
- **CodeCommit:** 5 active users free forever.
- **CodeBuild:** 100 build minutes/month free (12 months).
- **CodeDeploy to EC2:** Always free.
- **CodePipeline:** 1 active pipeline free (12 months).
- **EC2 t2.micro:** 750 hours/month free (12 months).
- **S3 artifact bucket:** 5 GB free (12 months).
**Total Cost:** $0.00 best case · ~$0.01 worst case (S3 storage).