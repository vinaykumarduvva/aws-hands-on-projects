# Project 11 Troubleshooting Guide: CloudFormation

When deploying Infrastructure as Code, failures usually occur during the `CREATE_IN_PROGRESS` or `UPDATE_IN_PROGRESS` phases. CloudFormation's rollback mechanism makes troubleshooting uniquely reliant on stack events.

---

## 📋 Quick Reference Table

| Problem | Quick Fix |
|:---|:---|
| Stack stuck in `ROLLBACK_IN_PROGRESS` | Wait for rollback to complete. Do not attempt to delete the stack manually until it reaches `ROLLBACK_COMPLETE`. |
| `ValidationError: Template format error` | Check your YAML indentation. Ensure intrinsic functions (e.g., `!Ref`) are correctly formatted. |
| `Resource handler returned message: ... already exists` | You are trying to create a resource (like an S3 bucket or IAM role) with a hardcoded name that is already in use. |
| EC2 instances not joining the ASG | Check the User Data script in the Launch Template for syntax errors or missing packages (`httpd`). |

---

## Deployment Errors

### ❌ Stack Creation Fails and Rolls Back
**Symptom:** You run `aws cloudformation create-stack`, but the status quickly changes to `ROLLBACK_IN_PROGRESS`.

**Cause 1:** Hardcoded Resource Names.
Many AWS resources (like IAM Roles and S3 buckets) require globally or account-unique names. If you hardcode a `RoleName` and it already exists, the deployment fails.
**Fix 1:** Remove the hardcoded `RoleName` from your template and allow CloudFormation to dynamically generate a unique physical ID.

**Cause 2:** Dependency Violation.
You attempted to reference a resource before it was fully created, or the underlying resource failed to provision (e.g., requesting an EC2 instance type not available in the selected AZ).
**Fix 2:** Open the CloudFormation Console, navigate to the **Events** tab for your stack, and look for the first event with the status `CREATE_FAILED`. The `Status reason` column will detail exactly why the resource failed.

---

## Configuration Errors

### ❌ YAML Syntax or Validation Errors
**Symptom:** The CLI returns `ValidationError` immediately when you run the `create-stack` or `validate-template` command.

**Cause:** CloudFormation templates are extremely strict about YAML indentation, allowed properties, and intrinsic function usage.
**Fix:** 
1. Run `aws cloudformation validate-template --template-body file://main-stack.yaml`. This will catch basic syntax errors before attempting a deployment.
2. Ensure you are using the correct short-form syntax for intrinsic functions (e.g., `!Sub` instead of `Fn::Sub`) consistently.

---

## Execution Errors

### ❌ EC2 Instances Fail Health Checks
**Symptom:** The stack deploys successfully (`CREATE_COMPLETE`), but the Target Group shows the EC2 instances as `Unhealthy`, and the Auto Scaling Group keeps terminating and replacing them.

**Cause:** The EC2 instances are booting up, but the Apache web server (`httpd`) is either not installing, not starting, or not responding on Port 80.
**Fix:**
1. SSH into one of the running EC2 instances (if you attached a Key Pair).
2. Check the user data execution logs: `cat /var/log/cloud-init-output.log`.
3. Verify if `httpd` is running: `systemctl status httpd`.
4. Update the `UserData` property in your CloudFormation Launch Template to fix any script errors, then perform a Stack Update.

---

## 🔍 Debug Commands

Use these CLI commands to probe your CloudFormation stack and identify failures:

**Validate Template Syntax**
```bash
aws cloudformation validate-template \
    --template-body file://main-stack.yaml
```

**Get the Root Cause of a Failure**
*(This fetches the specific event that triggered a rollback)*
```bash
aws cloudformation describe-stack-events \
    --stack-name my-app-stack \
    --query "StackEvents[?ResourceStatus=='CREATE_FAILED'].{Resource:LogicalResourceId, Reason:ResourceStatusReason}" \
    --output table
```

**Check Target Group Health (To debug ASG issues)**
```bash
aws elbv2 describe-target-health \
    --target-group-arn <YOUR-TARGET-GROUP-ARN> \
    --query "TargetHealthDescriptions[*].[Target.Id, TargetHealth.State, TargetHealth.Description]" \
    --output table
```
