# Troubleshooting Guide

When working with CloudFormation, deployments may occasionally fail or rollback. Here is how to diagnose common issues.

## 1. Stack Creation Fails (ROLLBACK_IN_PROGRESS)
If a stack fails to create, CloudFormation will automatically roll back and delete all resources it created up to the point of failure.
**How to fix:**
- Go to the CloudFormation Console.
- Select your stack and click the **Events** tab.
- Look for the first event with the status `CREATE_FAILED`.
- The **Status reason** column will usually provide the exact cause (e.g., "Invalid AMI ID", "Parameter missing", or "Security Group rule already exists").
- Correct the YAML template and re-deploy.

## 2. EC2 Instances Failing Health Checks
If your stack creates successfully, but your instances are constantly being terminated and recreated by the ASG.
**Possible Causes:**
- **User Data Error:** The `index.html` file isn't being created, or Apache isn't starting. The ALB health check looks for an HTTP 200 response on `/`. Check the `/var/log/cloud-init-output.log` on the instance.
- **Grace Period too short:** The instance takes longer to boot and install Apache than the ASG's 120-second `HealthCheckGracePeriod`. Increase the grace period in the template.
- **Security Groups:** The `EC2SecurityGroup` is not allowing Port 80 from the `ALBSecurityGroup`.

## 3. Cannot Access the Web Page via ALB
- Ensure you are using the ALB's DNS name (from the Outputs tab), not the IP of an EC2 instance.
- Verify the `ALBSecurityGroup` allows Inbound Port 80 from `0.0.0.0/0`.
- Check the Target Group in the EC2 Console. Ensure the instances are registered and show as `Healthy`.

## 4. Drift Detected
If you run `05-detect-drift.sh` and it reports drift, it means someone manually changed a resource in the AWS Console (e.g., manually edited a Security Group rule).
**How to fix:**
- CloudFormation cannot automatically fix drift. You must either manually change the resource back to match the template, or update your template to match the new manual configuration and deploy a Change Set.
