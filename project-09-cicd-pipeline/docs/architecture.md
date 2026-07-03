# Architecture — Project 9 CI/CD Pipeline

## High-Level Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                    Developer Workstation                        │
│                    Windows PC — ap-south-1                      │
│                                                                 │
│   git push origin main                                          │
│   (index.html, buildspec.yml, appspec.yml, scripts/)           │
└──────────────────────────────┬──────────────────────────────────┘
                               │ HTTPS push
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│              CodeCommit — my-web-app                            │
│              Region: ap-south-1                                 │
│              Branch: main                                       │
│              Trigger: CloudWatch Events rule                    │
└──────────────────────────────┬──────────────────────────────────┘
                               │ EventBridge trigger
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CodePipeline                                │
│                     my-web-app-pipeline                         │
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌──────────────────┐    │
│  │   Source    │───▶│    Build    │───▶│     Deploy       │    │
│  │             │    │             │    │                  │    │
│  │ CodeCommit  │    │  CodeBuild  │    │   CodeDeploy     │    │
│  │ SourceOutput│    │ BuildOutput │    │   production     │    │
│  └─────────────┘    └─────────────┘    └──────────────────┘    │
│          │                 │                    │               │
│          ▼                 ▼                    ▼               │
│    S3 artifact       S3 artifact          EC2 Instance          │
│    (source zip)      (built zip)          (deployed app)        │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│              EC2 Instance — cicd-deploy-server                  │
│              ap-south-1 · t2.micro · Amazon Linux 2023          │
│              Tag: Environment=production                        │
│                                                                 │
│              CodeDeploy Agent (running)                         │
│              Apache Web Server (httpd)                          │
│              Application: /var/www/html/                        │
│                                                                 │
│              Public IP → http://YOUR_IP → live app ✅           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Architecture

### Source Stage — CodeCommit

```text
CodeCommit Repository: my-web-app
├── main branch (production)
│   ├── index.html          ← Application source
│   ├── buildspec.yml       ← Build instructions
│   ├── appspec.yml         ← Deploy instructions
│   └── scripts/            ← Lifecycle hook scripts
│
└── CloudWatch Events Rule
    └── Trigger: aws.codecommit referenceUpdated on main
    └── Target: CodePipeline execution start
```

### Build Stage — CodeBuild

```text
CodeBuild Project: my-web-app-build
├── Environment: aws/codebuild/standard:7.0 (Linux)
├── Compute: BUILD_GENERAL1_SMALL (3 GB RAM, 2 vCPU)
├── Source: CodeCommit my-web-app (main)
├── Buildspec: buildspec.yml (in repo root)
│
├── Phase: install    → set up Python 3.11 runtime
├── Phase: pre_build  → validate HTML, check files exist
├── Phase: build      → copy to dist/, generate build-info.txt
├── Phase: post_build → confirm artifact ready
│
├── Artifacts:
│   └── S3: codepipeline-artifacts-ACCOUNT-ap-south-1/
│       └── my-web-app-build/BuildOutput.zip
│
└── Logs: /aws/codebuild/my-web-app-build (CloudWatch)
```

### Deploy Stage — CodeDeploy

```text
CodeDeploy Application: my-web-app
└── Deployment Group: production
    ├── EC2 tag filter: Environment=production
    ├── Deployment config: CodeDeployDefault.AllAtOnce
    ├── Auto-rollback: enabled on DEPLOYMENT_FAILURE
    │
    └── Lifecycle Hooks (appspec.yml):
        ├── BeforeInstall    → before_install.sh
        ├── AfterInstall     → after_install.sh
        ├── ApplicationStart → start_application.sh
        └── ValidateService  → validate_service.sh
```

---

