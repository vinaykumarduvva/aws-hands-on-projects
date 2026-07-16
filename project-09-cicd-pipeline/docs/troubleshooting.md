# Troubleshooting Guide

Use this reference to resolve common issues encountered during the deployment of Project 09.

## 🚨 Common Issues & Resolutions

### Issue 1: CodeCommit push fails with 403 Forbidden
- **Cause:** Git credential helper for CodeCommit is not configured, or IAM user lacks `AWSCodeCommitFullAccess`.
- **Fix:** Run `git config --global credential.helper "!aws codecommit credential-helper $@"` and `git config --global credential.UseHttpPath true`. Verify the IAM user has CodeCommit permissions.

### Issue 2: CodeBuild fails — `appspec.yml not found`
- **Cause:** The `appspec.yml` file was not committed to the repository root, or the `buildspec.yml` failed to copy it into the `dist/` output directory.
- **Fix:** Verify `appspec.yml` is committed: `git ls-files | grep appspec`. Ensure the `build` phase in `buildspec.yml` includes `cp appspec.yml dist/`.

### Issue 3: CodeDeploy fails — agent not running
- **Cause:** The CodeDeploy agent failed to install during EC2 user data execution, or the service stopped.
- **Fix:** SSH into the instance and run `sudo systemctl status codedeploy-agent`. If stopped, start it: `sudo systemctl start codedeploy-agent`. Check install logs: `cat /tmp/codedeploy-agent-install.log`.

### Issue 4: CodeDeploy fails — no instances matched
- **Cause:** The EC2 instance tags do not match the deployment group filter.
- **Fix:** Verify the EC2 instance has the tag `Environment=production` (case-sensitive). The deployment group is configured to filter by `Key=Environment, Value=production, Type=KEY_AND_VALUE`.

### Issue 5: Pipeline not triggering on push
- **Cause:** CloudWatch Events rule was not created, or the Source stage is configured with `PollForSourceChanges: true` but polling is unreliable.
- **Fix:** In the CodePipeline console, edit the Source stage and verify the detection option is set to **Amazon CloudWatch Events (recommended)**. Manually trigger with `aws codepipeline start-pipeline-execution --name my-web-app-pipeline` to verify the rest of the pipeline works.

### Issue 6: Build fails — Python validation error
- **Cause:** The `index.html` file is missing required tags (`<html>`, `<head>`, `<body>`) that the inline Python validation checks for.
- **Fix:** Open `index.html` in a browser to confirm it renders correctly. Ensure the file contains `<html`, `<head>`, and `<body>` tags. Fix the HTML and push again.

### Issue 7: CodeDeploy hook script fails with exit code 127
- **Cause:** The hook script was not found at the path specified in `appspec.yml`, or it has Windows-style CRLF line endings.
- **Fix:** Verify the script exists in the artifact at the exact path (e.g., `scripts/before_install.sh`). Fix line endings: `sed -i 's/\r//' scripts/*.sh`. Ensure scripts have `#!/bin/bash` as the first line.

### Issue 8: Pipeline role permission error (AccessDenied)
- **Cause:** One of the IAM service roles is missing a required policy attachment.
- **Fix:** Check AWS CloudTrail for the specific `AccessDenied` action and add the required managed policy to the appropriate role using `aws iam attach-role-policy`.