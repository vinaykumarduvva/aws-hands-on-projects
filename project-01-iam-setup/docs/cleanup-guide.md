# Comprehensive Cleanup Guide

This project establishes the foundational identities (IAM) and guardrails (Budgets) for your AWS account. As such, **you should not clean up these resources if you intend to continue using this AWS account.**

However, if you are working in a temporary sandbox environment or simply wish to practice tearing down infrastructure, follow the guide below.

---

## 🛑 Warning: DO NOT Delete the Root User
The Root User cannot be deleted without closing the entire AWS Account. If you attempt to close the AWS account, all resources running inside it will eventually be permanently destroyed.

---

## 🧹 Step-by-Step Manual Teardown Logic

### Step 1: Dismantle Financial Guardrails (Budgets)
AWS Budgets are free for the first two budgets, but if you create more, they cost money.
1. Log into the AWS Console.
2. Navigate to **AWS Budgets**.
3. Select your `Zero Spend Budget`.
4. Click **Actions** → **Delete**.

### Step 2: Invalidate CLI Credentials
You must destroy the cryptographic keys used by your local operating system.
1. Navigate to the **IAM Dashboard**.
2. Click **Users** → select your `admin` user.
3. Click the **Security credentials** tab.
4. Scroll to **Access keys**.
5. Click **Make Inactive**, then click **Delete**.
6. On your local computer, open the `~/.aws/credentials` file and delete the text inside, or delete the file entirely. Your `aws cli` will no longer function.

### Step 3: Delete the IAM User
1. In the IAM Console, navigate to **Users**.
2. Select your `admin` user.
3. Click **Delete**. You will be prompted to type the username to confirm deletion.

### Step 4: Delete the IAM Group
1. Navigate to **User groups**.
2. Select the `Administrators` group.
3. Click **Delete**.

### Step 5: (Optional) Remove Root MFA
If you are closing the account, you may wish to decouple your authenticator app from the root account to free up space in your app.
1. Log in as the Root User.
2. Go to **Security credentials**.
3. Under **Multi-factor authentication (MFA)**, click **Remove**.