# Cleanup Guide

One of the primary benefits of using Infrastructure as Code (CloudFormation) is the ability to cleanly and completely tear down an entire environment without leaving orphaned resources behind.

## Destroying the Infrastructure

To avoid ongoing AWS charges, you should delete the CloudFormation stack when you are done experimenting.

### Method 1: Using the provided script (Recommended)
We have provided a cleanup script that handles the deletion process.
1. Open your terminal.
2. Run the cleanup script:
   ```bash
   ./scripts/06-cleanup.sh
   ```
   *(If using Windows PowerShell, run `.\scripts\06-cleanup.ps1`)*

### Method 2: Using the AWS CLI directly
You can trigger the stack deletion manually via the CLI:
```bash
aws cloudformation delete-stack --stack-name my-app-stack
```

### Method 3: Using the AWS Console
1. Log in to the AWS Management Console.
2. Navigate to **CloudFormation**.
3. Select the stack you created (e.g., `my-app-stack`).
4. Click the **Delete** button at the top right.
5. Confirm the deletion.

## Verifying Deletion

CloudFormation deletion happens asynchronously. To verify that all resources were successfully destroyed:

**Via CLI:**
```bash
aws cloudformation describe-stacks --stack-name my-app-stack
```
*Note: Once fully deleted, this command will return an error stating that the stack does not exist, which confirms success.*

**Via Console:**
Watch the **Events** tab in the CloudFormation console. You should see `DELETE_IN_PROGRESS` followed eventually by `DELETE_COMPLETE`. If a resource fails to delete (e.g., you manually modified an S3 bucket or security group), the stack will enter a `DELETE_FAILED` state, and you will need to manually remove the offending resource before retrying the stack deletion.
