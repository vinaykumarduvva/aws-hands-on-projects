# Security Protocols & Compliance

This project establishes the fundamental security perimeter for your AWS account. Without these protocols in place, your account is vulnerable to automated credential stuffing attacks, leaked access keys, and unauthorized resource provisioning.

---

## 🔐 1. Identity Security Posture

### The Vulnerability of the Root User
The Root User is fundamentally different from an IAM user. It cannot be restricted by IAM policies. If a malicious actor gains access to your Root User, they can:
- Change your AWS Support plan to the most expensive tier.
- Delete your entire AWS Account permanently.
- Delete or modify AWS CloudTrail logs to hide their tracks.
- Bypass any Service Control Policies (SCPs) in AWS Organizations.

### Multi-Factor Authentication (MFA) Implementation
We mitigate the risk of password compromise by enforcing MFA on the Root User. By binding authentication to a physical device (or virtual authenticator app) that you control, a compromised password is no longer sufficient to breach the account.

---

## 🛡️ 2. Role-Based Access Control (RBAC)

In enterprise environments, assigning permissions directly to users (e.g., attaching the `AdministratorAccess` policy to `User: Alice` and `User: Bob` individually) is an anti-pattern. It leads to fragmented permissions, policy drift, and audit nightmares.

### The IAM Group Strategy
Instead, we utilize RBAC:
1. Define the Job Role (e.g., `Administrators`, `Developers`, `Auditors`).
2. Create an IAM Group for that role.
3. Attach the necessary IAM Policies (like `AdministratorAccess` or `ViewOnlyAccess`) to the Group.
4. Place the human IAM Users into the appropriate Group.

When Bob leaves the company, you simply delete his IAM User. When Alice transitions from Developer to Administrator, you move her from the Developer Group to the Admin Group. Permissions management scales seamlessly.

---

## 🚧 3. Programmatic Access Key Lifecycle

The `Access Key ID` and `Secret Access Key` generated in this project act as your programmatic username and password. 
- **Local Storage:** When you run `aws configure`, these keys are stored in plaintext on your local hard drive (in `~/.aws/credentials` on Linux/Mac, or `C:\Users\Name\.aws\credentials` on Windows).
- **Security Implication:** Any malware or script running on your machine can read these keys. If you accidentally commit this file or hardcode these keys into a script pushed to GitHub, bots will scrape the keys within seconds and use them to mine cryptocurrency on your account.
- **Best Practice:** Never share these keys. Rotate them every 90 days. If you suspect compromise, immediately delete the keys in the IAM Console.