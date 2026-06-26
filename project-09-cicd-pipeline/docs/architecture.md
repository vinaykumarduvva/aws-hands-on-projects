# Architecture Documentation

## High-Level Architecture

The CI/CD pipeline implements a three-stage deployment workflow using AWS managed services, eliminating the need for self-hosted CI/CD infrastructure.

## Component Architecture

### 1. Source Control Layer
```text
┌─────────────────────────────────────┐
│ AWS CodeCommit                      │
│ ┌─────────────────────────────────┐ │
│ │ Repository: my-web-app          │ │
│ │ Branch: main                    │ │
│ │ Files:                          │ │
│ │ - index.html                    │ │
│ │ - buildspec.yml                 │ │
│ │ - appspec.yml                   │ │
│ │ - scripts/*.sh                  │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### 2. Build Layer
```text
┌─────────────────────────────────────┐
│ AWS CodeBuild                       │
│ ┌─────────────────────────────────┐ │
│ │ Project: my-web-app-build       │ │
│ │ Image: aws/codebuild/           │ │
│ │        standard:7.0             │ │
│ │ Compute: BUILD_GENERAL1_SMALL   │ │
│ │ Phases:                         │ │
│ │ - Install (Python 3.11)         │ │
│ │ - Pre-build (validation)        │ │
│ │ - Build (packaging)             │ │
│ │ - Post-build (finalize)         │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### 3. Deployment Layer
```text
┌─────────────────────────────────────┐
│ AWS CodeDeploy                      │
│ ┌─────────────────────────────────┐ │
│ │ App: my-web-app                 │ │
│ │ Group: production               │ │
│ │ Config: AllAtOnce               │ │
│ │ Hooks:                          │ │
│ │ - BeforeInstall                 │ │
│ │ - AfterInstall                  │ │
│ │ - ApplicationStart              │ │
│ │ - ValidateService               │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### 4. Target Infrastructure
```text
┌─────────────────────────────────────┐
│ Amazon EC2 (t2.micro)               │
│ ┌─────────────────────────────────┐ │
│ │ OS: Amazon Linux 2023           │ │
│ │ Agent: CodeDeploy Agent         │ │
│ │ Server: Apache HTTPD            │ │
│ │ Root: /var/www/html/            │ │
│ │ Role: ec2-codedeploy-role       │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Network Architecture
```text
┌──────────────────────────────────────────────────┐
│ AWS Cloud (ap-south-1)                           │
│ ┌──────────────────────────────────────────────┐ │
│ │ VPC (Default)                                │ │
│ │ ┌──────────────────────────────────────────┐ │ │
│ │ │ Public Subnet                            │ │ │
│ │ │ ┌──────────────────────────────────────┐ │ │ │
│ │ │ │ Security Group: cicd-deploy-sg       │ │ │ │
│ │ │ │ - Port 80: 0.0.0.0/0 (HTTP)          │ │ │ │
│ │ │ │ - Port 22: YOUR_IP/32 (SSH)          │ │ │ │
│ │ │ │                                      │ │ │ │
│ │ │ │ EC2 Instance                         │ │ │ │
│ │ │ │ - Apache on port 80                  │ │ │ │
│ │ │ │ - CodeDeploy Agent                   │ │ │ │
│ │ │ └──────────────────────────────────────┘ │ │ │
│ │ └──────────────────────────────────────────┘ │ │
│ └──────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────┘
```

## Data Flow

### Normal Operation Flow
1. Developer pushes code to CodeCommit (`git push`)
2. CloudWatch Events detects branch update
3. CodePipeline triggers automatically
4. Source stage fetches code from CodeCommit
5. Build stage:
   - CodeBuild pulls source code
   - Executes buildspec.yml phases
   - Packages artifacts
   - Uploads to S3 artifact bucket
6. Deploy stage:
   - CodeDeploy fetches artifacts from S3
   - Executes appspec.yml hooks on EC2
   - Deploys application to /var/www/html/
   - Validates deployment health

### Error Handling Flow
1. Pipeline stage fails
2. CodePipeline stops execution
3. SNS notification sent (if configured)
4. CloudWatch Logs capture error details
5. Automatic rollback (if configured in CodeDeploy)
6. Developer can view logs and retry

## IAM Permission Model

### Service Roles
```text
codepipeline-service-role
├── AWSCodePipeline_FullAccess
├── AWSCodeCommitFullAccess
├── AWSCodeBuildAdminAccess
├── AWSCodeDeployFullAccess
└── AmazonS3FullAccess

codebuild-service-role
├── AWSCodeBuildAdminAccess
├── CloudWatchLogsFullAccess
└── AmazonS3FullAccess

codedeploy-service-role
└── AWSCodeDeployRole

ec2-codedeploy-role (Instance Profile)
├── AmazonSSMManagedInstanceCore
└── AmazonS3ReadOnlyAccess
```

## Scaling Considerations

### Current Configuration (Free Tier)
- Single EC2 instance (t2.micro)
- All-at-once deployment strategy
- Single pipeline execution

### Production Scaling Options
- **Horizontal**: Add instances to Auto Scaling Group
- **Deployment Strategies**: 
  - Blue/Green (zero-downtime)
  - Canary (gradual rollout)
  - Linear (controlled percentage)
- **Multi-Region**: Pipeline per region deployment
- **Multi-Environment**: Dev → Staging → Production pipelines

## Monitoring and Observability

### CloudWatch Integration
- **Build Logs**: /aws/codebuild/my-web-app-build
- **Deployment Logs**: CodeDeploy agent logs on EC2
- **Pipeline State**: Pipeline execution history
- **Notifications**: SNS for pipeline failures

### Health Checks
- Deployment validation: HTTP 200 check
- Apache service status verification
- Build-time HTML syntax validation
- File integrity verification

## Cost Optimization

| Resource | Free Tier | Cost/Month (if exceeded) |
|----------|-----------|---------------------------|
| CodeCommit | 5 active users (forever) | $1/user/month |
| CodeBuild | 100 build.minutes | $0.005/minute |
| CodePipeline | 1 active pipeline | $1/pipeline/month |
| EC2 t2.micro | 750 hours | $0.0124/hour |
| S3 | 5 GB storage | $0.023/GB |
| **Total (best case)** | **$0.00** | |
| **Total (worst case)** | **~$1.00** | |