# Comprehensive Deployment Guide

This guide details the complete process for deploying a serverless static website to Amazon S3, mimicking how frontend applications are hosted in production.

---

## 🚀 PRE-FLIGHT CHECKS

Before deploying cloud infrastructure, always validate your terminal session identity to ensure you are not accidentally deploying resources to the wrong AWS account.

Run these commands in PowerShell or Bash:
```powershell
# Confirm you are authenticated as the IAM Administrator (from Project 01)
aws sts get-caller-identity

# Confirm your default region
aws configure get region
```

---

## 🏗️ PART 1 — PROVISION THE S3 BUCKET

We must first create the logical container for our website code.

### Console Execution
1. Navigate to **S3** → **Create bucket**.
2. **Bucket name**: `portfolio-website-yourname` (Must be globally unique. Do not use spaces or uppercase letters).
3. **Region**: `US East (N. Virginia) us-east-1` (or your preferred region).
4. **Object Ownership**: ACLs disabled (default).
5. **Block Public Access settings for this bucket**: 
   - **CRITICAL:** Uncheck the box that says "Block *all* public access".
   - Check the warning box acknowledging that the current settings might result in this bucket and the objects within becoming public.
6. Click **Create bucket**.

---

## ⚙️ PART 2 — ENABLE STATIC WEBSITE HOSTING

By default, S3 acts as a storage drive. We must tell it to act as a web server.

### Console Execution
1. Click your newly created bucket to open it.
2. Navigate to the **Properties** tab.
3. Scroll all the way to the bottom to **Static website hosting**.
4. Click **Edit**.
5. Select **Enable**.
6. **Hosting type:** Host a static website.
7. **Index document:** Type `index.html` (This tells S3 which file to load when a user hits the root URL).
8. **Error document:** Type `error.html` (Optional, but best practice for custom 404 pages).
9. Click **Save changes**.
10. Scroll back down to **Static website hosting** and **copy the Bucket website endpoint URL**. You will need this later.

---

## 🔐 PART 3 — APPLY THE PUBLIC BUCKET POLICY

Even though we turned off the "Block Public Access" kill-switch, the files inside the bucket are still private by default. We must apply a JSON policy to grant the world read-access.

### Console Execution
1. Navigate to the **Permissions** tab of your bucket.
2. Scroll to **Bucket policy** and click **Edit**.
3. Paste the following JSON policy. **You MUST replace `YOUR-BUCKET-NAME` with your actual bucket name.**

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
        }
    ]
}
```
4. Click **Save changes**. You will now see a red "Public" tag attached to your bucket. This is expected and desired for a public website.

---

## 🚀 PART 4 — DEPLOY THE WEBSITE CODE

We will use the AWS CLI to rapidly sync a local directory of code to the S3 bucket.

### Local Execution (PowerShell or Bash)
1. Open your terminal and navigate to the `src/` folder of this project, which contains the provided HTML/CSS files.
   ```powershell
   cd "e:\AWS Hands-on Projects\project-02-s3-static-website\src"
   ```
2. Run the `aws s3 sync` command to upload all files to the bucket. Replace `<YOUR-BUCKET-NAME>` with your bucket.
   ```powershell
   aws s3 sync . s3://<YOUR-BUCKET-NAME>
   ```
   *Expected Output: You should see the CLI uploading `index.html`, `style.css`, etc.*

---

## 🌐 PART 5 — VALIDATE THE LIVE WEBSITE

1. Open your web browser.
2. Paste the **Bucket website endpoint URL** you copied in Part 2. (Format: `http://<bucket-name>.s3-website-<region>.amazonaws.com`).
3. You should see the custom HTML portfolio page rendered perfectly in your browser!