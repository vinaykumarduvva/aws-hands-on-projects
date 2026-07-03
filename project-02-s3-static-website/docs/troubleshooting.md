# Comprehensive Troubleshooting Guide

Below is a list of common failure states encountered when configuring S3 Static Websites, along with root causes and remediation steps.

---

## 🌐 Website Access Errors

| Symptom / Error | Root Cause Analysis | Remediation Steps |
|:----------------|:--------------------|:------------------|
| **`403 Forbidden` when accessing the website URL** | 1. **BPA is ON:** Block Public Access was not turned off.<br>2. **No Bucket Policy:** The JSON policy was not applied.<br>3. **Wrong URL:** You are using the REST API URL (`s3.amazonaws.com`) instead of the Website Endpoint URL (`s3-website.amazonaws.com`). | 1. Go to Permissions → Turn off Block Public Access.<br>2. Add the JSON Bucket Policy.<br>3. Go to Properties → scroll to the bottom → copy the specific Website Endpoint URL. |
| **`404 Not Found` when accessing the website URL** | S3 cannot find the `index.html` file. This usually happens if you uploaded the `src/` folder itself, rather than the files *inside* the folder. | Open your bucket in the console. If you see a folder called `src`, you uploaded it incorrectly. Delete the folder, go inside your local `src` folder, and run the `aws s3 sync . s3://bucket-name` command again. |
| **Website loads, but it looks broken (No CSS/Images)** | The HTML file loaded, but the browser cannot find `style.css`. This is usually a pathing issue within the HTML file itself, or the CSS file was not uploaded to S3. | Ensure all files from the `src/` directory were uploaded. Open `index.html` locally and verify the `<link rel="stylesheet" href="style.css">` tag is correct. |

---

## ⚙️ Configuration & Policy Errors

| Symptom / Error | Root Cause Analysis | Remediation Steps |
|:----------------|:--------------------|:------------------|
| **`Access Denied` when trying to save the Bucket Policy** | You cannot save a public bucket policy if "Block Public Access" is still turned on. AWS rejects the save attempt to protect you. | Navigate to the "Block public access (bucket settings)" section, click Edit, uncheck the master box, save, and type "confirm". THEN try to paste the Bucket Policy again. |
| **`Invalid principal in policy` or `Policy has invalid resource`** | The JSON formatting is broken, or you forgot to replace `YOUR-BUCKET-NAME` in the Resource ARN string with your actual bucket name. | Ensure the resource string looks exactly like this: `"arn:aws:s3:::my-unique-bucket-name-123/*"`. Do not forget the `/*` at the end. |

---

## 💻 CLI Sync Errors

| Symptom / Error | Root Cause Analysis | Remediation Steps |
|:----------------|:--------------------|:------------------|
| **`The user is not authorized to perform: s3:ListBucket`** | The AWS CLI is using the wrong credentials, or your IAM user does not have `AdministratorAccess` (or `AmazonS3FullAccess`). | Run `aws sts get-caller-identity` to verify you are logged in as your `admin` user from Project 01. Check the IAM console to ensure the user has the proper policies attached. |