## IAM Role Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                    IAM Roles                                │
│                                                             │
│  codebuild-service-role                                     │
│  ├── Trust: codebuild.amazonaws.com                         │
│  ├── AWSCodeBuildAdminAccess                                │
│  ├── CloudWatchLogsFullAccess                               │
│  └── AmazonS3FullAccess                                     │
│                                                             │
│  codedeploy-service-role                                    │
│  ├── Trust: codedeploy.amazonaws.com                        │
│  └── AWSCodeDeployRole                                      │
│                                                             │
│  codepipeline-service-role                                  │
│  ├── Trust: codepipeline.amazonaws.com                      │
│  ├── AWSCodePipeline_FullAccess                             │
│  ├── AWSCodeCommitFullAccess                                │
│  ├── AWSCodeBuildAdminAccess                                │
│  ├── AWSCodeDeployFullAccess                                │
│  └── AmazonS3FullAccess                                     │
│                                                             │
│  ec2-codedeploy-role                                        │
│  ├── Trust: ec2.amazonaws.com                               │
│  ├── AmazonSSMManagedInstanceCore                           │
│  └── AmazonS3ReadOnlyAccess                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Network Architecture

```text
VPC: Default VPC (ap-south-1)
│
└── Public Subnet (ap-south-1a)
    │
    └── EC2: cicd-deploy-server
        ├── Security Group: cicd-deploy-sg
        │   ├── Inbound: SSH :22 from MY_IP/32
        │   └── Inbound: HTTP :80 from 0.0.0.0/0
        │
        ├── IAM Role: ec2-codedeploy-role
        │   (allows S3 read + SSM access)
        │
        └── CodeDeploy Agent
            └── Polls CodeDeploy service for deployments
            └── Pulls artifact from S3
            └── Executes lifecycle hooks
```

---

## S3 Artifact Flow

```text
S3 Bucket: codepipeline-artifacts-ACCOUNT-ap-south-1
│
├── Source artifacts (CodePipeline puts here)
│   └── my-web-app-pipeline/SourceOutput/
│       └── source.zip (index.html + buildspec + appspec + scripts)
│
└── Build artifacts (CodeBuild puts here)
    └── my-web-app-pipeline/BuildOutput/
        └── BuildOutput.zip
            ├── index.html
            ├── appspec.yml
            ├── build-info.txt
            └── scripts/
                ├── before_install.sh
                ├── after_install.sh
                ├── start_application.sh
                └── validate_service.sh
```

---

## Data Flow Summary

```text
1. Developer edits index.html locally (Version 1.0 → 2.0)

2. git push origin main
   └── CodeCommit stores new commit

3. CloudWatch Events detects push
   └── Triggers CodePipeline execution

4. Source Stage
   └── CodePipeline fetches source from CodeCommit
   └── Zips and stores in S3 as SourceOutput

5. Build Stage
   └── CodeBuild pulls SourceOutput from S3
   └── Runs buildspec.yml phases
   └── Validates HTML, copies to dist/
   └── Zips dist/ and stores as BuildOutput in S3

6. Deploy Stage
   └── CodeDeploy pulls BuildOutput from S3
   └── Finds EC2 instances tagged Environment=production
   └── CodeDeploy agent on EC2 downloads artifact
   └── Runs lifecycle hooks from appspec.yml
   └── Validates HTTP 200 response

7. Done — Version 2.0 live at http://EC2_PUBLIC_IP
   Total time: ~3-4 minutes from git push
```

---

## Monitoring and Observability

| What to monitor | Where | Metric/Log |
| --- | --- | --- |
| Pipeline executions | CodePipeline console | Stage status, duration |
| Build logs | CloudWatch Logs | /aws/codebuild/my-web-app-build |
| Deploy events | CodeDeploy console | Deployment history, hook logs |
| EC2 agent status | EC2 SSH / SSM | `systemctl status codedeploy-agent` |
| App availability | Browser / curl | HTTP 200 from EC2 public IP |

---

## Deployment Config Options

| Config | Behavior | Use Case |
| --- | --- | --- |
| AllAtOnce | Deploy to all instances simultaneously | Dev/test, single instance |
| HalfAtATime | Deploy to 50% then 50% | Rolling update |
| OneAtATime | Deploy one instance at a time | Zero downtime (large fleet) |
| Custom | You define percentage/count | Fine-grained control |

This project uses `AllAtOnce` since we have a single EC2 instance.
Production fleets typically use `HalfAtATime` or `OneAtATime`.
