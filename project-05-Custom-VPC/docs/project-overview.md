# Project 05: Custom VPC Overview

## 🎯 Business Problem

By default, AWS provisions a "Default VPC" in every region. While this is convenient for quick testing, it is entirely inappropriate for production environments. A Default VPC lacks logical segmentation, places all resources in public subnets by default, and does not adhere to enterprise security standards.

Organizations require robust, secure, and highly customizable network foundations to isolate their application tiers, protect databases from public access, and strictly control inbound and outbound traffic flows.

## 🚀 Solution

In this project, we build a production-grade AWS network from absolute scratch — architecting the exact VPC topology utilized by Fortune 500 companies. This Custom VPC establishes a secure boundary for all future cloud deployments.

We logically divide a large address space (`10.0.0.0/16`) into smaller, isolated subnets across multiple Availability Zones. By implementing both Public and Private subnets, we can place internet-facing resources (like load balancers and bastion hosts) in the public tier, while securely hiding backend servers and databases in the private tier.

## 🧠 Learning Objectives

Upon completing this project, you will:

- **Understand VPC Fundamentals:** Comprehend what a Virtual Private Cloud is, why it is critical, and how it logically isolates your AWS resources.
- **Master Subnetting:** Learn to divide a VPC CIDR block into public and private subnets, distributed across at least two Availability Zones for High Availability.
- **Configure Internet Access:** Attach an Internet Gateway (IGW) to provide public subnets with bidirectional internet connectivity.
- **Implement Route Tables:** Configure explicit routing rules to dictate exactly where network traffic is allowed to flow.
- **Deploy NAT Gateways:** Enable private instances to securely download patches and updates from the internet without exposing them to inbound attacks.
- **Understand Network Security:** Grasp the critical differences and layered defense strategy of using Security Groups (stateful) and Network ACLs (stateless).
- **Verify Connectivity:** Launch EC2 instances in both public and private subnets to practically validate your routing and security configurations.