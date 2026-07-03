# Architecture Design

This document details the architecture provisioned by the CloudFormation template in Project 11.

![Architecture Diagram](../architecture/architecture.svg)

## Overview

The infrastructure relies on a Virtual Private Cloud (VPC) spanned across two Availability Zones for high availability. 
It features a public-facing Application Load Balancer (ALB) distributing traffic to EC2 instances managed by an Auto Scaling Group (ASG).

## Infrastructure Components

1. **Networking Layer**
   - **VPC**: A single VPC with a custom CIDR block (default `10.1.0.0/16`).
   - **Subnets**: Two public subnets in different Availability Zones (defaults `10.1.1.0/24` and `10.1.2.0/24`).
   - **Internet Gateway**: Attached to the VPC to enable public internet access.
   - **Route Tables**: A public route table routing `0.0.0.0/0` traffic to the Internet Gateway, associated with both public subnets.

2. **Compute Layer**
   - **Launch Template**: Defines the blueprint for EC2 instances, including AMI, instance type, security groups, and user data.
   - **Auto Scaling Group (ASG)**: Maintains the desired number of instances, scaling out or in based on CPU utilization.

3. **Load Balancing**
   - **Application Load Balancer (ALB)**: Internet-facing, sits in the public subnets.
   - **Target Group**: Groups EC2 instances for the ALB to route traffic to and perform health checks.

4. **Security**
   - **Security Groups**: Granular control of inbound traffic, ensuring EC2 instances only receive HTTP traffic from the ALB.

All of these resources are defined as Code in the `main-stack.yaml` template, ensuring consistent and repeatable deployments.
