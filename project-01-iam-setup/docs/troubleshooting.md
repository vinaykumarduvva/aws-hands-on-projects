# Comprehensive Troubleshooting Guide

Below is an exhaustive list of common failure states encountered when configuring IAM, AWS CLI, and Billing, along with root causes and remediation steps.

---

## 👤 IAM and Login Issues

| Symptom / Error | Root Cause Analysis | Remediation Steps |
|:----------------|:--------------------|:------------------|
| **Lost MFA device for Root Account** | The physical phone broke, was lost, or the authenticator app data was wiped. | You must use the "Troubleshoot MFA" workflow on the root login screen. It will require you to verify the email address AND the phone number attached to the account. If the phone number is invalid, you must contact AWS Support. |
| **IAM User Login fails (Invalid Credentials)** | You are likely on the wrong login page. IAM users cannot log in from the "Root User" page. | Ensure you are using the custom Sign-in URL that includes your 12-digit Account ID (e.g., `https://123456789012.signin.aws.amazon.com/console`). |
| **IAM User sees "Access Denied" or "API Error" banners** | The IAM User lacks permissions. They were either not added to the `Administrators` group, or the group does not have the `AdministratorAccess` policy attached. | Log back in as Root. Go to IAM → User groups → Check that the group has the policy attached, and check that the user is a member of the group. |

---

## 💻 CLI Configuration Failures

| Symptom / Error | Root Cause Analysis | Remediation Steps |
|:----------------|:--------------------|:------------------|
| **`Unable to locate credentials`** | The AWS CLI cannot find the `~/.aws/credentials` file, or the file is empty. | Run `aws configure` again and ensure you paste the Access Key ID and Secret Access Key correctly. |
| **`InvalidClientTokenId`** | The Access Key ID provided does not exist, or the Secret Access Key is incorrect (e.g., missing characters from a bad copy/paste). | Delete the old access key in the IAM Console, generate a new pair, and run `aws configure` again with the fresh keys. |
| **`AccessDeniedException` when running CLI commands** | The programmatic keys are valid, but the user attached to those keys does not have the necessary IAM permissions to execute the specific API call. | Verify in the IAM Console that the user whose keys you are using is actually in the `Administrators` group. |

---

## 💰 Billing Alert Issues

| Symptom / Error | Root Cause Analysis | Remediation Steps |
|:----------------|:--------------------|:------------------|
| **Cannot create AWS Budget ("Access Denied")** | Historically, IAM Users required explicit activation to view billing data, even if they had `AdministratorAccess`. | Log in as Root. Click account name in top right → Account. Scroll to **IAM User and Role Access to Billing Information**. Click Edit, activate IAM Access, and save. Try creating the budget again as the IAM user. |