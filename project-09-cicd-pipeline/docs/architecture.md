# Architecture Details: CI/CD Pipeline

## 🏗️ System Overview & Data Flow

This project implements an automated software delivery pipeline using four AWS Developer Tools services orchestrated by CodePipeline.

```mermaid
flowchart TD
    Dev([Developer - Windows PC])
    
    subgraph "AWS Cloud (ap-south-1)"
        subgraph "Source"
            CC["CodeCommit Repository (my-web-app)"]
        end
        
        subgraph "CodePipeline"
            S1["Stage 1: Source"]
            S2["Stage 2: Build"]
            S3["Stage 3: Deploy"]
        end
        
        subgraph "Build"
            CB["CodeBuild (my-web-app-build)"]
            BS["buildspec.yml"]
        end
        
        subgraph "Deploy"
            CD["CodeDeploy (my-web-app)"]
            AS["appspec.yml"]
        end
        
        S3B[("S3 Artifact Bucket")]
        IAM["IAM Service Roles (x4)"]
        CW["CloudWatch Logs"]
        
        subgraph "Target"
            EC2["EC2 Instance (Amazon Linux 2023)"]
            Agent["CodeDeploy Agent"]
            Apache["Apache httpd"]
        end
    end
    
    Dev -- "git push (main branch)" --> CC
    CC --> S1
    S1 -- "SourceOutput artifact" --> S3B
    S3B --> S2
    S2 --> CB
    CB -- "Reads" -.-> BS
    CB -- "BuildOutput artifact" --> S3B
    S3B --> S3
    S3 --> CD
    CD -- "Reads" -.-> AS
    CD -- "Downloads artifact" --> Agent
    Agent --> Apache
    CB -- "Build logs" --> CW
    IAM -.-> CB
    IAM -.-> CD
    IAM -.-> EC2
```

## 🔄 Data Flow Analysis

1. **Code Push:** The developer pushes code changes to the `main` branch of the CodeCommit repository from their local machine.
2. **Event Detection:** A CloudWatch Events rule detects the push and automatically triggers the CodePipeline execution.
3. **Source Stage:** CodePipeline pulls the latest source code from CodeCommit and stores it as a `SourceOutput` ZIP artifact in the S3 artifact bucket.
4. **Build Stage:** CodeBuild picks up the `SourceOutput` artifact, provisions a fresh Linux container, and executes `buildspec.yml` — installing Python 3.11, validating HTML syntax, packaging files into `dist/`, and generating `build-info.txt`.
5. **Artifact Upload:** CodeBuild zips the `dist/` directory contents and stores them as a `BuildOutput` artifact in S3.
6. **Deploy Stage:** CodeDeploy reads the `BuildOutput` artifact and instructs the CodeDeploy Agent running on the EC2 instance to download it.
7. **Lifecycle Execution:** The Agent executes the `appspec.yml` lifecycle hooks in order: `BeforeInstall` (stop Apache, clean old files) → file copy (`index.html` → `/var/www/html/`) → `AfterInstall` (set permissions) → `ApplicationStart` (start Apache) → `ValidateService` (HTTP 200 health check).
8. **Completion:** If `ValidateService` returns exit code 0, the deployment is marked Succeeded. If it returns non-zero, CodeDeploy marks the deployment as Failed and automatically rolls back to the previous revision.

## 🔁 Rollback Behavior

When auto-rollback is enabled (configured in the deployment group), CodeDeploy automatically re-deploys the last successful revision if:
- Any lifecycle hook script returns a non-zero exit code
- The CodeDeploy Agent loses connectivity during deployment
- The deployment exceeds the configured timeout