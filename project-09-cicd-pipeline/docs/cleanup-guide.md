# Cleanup Guide — CI/CD Pipeline Project

## Why Cleanup Matters

Most services in this project are within the Free Tier, however:
- EC2 instances consume free tier hours (750 hrs/month shared across all instances)
- The CodePipeline free tier covers only 1 active pipeline for 12 months
- S3 artifact storage grows with each pipeline execution
- Leaving IAM roles behind creates security surface area

Script: `scripts/powershell/10-cleanup.ps1` or `scripts/bash/10-cleanup.sh`

---

## Cleanup Sequence

Resources must be deleted in dependency order: pipeline first (it references other services), then the services, then infrastructure.

### Step 1 — Delete CodePipeline

```powershell
aws codepipeline delete-pipeline --name my-web-app-pipeline
Write-Host "Pipeline deleted"
```

This immediately stops all automated pipeline executions. CodeBuild, CodeDeploy, and CodeCommit remain untouched.

### Step 2 — Delete CodeDeploy

```powershell
aws deploy delete-deployment-group `
  --application-name my-web-app `
  --deployment-group-name production

aws deploy delete-application --application-name my-web-app
Write-Host "CodeDeploy deleted"
```

Deleting the application automatically deletes all deployment groups and revision history.

### Step 3 — Delete CodeBuild

```powershell
aws codebuild delete-project --name my-web-app-build
Write-Host "CodeBuild deleted"
```

Build history and logs remain in CloudWatch Logs until the log group is deleted separately.

### Step 4 — Delete CodeCommit

```powershell
aws codecommit delete-repository --repository-name my-web-app
Write-Host "CodeCommit deleted"
```

> ⚠️ This permanently destroys the source code on AWS. Ensure you have a local copy before proceeding.

### Step 5 — Terminate EC2 and Delete Security Group

```powershell
aws ec2 terminate-instances --instance-ids $DEPLOY_INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $DEPLOY_INSTANCE_ID
aws ec2 delete-security-group --group-id $DEPLOY_SG
Write-Host "EC2 and security group deleted"
```

The security group cannot be deleted until the instance is fully terminated.

### Step 6 — Empty and Delete S3 Bucket

```powershell
aws s3 rm s3://$ARTIFACT_BUCKET --recursive
aws s3api delete-bucket --bucket $ARTIFACT_BUCKET --region ap-south-1
Write-Host "S3 bucket deleted"
```

S3 buckets must be empty before deletion. The `--recursive` flag removes all objects and versions.

### Step 7 — Delete IAM Roles

```powershell
$ROLES = @("codebuild-service-role","codedeploy-service-role","codepipeline-service-role","ec2-codedeploy-role")
foreach ($ROLE in $ROLES) {
    $POLICIES = aws iam list-attached-role-policies `
      --role-name $ROLE `
      --query "AttachedPolicies[*].PolicyArn" --output text
    foreach ($P in $POLICIES.Split()) {
        if ($P) {
            aws iam detach-role-policy --role-name $ROLE --policy-arn $P
        }
    }
    aws iam delete-role --role-name $ROLE 2>$null
    Write-Host "Deleted role: $ROLE"
}

aws iam remove-role-from-instance-profile `
  --instance-profile-name ec2-codedeploy-profile `
  --role-name ec2-codedeploy-role 2>$null
aws iam delete-instance-profile `
  --instance-profile-name ec2-codedeploy-profile 2>$null
```

IAM roles cannot be deleted while they have attached policies — all managed policies must be detached first.

---

## Verification

```powershell
# Pipeline gone
aws codepipeline get-pipeline --name my-web-app-pipeline 2>&1
# Expected: PipelineNotFoundException

# CodeDeploy gone
aws deploy get-application --application-name my-web-app 2>&1
# Expected: ApplicationDoesNotExistException

# CodeBuild gone
aws codebuild batch-get-projects --names my-web-app-build `
  --query "projects" --output text
# Expected: empty

# CodeCommit gone
aws codecommit get-repository --repository-name my-web-app 2>&1
# Expected: RepositoryDoesNotExistException
```

---

## Cost Check

After cleanup, check **AWS Billing → Cost Explorer** in 24 hours.

Expected charges:
- CodeCommit: $0.00 (5 users free forever)
- CodeBuild: $0.00 (within 100 free build minutes)
- CodeDeploy: $0.00 (EC2 deployments always free)
- CodePipeline: $0.00 (1 pipeline free for 12 months)
- EC2: $0.00 (within 750 free hours)
- S3: $0.00–$0.01 (minimal artifact storage)

Total: **$0.00**
