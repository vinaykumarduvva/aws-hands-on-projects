# Security Protocols

## 🔐 IAM Least Privilege Permissions

This pipeline uses four dedicated IAM service roles, each scoped to the minimum permissions required for its specific function.

### CodeBuild Service Role (`codebuild-service-role`)
Assumed by the CodeBuild service to execute builds.
- **Trust Policy:** `codebuild.amazonaws.com`
- **Attached Policies:**
  - `AWSCodeBuildAdminAccess` — manage build projects
  - `CloudWatchLogsFullAccess` — write build execution logs
  - `AmazonS3FullAccess` — read source artifacts, write build artifacts
  - `AWSCodeCommitReadOnly` — pull source code from repository

### CodeDeploy Service Role (`codedeploy-service-role`)
Assumed by the CodeDeploy service to orchestrate deployments.
- **Trust Policy:** `codedeploy.amazonaws.com`
- **Attached Policies:**
  - `AWSCodeDeployRole` — read EC2 tags, manage deployment lifecycle, interact with Auto Scaling

### CodePipeline Service Role (`codepipeline-service-role`)
Assumed by the CodePipeline service to coordinate pipeline stages.
- **Trust Policy:** `codepipeline.amazonaws.com`
- **Attached Policies:**
  - `AWSCodePipeline_FullAccess` — manage pipeline executions
  - `AWSCodeCommitFullAccess` — trigger on repository changes
  - `AWSCodeBuildAdminAccess` — start and monitor builds
  - `AWSCodeDeployFullAccess` — create and monitor deployments
  - `AmazonS3FullAccess` — read/write pipeline artifacts

### EC2 Instance Profile (`ec2-codedeploy-role`)
Assumed by the EC2 deployment target to interact with the CodeDeploy Agent.
- **Trust Policy:** `ec2.amazonaws.com`
- **Attached Policies:**
  - `AmazonSSMManagedInstanceCore` — Systems Manager access for remote management
  - `AmazonS3ReadOnlyAccess` — download deployment artifacts from S3

## 🛡️ Network Security

### Security Group (`cicd-deploy-sg`)
| Rule | Protocol | Port | Source | Purpose |
|:-----|:---------|:-----|:-------|:--------|
| SSH | TCP | 22 | `<YOUR_IP>/32` | Administrator access only |
| HTTP | TCP | 80 | `0.0.0.0/0` | Serve web application to public |

- SSH is restricted to a single IP address — never open to `0.0.0.0/0`.
- HTTP is open globally because the EC2 instance serves a public web page.

## 🔒 Artifact & Data Security

- **S3 Bucket:** Block Public Access is fully enabled (`BlockPublicAcls`, `IgnorePublicAcls`, `BlockPublicPolicy`, `RestrictPublicBuckets` all set to `true`).
- **S3 Versioning:** Enabled on the artifact bucket to maintain artifact integrity and allow recovery.
- **CodeCommit:** Data encrypted in transit (TLS) and at rest (AWS-managed KMS keys). Access governed by IAM credentials or SSH keys.
- **EC2 Key Pair:** SSH key pair (`aws-ec2-keypair`) stored securely; private key never uploaded to AWS.