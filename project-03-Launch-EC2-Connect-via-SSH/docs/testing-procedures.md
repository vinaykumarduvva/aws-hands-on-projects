# Testing & Validation Procedures

To ensure your EC2 instance is configured correctly and securely, follow these validation steps.

---

## 🧪 Scenario 1: Validate User Data Execution (Web Server)

**Goal:** Prove that the bootstrap script successfully installed Apache and started the service.

1. Obtain the **Public IPv4 address** of your running EC2 instance from the console.
2. Open a web browser and navigate to `http://<Public-IP>`.
3. **Expected Outcome:** You should see the exact HTML message you coded in the User Data script: "Hello from my first AWS EC2 Web Server! Bootstrapping successful."
   *If the browser spins indefinitely and times out, see Scenario 2.*

---

## 🧪 Scenario 2: Validate Security Group Rules (Firewall Test)

**Goal:** Prove that the Security Group is enforcing your intended network boundary.

1. In the EC2 console, edit the Inbound Rules of your `web-server-sg` Security Group.
2. **Delete** the rule allowing HTTP (Port 80) from `0.0.0.0/0`. Save the rule.
3. Refresh your web browser.
4. **Expected Outcome:** The page will stop loading immediately and eventually time out (`ERR_CONNECTION_TIMED_OUT`). The AWS hypervisor is now dropping your HTTP packets before they reach the instance.
5. Re-add the Port 80 rule from `0.0.0.0/0` to restore access.

---

## 🧪 Scenario 3: Validate SSH Connection & OS Introspection

**Goal:** Prove you can access the underlying operating system and verify its state.

1. Connect to the instance via your terminal using your `.pem` key:
   ```powershell
   ssh -i my-web-key.pem ec2-user@<Public-IP>
   ```
2. Once connected, check the status of the Apache web server daemon:
   ```bash
   systemctl status httpd
   ```
   **Expected Outcome:** The output should show `Active: active (running)` in green text.
3. Elevate privileges and check the User Data execution logs to prove your script ran at boot:
   ```bash
   sudo cat /var/log/cloud-init-output.log
   ```
   **Expected Outcome:** You should see the massive output of `yum update` downloading packages, followed by the installation of `httpd`.
4. Type `exit` to terminate the SSH session.