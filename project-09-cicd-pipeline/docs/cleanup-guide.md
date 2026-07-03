# 🧹 Project 09 Cleanup Guide

To avoid incurring any unexpected charges on your AWS account, it is important to delete all the resources provisioned during this project. Follow these steps in order to cleanly tear down the CI/CD pipeline.

> [!WARNING]
> **Data Loss Warning**: Deleting the CodeCommit repository will permanently destroy the source code hosted on AWS. Ensure you have a local copy of your code before proceeding.

## 1. Delete EC2 Instance and Security Group
- [ ] Go to the **EC2 Console** > **Instances**.
- [ ] Select the instance named **`cicd-deploy-server`**.
- [ ] Click **Instance state** > **Terminate instance** and confirm.
- [ ] Wait for the instance state to change to *Terminated*.
- [ ] Navigate to **Security Groups** (under Network & Security).
- [ ] Select **`cicd-deploy-sg`**, click **Actions** > **Delete security groups**, and confirm.

## 2. Delete CodePipeline
- [ ] Go to the **CodePipeline Console** > **Pipelines**.
- [ ] Select **`my-web-app-pipeline`**.
- [ ] Click **Delete** and type the pipeline name to confirm.

## 3. Delete CodeDeploy Application
- [ ] Go to the **CodeDeploy Console** > **Applications**.
- [ ] Select **`my-web-app`**.
- [ ] Click **Delete application** and type the application name to confirm. *(This automatically deletes the `production` deployment group as well).*

## 4. Delete CodeBuild Project & Logs
- [ ] Go to the **CodeBuild Console** > **Build projects**.
- [ ] Select **`my-web-app-build`**.
- [ ] Click **Delete build project** and confirm.
- [ ] Go to the **CloudWatch Console** > **Log groups**.
- [ ] Search for **`/aws/codebuild/my-web-app-build`**, select it, and click **Actions** > **Delete log group(s)**.

## 5. Delete CodeCommit Repository
- [ ] Go to the **CodeCommit Console** > **Repositories**.
- [ ] Select **`my-web-app`**.
- [ ] Click **Delete repository** and type `delete` to confirm.

## 6. Empty and Delete S3 Artifact Bucket
- [ ] Go to the **S3 Console**.
- [ ] Find the bucket named **`codepipeline-artifacts-[YOUR_ACCOUNT]-ap-south-1`**.
- [ ] Select the bucket, click **Empty**, and type *permanently delete* to confirm.
- [ ] Once emptied, select the bucket again, click **Delete**, and type the bucket name to confirm.

## 7. Delete IAM Roles
- [ ] Go to the **IAM Console** > **Roles**.
- [ ] Search for and delete the following roles one by one:
  - [ ] **`codebuild-service-role`**
  - [ ] **`codedeploy-service-role`**
  - [ ] **`codepipeline-service-role`**
  - [ ] **`ec2-codedeploy-role`**
- [ ] *Note: When you delete `ec2-codedeploy-role`, the associated instance profile is also deleted.*

---

**🎉 Cleanup Complete!**
Your AWS environment is now clean from Project 09 resources and you will not incur further charges related to this pipeline.
