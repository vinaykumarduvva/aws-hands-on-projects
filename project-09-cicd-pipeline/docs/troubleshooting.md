# Troubleshooting Guide — Project 9 CI/CD Pipeline

## Quick Diagnosis Checklist

When something fails, check these in order:

```
1. Which stage failed? Source / Build / Deploy
2. What is the error message? (click stage in console)
3. Is it an IAM permission error? (look for AccessDenied)
4. Is it a script error? (check CloudWatch / deployment logs)
5. Is the EC2 instance healthy? (check instance status)
```

---

## Stage 1 — Source Stage Issues

### Issue: Source stage fails immediately

**Error message:**
```
The provided role does not have sufficient permissions
```

**Diagnosis:**
```powershell
# Check pipeline role has CodeCommit access
aws iam list-attached-role-policies `
  --role-name codepipeline-service-role `
  --output table
# Should include: AWSCodeCommitFullAccess
```

**Fix:**
```powershell
aws iam attach-role-policy `
  --role-name codepipeline-service-role `
  --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitFullAccess
```

---

### Issue: Git push fails — credentials rejected

**Error message:**
```
fatal: unable to access 'https://git-codecommit.ap-south-1...'
The requested URL returned error: 403
```

**Fix:**
```powershell
# Reconfigure credential helper
git config --global credential.helper "!aws codecommit credential-helper $@"
git config --global credential.UseHttpPath true

# Verify your IAM user has CodeCommit access
aws codecommit get-repository --repository-name my-web-app
# If this works — IAM is fine, credential helper is the issue

# Clear cached credentials
cmdkey /delete:git:https://git-codecommit.ap-south-1.amazonaws.com
# Then try push again
```

---

### Issue: Pipeline not triggering on push

**Cause:** CloudWatch Events rule not created or disabled.

**Diagnosis:**
```powershell
# Check if EventBridge rule exists
aws events list-rules `
  --query "Rules[?contains(Name,'my-web-app-pipeline')]" `
  --output table
```

**Fix:**
```
Console → CodePipeline → my-web-app-pipeline → Edit
→ Source stage → Edit stage → Edit action
→ Change detection options → Amazon CloudWatch Events
→ Save
```

---

## Stage 2 — Build Stage Issues

### Issue: Build fails — HTML validation error

**Error in CloudWatch logs:**
```
AssertionError: Missing html tag
```

**Cause:** index.html doesn't have the expected HTML structure.

**Fix:**
```powershell
# Check local index.html
Select-String "<html" index.html
# If not found — add proper HTML structure to the file

# Also verify the file is committed
git status
# Should show: nothing to commit (if not — git add + git commit)
```

---

### Issue: Build fails — appspec.yml not found

**Error:**
```
Script does not exist at specified location: scripts/before_install.sh
# OR
AppSpec file not found
```

**Cause:** buildspec.yml is not copying appspec.yml to dist/

**Fix:**
Check your buildspec.yml build phase includes:
```yaml
build:
  commands:
    - cp appspec.yml dist/          ← This line must exist
    - cp -r scripts/ dist/          ← And this one
```

**Verify locally:**
```powershell
# Simulate what CodeBuild does
mkdir dist
cp index.html dist/
cp appspec.yml dist/
cp -r scripts dist/
dir dist/    # Should show: index.html, appspec.yml, scripts/
```

---

### Issue: Build fails — Python not found

**Error:**
```
python: command not found
```

**Cause:** Wrong runtime version specified in buildspec.yml

**Fix:**
```yaml
# In buildspec.yml install phase:
install:
  runtime-versions:
    python: 3.11   ← Use 3.11 not 3.x or 3.12
```

Available runtimes for `aws/codebuild/standard:7.0`:
- python: 3.9, 3.10, 3.11, 3.12
- nodejs: 16, 18, 20
- java: corretto11, corretto17, corretto21

---

### Issue: Build succeeds but no artifact in S3

**Cause:** Artifacts section misconfigured in buildspec.yml.

**Check:**
```yaml
# buildspec.yml must have this exactly:
artifacts:
  files:
    - '**/*'
  base-directory: dist   ← Must match your build output dir
  discard-paths: no
```

**Verify S3:**
```powershell
aws s3 ls s3://$ARTIFACT_BUCKET/ --recursive
# Should show files after a successful build
```

---

## Stage 3 — Deploy Stage Issues

### Issue: No instances found for deployment

**Error:**
```
The deployment failed because no instances were found for
your deployment group.
```

**Cause:** EC2 tag doesn't match deployment group filter.

**Diagnosis:**
```powershell
# Check EC2 instance tags
aws ec2 describe-instances `
  --instance-ids $DEPLOY_INSTANCE_ID `
  --query "Reservations[0].Instances[0].Tags" `
  --output table
# Must show: Key=Environment, Value=production

# Check deployment group tag filter
aws deploy get-deployment-group `
  --application-name my-web-app `
  --deployment-group-name production `
  --query "deploymentGroupInfo.ec2TagFilters" `
  --output table
# Must show: Key=Environment, Value=production, Type=KEY_AND_VALUE
```

**Fix:**
```powershell
# Add the correct tag to EC2
aws ec2 create-tags `
  --resources $DEPLOY_INSTANCE_ID `
  --tags Key=Environment,Value=production
```

---

### Issue: CodeDeploy agent not running

**Error:**
```
The overall deployment failed because too many individual
instances failed deployment
```

**Diagnosis:**
```bash
# SSH or SSM into EC2 instance
sudo systemctl status codedeploy-agent
# If not running:

