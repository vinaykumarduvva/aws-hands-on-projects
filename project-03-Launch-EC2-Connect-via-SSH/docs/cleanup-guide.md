# Comprehensive Cleanup Guide

Leaving EC2 instances running indefinitely is the most common way beginners incur massive unexpected AWS bills. If you exceed the 750 hours provided by the Free Tier, you will be billed by the second for compute, and by the gigabyte for the EBS root volume storage.

You must terminate your instance when you are finished testing.

---

## 🧹 Step-by-Step Manual Teardown Logic

### Step 1: Terminate the EC2 Instance
Terminating an instance permanently destroys the virtual machine and automatically deletes the attached EBS hard drive.
1. Navigate to the **EC2 Dashboard** → **Instances**.
2. Select the checkbox next to your `My-First-Web-Server` instance.
3. Click the **Instance state** dropdown menu at the top.
4. Click **Terminate instance**.
5. Confirm by clicking **Terminate** in the popup box.
6. The state will change to `Shutting-down` and eventually `Terminated`. 

*(Note: Terminated instances remain visible in the console with a "Terminated" status for about an hour before disappearing entirely. You are not billed for them during this time).*

### Step 2: Delete the Security Group
Security Groups are free, but keeping unused Security Groups clutters your environment.
1. Navigate to **Network & Security** → **Security Groups**.
2. Select your `web-server-sg`.
3. Click **Actions** → **Delete security groups**.
4. Confirm deletion. 

*(Note: You cannot delete a Security Group if an active EC2 instance is still using it. You must wait for the instance to fully terminate first).*

### Step 3: Delete the Key Pair
Key Pairs are also free to store, but if you do not plan on reusing this specific key, you should delete it from AWS.
1. Navigate to **Network & Security** → **Key Pairs**.
2. Select your `my-web-key`.
3. Click **Actions** → **Delete**.
4. Type `Delete` to confirm.
5. You can now safely delete the `.pem` file from your local hard drive.

---

## ✅ Final Verification
1. Navigate to the main **EC2 Dashboard**.
2. Under **Resources**, verify that:
   - **Instances (running):** 0
   - **Volumes:** 0 (This confirms the EBS drive was successfully destroyed).