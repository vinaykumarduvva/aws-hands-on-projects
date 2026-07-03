This guide covers common issues encountered when connecting to EC2 instances via PuTTY, Session Manager, or accessing web servers, along with their root causes and immediate resolutions.

---

## Quick Reference Troubleshooting Matrix

| Problem | Potential Cause | Verification & Fix |
| :--- | :--- | :--- |
| **PuTTY shows:**<br>`Connection refused` | Security group is missing the SSH rule, or the instance is still booting up. | 1. Check that the security group has port `22` open to your current IP.<br>2. Wait for the instance status checks to show **2/2 passed** in the EC2 console. |
| **PuTTY shows:**<br>`Connection timed out` | Incorrect IP address used, or the security group is not attached to the instance. | 1. Verify the **Public IPv4 address** directly in the EC2 console.<br>2. Confirm that the `ec2-web-sg` security group is actively attached to the instance. |
| **PuTTY shows:**<br>`No supported authentication methods` | The wrong private key file format or path was selected in the PuTTY configuration. | Open your PuTTY session settings, browse your authentication credentials again, and specifically select the valid `.ppk` file. |
| **Apache page not loading**<br>in browser | The HTTP rule is missing in the security group, or the Apache service is not running. | 1. Check the security group for an inbound rule allowing port `80`.<br>2. SSH into the instance and start the service manually:<br>`sudo systemctl start httpd` |
| **Session Manager**<br>`Connect` button is greyed out | The required IAM role is not attached, or the Systems Manager (SSM) agent is still initializing. | 1. Ensure the instance IAM role includes the `AmazonSSMManagedInstanceCore` policy.<br>2. Wait up to 5 minutes after attaching the role for the agent to check in. |
| **Public IP changed**<br>after an instance restart | Default EC2 public IP addresses are dynamic and release upon instance stop/start. | This is expected behavior. Update your connection string with the new IP shown in the console. For a permanent fix, associate an **Elastic IP** to the instance. |
| **AWS CLI Command:**<br>`aws ec2 wait` times out | The instance initialization or state transition is taking longer than the default timeout window. | Run the manual status description command to check the exact state of the resource:<br>`aws ec2 describe-instances` |

---

> [!TIP]
> **Security Best Practice:** When opening port 22 for SSH troubleshooting, avoid using `0.0.0.0/0`. Always restrict the source to **My IP** to secure your instance from unauthorized access attempts.