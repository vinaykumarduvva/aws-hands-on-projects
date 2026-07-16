# Project 11 Security Protocols: CloudFormation

This document outlines the security posture of the infrastructure deployed via CloudFormation, highlighting how automated provisioning enforces strict security boundaries.

## 🔐 IAM & Access Control

### CloudFormation Service Role
By default, CloudFormation uses the credentials of the IAM user executing the stack deployment. To adhere to the principle of least privilege in production, it is a best practice to pass a **Service Role** to CloudFormation.
- This allows the IAM user to only have the `cloudformation:*` permission.
- CloudFormation assumes the Service Role to actually provision the underlying resources (VPC, EC2, ALB).

### EC2 Instance Profile (Role)
Although not explicitly modeled in this specific baseline template, future iterations should attach an **IAM Instance Profile** to the EC2 Launch Template.
- Instead of baking long-term access keys into the EC2 instance, the Instance Profile securely vends temporary, rotating credentials to the EC2 instances.

## 🛡️ Network Security

The CloudFormation template provisions a secure network foundation mimicking enterprise best practices.

### VPC Isolation
- Resources are deployed into a custom, isolated Virtual Private Cloud (VPC), separate from other workloads.
- The subnets span multiple Availability Zones to ensure high availability.

### Security Group Chaining
Security is enforced using strict Security Group chaining rules defined in the YAML:
1. **`ALBSecurityGroup`:** Acts as the public perimeter. It allows inbound HTTP (Port 80) traffic from `0.0.0.0/0` (the internet).
2. **`WebServerSecurityGroup`:** Attached to the EC2 instances. It blocks all direct internet access. It **only** allows inbound HTTP traffic if the source is the `ALBSecurityGroup`. 
   - This makes it physically impossible for an attacker to bypass the Load Balancer and hit the EC2 instances directly.

## 🔒 Encryption

### Data at Rest
- **EBS Volumes:** The root EBS volumes attached to the EC2 instances via the Launch Template should have `Encrypted: true` specified in the Block Device Mappings, utilizing the default AWS KMS key (`aws/ebs`).

### Data in Transit
- **TLS/HTTPS:** While this baseline project uses HTTP (Port 80) for simplicity, a production CloudFormation template would provision an HTTPS Listener on the ALB and attach an ACM (AWS Certificate Manager) SSL/TLS certificate to encrypt all client-to-ALB traffic in transit.

## 📋 Compliance & Best Practices

- **Infrastructure as Code Auditing:** Because the entire environment is defined in YAML, every security rule, open port, and IAM permission can be reviewed, linted (using tools like `cfn-lint`), and approved in a pull request *before* it is ever deployed.
- **Drift Detection:** CloudFormation Drift Detection can be run periodically to ensure no administrator has manually modified Security Groups (e.g., opening port 22 to the world) outside of the IaC pipeline.
- **IMDSv2:** The EC2 Launch Template should explicitly require Instance Metadata Service Version 2 (IMDSv2) to protect against Server-Side Request Forgery (SSRF) vulnerabilities.
