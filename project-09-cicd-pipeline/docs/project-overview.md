# Project 9: CI/CD Pipeline with AWS Developer Tools

## Project Overview

This project implements a fully automated CI/CD pipeline using AWS developer tools, demonstrating how engineering teams ship code reliably and repeatedly. The pipeline automatically detects code changes, builds and tests the application, and deploys it to an EC2 server.

## Project Details

| Attribute | Value |
|-----------|-------|
| **Project Number** | 9 |
| **Level** | Intermediate |
| **Estimated Time** | 5-6 hours |
| **Region** | ap-south-1 (Mumbai) |
| **Date Completed** | 2026 |
| **Status** | ✅ Complete |

## Architecture Summary

The pipeline follows a **Source → Build → Deploy** pattern:

1. **Source Stage**: CodeCommit repository stores application code
2. **Build Stage**: CodeBuild compiles, validates, and packages the application
3. **Deploy Stage**: CodeDeploy pushes the application to EC2 instances
4. **Orchestration**: CodePipeline connects all stages and triggers automatically

## Technology Stack

### AWS Services
- **AWS CodeCommit**: Managed Git repository (source control)
- **AWS CodeBuild**: Managed build service (CI)
- **AWS CodeDeploy**: Automated deployment service (CD)
- **AWS CodePipeline**: CI/CD orchestration service
- **Amazon EC2**: Deployment target running Apache
- **Amazon S3**: Artifact storage between pipeline stages
- **AWS IAM**: Service roles and permissions

### Application Stack
- **Web Server**: Apache HTTPD
- **Frontend**: HTML5, CSS3, JavaScript
- **Validation**: Python 3.11 (build-time HTML validation)
- **Scripting**: Bash (deployment lifecycle hooks)

## Key Features

### Automated Pipeline
- ✅ Git push triggers automatic pipeline execution
- ✅ CloudWatch Events detects source changes
- ✅ Zero manual intervention required for deployments
- ✅ Rollback on deployment failure (configurable)

### Build Process
- ✅ HTML syntax validation using Python
- ✅ Required file verification (index.html, appspec.yml)
- ✅ Build metadata generation (build ID, timestamp, region)
- ✅ Artifact packaging for deployment

### Deployment Process
- ✅ Apache installation and configuration
- ✅ Graceful service management (stop → deploy → start)
- ✅ File permission management
- ✅ Automated health checks (HTTP 200 validation)

### Security
- ✅ IAM roles with least privilege principle
- ✅ HTTPS for CodeCommit operations
- ✅ S3 bucket with public access blocked
- ✅ Security group restricting SSH to your IP only

## Project Structure

my-web-app/
├── index.html # Web application
├── buildspec.yml # CodeBuild configuration
├── appspec.yml # CodeDeploy configuration
├── scripts/
│   ├── before_install.sh # Pre-installation tasks
│   ├── after_install.sh # Post-installation tasks
│   ├── start_application.sh # Start web server
│   └── validate_service.sh # Health check validation
└── dist/ # Build output directory (created by CodeBuild)
    ├── index.html
    ├── appspec.yml
    ├── build-info.txt
    └── scripts/
```

## Success Metrics

- **Pipeline Duration**: ~3-4 minutes end-to-end
- **Deployment Success Rate**: 100% (with proper configuration)
- **Automation Level**: Fully automated from git push to production
- **Rollback Capability**: Automatic on deployment failure
- **Cost**: $0.00 under AWS Free Tier

## Learning Outcomes

By completing this project, you've learned:
1. CI/CD concepts and pipeline orchestration
2. AWS Developer Tools suite integration
3. Infrastructure as Code principles
4. Build specification file (buildspec.yml) syntax
5. Application specification file (appspec.yml) syntax
6. Deployment lifecycle hook management
7. IAM role and permission management
8. Automated testing in CI/CD pipelines