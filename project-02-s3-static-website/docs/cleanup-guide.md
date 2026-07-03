# Comprehensive Cleanup Guide

To avoid unexpected charges and keep your AWS environment tidy, you should remove the resources created in this project once you have finished testing. 

Unlike the versioned bucket in Project 04, standard S3 buckets are relatively easy to delete, but they still must be empty first.

---

## 🧹 Step-by-Step Manual Teardown Logic

### Step 1: Empty the Bucket
An S3 bucket cannot be deleted if it contains any files. You must first empty the bucket.

**Via CLI (Recommended):**
Open your terminal and run the recursive delete command. This will iterate through all files and delete them instantly.
```powershell
aws s3 rm s3://<YOUR-BUCKET-NAME> --recursive
```

**Via Console:**
1. Navigate to the **S3** dashboard.
2. Click the radial button next to your bucket name (do not click the name itself).
3. Click the **Empty** button at the top.
4. Type `permanently delete` in the confirmation box and click **Empty**.

### Step 2: Delete the Bucket
Once the bucket is empty, you can destroy the bucket itself.

**Via CLI:**
```powershell
aws s3api delete-bucket --bucket <YOUR-BUCKET-NAME> --region us-east-1
```
*(Note: If your bucket is in a region other than `us-east-1`, you must specify the correct `--region` flag).*

**Via Console:**
1. Navigate to the **S3** dashboard.
2. Click the radial button next to your bucket name.
3. Click the **Delete** button at the top.
4. Type the name of the bucket in the confirmation box and click **Delete bucket**.

---

## ✅ Final Verification
Run the following command in your terminal to list all buckets in your account. If the teardown was successful, your portfolio bucket should no longer appear in the output.
```powershell
aws s3 ls
```