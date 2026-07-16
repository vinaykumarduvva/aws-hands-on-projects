# Testing Procedures & Validation

This document outlines how to actively test and verify the CI/CD pipeline built in this project.

## 🧪 1. Verifying the First Pipeline Execution

After creating the pipeline (Script 07), it triggers its first execution automatically.

1. Run the monitoring script (`08-monitor-pipeline.ps1` or bash equivalent).
2. Watch the pipeline state transition:
   ```
   Source  → InProgress → Succeeded
   Build   → InProgress → Succeeded
   Deploy  → InProgress → Succeeded
   ```
3. Alternatively, open the CodePipeline console → `my-web-app-pipeline` and watch each stage turn green.
4. Verify the deployed application by opening `http://<EC2_PUBLIC_IP>` in a browser.
5. Expected: The CI/CD Demo App page showing **Version 1.0** and the deployment timestamp.

## 🧪 2. Triggering an Automated Deployment (End-to-End Test)

This is the most critical test — proving that a code change flows automatically from commit to production.

1. Edit `index.html` locally — change `Version 1.0` to `Version 2.0`:
   ```powershell
   (Get-Content index.html) -replace 'Version 1.0', 'Version 2.0' | Set-Content index.html
   ```
2. Commit and push:
   ```bash
   git add index.html
   git commit -m "feat: update to version 2.0"
   git push origin main
   ```
3. Watch the pipeline auto-trigger in the CodePipeline console (should start within 30 seconds).
4. Wait ~3-4 minutes for all three stages to complete.
5. Refresh `http://<EC2_PUBLIC_IP>` — should now show **Version 2.0**.

## 🧪 3. Testing Automatic Rollback

To prove rollback works, deliberately break the application:

1. Edit `index.html` to remove the `<body>` tag (this will fail the `pre_build` HTML validation).
2. Push the broken code to CodeCommit.
3. Watch the Build stage fail (CodeBuild HTML validation catches the missing tag).
4. Verify the Deploy stage never runs — the pipeline stops at the Build stage.
5. Confirm `http://<EC2_PUBLIC_IP>` still shows the previous working version.

## 🧪 4. Validating CodeDeploy Agent Health

SSH into the EC2 instance and confirm the CodeDeploy agent is running:
```bash
sudo systemctl status codedeploy-agent
# Expected: active (running)
```

Check the deployment logs on the instance:
```bash
ls /opt/codedeploy-agent/deployment-root/
# Shows deployment IDs with lifecycle event logs
```