sudo systemctl start codedeploy-agent
sudo systemctl enable codedeploy-agent

# Check agent log
sudo tail -100 /var/log/aws/codedeploy-agent/codedeploy-agent.log
```

**Fix — reinstall agent:**
```bash
sudo yum install -y ruby wget
cd /tmp
wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x install
sudo ./install auto
sudo systemctl start codedeploy-agent
sudo systemctl status codedeploy-agent
```

---

### Issue: BeforeInstall hook fails

**Error in CodeDeploy console:**
```
Script failed with exit code 1
LifecycleEvent: BeforeInstall
Script: scripts/before_install.sh
```

**Diagnosis:**
```bash
# SSH to EC2 and run script manually
sudo bash /opt/codedeploy-agent/deployment-root/LATEST/deployment-archive/scripts/before_install.sh

# Check script line endings (Windows CRLF breaks bash)
file scripts/before_install.sh
# Should say: ASCII text (NOT: ASCII text, with CRLF line terminators)
```

**Fix Windows line endings:**
```bash
# On EC2 or in WSL
sed -i 's/\r//' scripts/before_install.sh
```

**Fix in PowerShell before committing:**
```powershell
# Convert all scripts to Unix line endings
foreach ($file in Get-ChildItem scripts\*.sh) {
  (Get-Content $file.FullName -Raw) -replace "`r`n", "`n" |
    Set-Content $file.FullName -NoNewline
}
```

---

### Issue: ValidateService fails — HTTP not 200

**Error:**
```
Validation FAILED — HTTP 000 received
# OR
Validation FAILED — HTTP 403 received
```

**Diagnosis:**
```bash
# SSH to EC2
# Check Apache is running
sudo systemctl status httpd

# Check file exists
ls -la /var/www/html/

# Check file permissions
stat /var/www/html/index.html
# Should show: access: 0644 (rw-r--r--)
# Owner should be apache

# Test manually
curl -v http://localhost/
```

**Common causes:**
| HTTP Code | Cause | Fix |
|---|---|---|
| 000 | Apache not started | `sudo systemctl start httpd` |
| 403 | Wrong file permissions | `sudo chown apache:apache /var/www/html/*` |
| 404 | index.html not copied | Check appspec.yml files section |
| 500 | Apache config error | `sudo apachectl configtest` |

---

### Issue: CodeDeploy EC2 access denied to S3

**Error in agent log:**
```
AccessDenied when calling s3:GetObject
```

**Cause:** EC2 instance profile missing S3 read permission.

**Fix:**
```powershell
# Verify instance profile is attached
aws ec2 describe-iam-instance-profile-associations `
  --filters "Name=instance-id,Values=$DEPLOY_INSTANCE_ID" `
  --output table

# If not attached:
aws ec2 associate-iam-instance-profile `
  --instance-id $DEPLOY_INSTANCE_ID `
  --iam-instance-profile Name=ec2-codedeploy-profile
```

---

## General Diagnostic Commands

```powershell
# Check all pipeline stage states
aws codepipeline get-pipeline-state `
  --name my-web-app-pipeline `
  --query "stageStates[*].{Stage:stageName,Status:latestExecution.status,Message:latestExecution.errorDetails.message}" `
  --output table

# Check latest build logs
$BUILD_ID = aws codebuild list-builds-for-project `
  --project-name my-web-app-build `
  --query "ids[0]" --output text

aws codebuild batch-get-builds `
  --ids $BUILD_ID `
  --query "builds[0].{Status:buildStatus,Initiator:initiator,Start:startTime,End:endTime}" `
  --output table

# List CloudWatch log streams for CodeBuild
aws logs describe-log-streams `
  --log-group-name /aws/codebuild/my-web-app-build `
  --order-by LastEventTime --descending `
  --query "logStreams[0:3].{Stream:logStreamName,Last:lastEventTimestamp}" `
  --output table

# Check latest CodeDeploy deployment
aws deploy list-deployments `
  --application-name my-web-app `
  --deployment-group-name production `
  --query "deployments[0:3]" --output table

# Get deployment failure details
aws deploy get-deployment `
  --deployment-id DEPLOYMENT_ID `
  --query "deploymentInfo.{Status:status,ErrorCode:errorInformation.code,ErrorMsg:errorInformation.message}" `
  --output table

# Check EC2 CodeDeploy agent status (via SSM)
aws ssm send-command `
  --instance-ids $DEPLOY_INSTANCE_ID `
  --document-name "AWS-RunShellScript" `
  --parameters 'commands=["sudo systemctl status codedeploy-agent"]' `
  --query "Command.CommandId" --output text
```

---

## Error Quick Reference

| Error | Stage | Most Likely Cause |
|---|---|---|
| AccessDenied | Any | IAM role missing permission |
| No instances found | Deploy | EC2 tag mismatch |
| Script exit code 1 | Deploy | Hook script failure |
| Script not found | Deploy | appspec.yml path wrong |
| AppSpec not found | Deploy | appspec.yml not in artifact root |
| Agent not running | Deploy | CodeDeploy agent needs restart |
| Build timeout | Build | Build taking > 60 min default |
| Python not found | Build | Wrong runtime in buildspec |
| 403 on git push | Source | Credential helper misconfigured |
| Pipeline not triggered | Source | CloudWatch Events rule missing |