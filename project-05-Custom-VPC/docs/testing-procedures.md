# Testing Procedures

This document outlines the systematic tests required to validate that the VPC, Gateways, Route Tables, and Security Groups are functioning exactly as architected.

## ✅ Test 1: Validate Public Subnet Routing

This test ensures that the Internet Gateway (IGW) is correctly attached and that the Public Route Table is properly distributing traffic.

1. Obtain the **Public IP** of the Bastion host (located in `public-subnet-a`).
2. Open your terminal (or PuTTY) and SSH into the Bastion:
   ```bash
   ssh -i aws-ec2-keypair.pem ec2-user@<BASTION_PUBLIC_IP>
   ```
3. Once connected, confirm you have outbound internet access by curling an external service:
   ```bash
   curl -s https://checkip.amazonaws.com
   ```
   **Expected Result:** The terminal outputs the Public IP of your Bastion host. This proves the IGW route is functioning.

## ✅ Test 2: Verify Private Instance Isolation

This test ensures that the Private Subnet is truly private and has no direct exposure to the public internet.

1. From your local workstation (not the bastion), attempt to ping the Private Instance's **Private IP**:
   ```bash
   ping <PRIVATE_INSTANCE_IP>
   ```
   **Expected Result:** The ping times out. Private IPs (`10.0.x.x`) are not routable over the public internet.
2. Check the AWS Management Console or CLI to confirm the Private Instance does not have a Public IP assigned:
   ```bash
   aws ec2 describe-instances --instance-ids <PRIVATE_INSTANCE_ID> --query "Reservations[0].Instances[0].PublicIpAddress"
   ```
   **Expected Result:** `None` or `null`.

## ✅ Test 3: Validate Bastion Security Group Hop

This test ensures that the Private Instance's Security Group correctly trusts the Bastion Host.

1. Ensure your SSH key is available on the Bastion Host (e.g., via `ssh -A` or temporarily copying the `.pem` file).
2. From the Bastion Host terminal, attempt to ping the Private Instance:
   ```bash
   ping -c 3 <PRIVATE_INSTANCE_IP>
   ```
   **Expected Result:** The ping fails (100% packet loss). This is expected because our Security Group only allows Port 22 (SSH), not ICMP (Ping).
3. SSH into the Private Instance from the Bastion:
   ```bash
   ssh -i /path/to/key.pem ec2-user@<PRIVATE_INSTANCE_IP>
   ```
   **Expected Result:** Successful login to the Private Instance.

## ✅ Test 4: Validate NAT Gateway Outbound Connectivity

This is the most critical test. It proves that the Private Route Table is successfully pushing traffic through the NAT Gateway.

1. Connect to the Private Instance (either via the SSH jump above, or using SSM Session Manager).
2. Request your public IP from an external service:
   ```bash
   curl -s https://checkip.amazonaws.com
   ```
   **Expected Result:** The terminal outputs the Elastic IP of the **NAT Gateway**, NOT the instance's IP.
3. Test a package update to simulate patching a backend server:
   ```bash
   sudo yum update -y
   ```
   **Expected Result:** The package manager successfully connects to the external Amazon Linux repositories and downloads updates.

If all 4 tests pass, your VPC architecture is mathematically proven to be correct!