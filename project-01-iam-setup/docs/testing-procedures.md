# Testing & Validation Procedures

Security configurations must be rigorously tested to ensure they function as intended. Follow these validation steps to confirm your IAM architecture is secure.

---

## 🧪 Scenario 1: Validate Root Account Lockdown

**Goal:** Prove that the root account cannot be accessed with just a password.

1. Open an Incognito/Private browsing window.
2. Navigate to the AWS Management Console login page.
3. Select **Root user** and enter your root email address and password.
4. **Expected Outcome:** You are immediately intercepted by an MFA prompt. If you cannot provide the 6-digit code from your authenticator app, login fails.

---

## 🧪 Scenario 2: Validate IAM User Sign-in

**Goal:** Prove that your new IAM Administrator can log in and manage resources.

1. Open an Incognito/Private browsing window.
2. Navigate to the custom **Console sign-in URL** generated during User creation (e.g., `https://<Account-ID>.signin.aws.amazon.com/console`).
3. Log in using your IAM `User name` (e.g., `admin`) and your custom password.
4. Navigate to the **EC2 Dashboard**.
5. **Expected Outcome:** The dashboard loads successfully without any red "Access Denied" or "API Error" banners, proving that the `AdministratorAccess` policy is functioning.

---

## 🧪 Scenario 3: Validate CLI Programmatic Access

**Goal:** Prove that your local operating system can authenticate to AWS securely.

1. Open your local terminal (Bash or PowerShell).
2. Run the Caller Identity command:
   ```powershell
   aws sts get-caller-identity
   ```
3. **Expected Outcome:** A JSON response indicating your IAM user ARN.
   ```json
   {
       "UserId": "AIDAxxxxxxxxxxxxxxxxx",
       "Account": "123456789012",
       "Arn": "arn:aws:iam::123456789012:user/admin"
   }
   ```
   *If the command returns `Unable to locate credentials` or `InvalidClientTokenId`, your `aws configure` step failed.*

---

## 🧪 Scenario 4: Validate Financial Guardrails

**Goal:** Prove that your AWS Budget is active and monitoring spend.

1. As the IAM user, navigate to the **AWS Budgets** console.
2. **Expected Outcome:** You should see a budget named `Zero Spend Budget` (or similar) with an amount of `$1.00`. The "Current vs budgeted" bar should be active, and the Status should be `OK`.