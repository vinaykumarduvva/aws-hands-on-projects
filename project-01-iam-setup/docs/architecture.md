# Architecture: AWS Account Setup & IAM Foundations

This document outlines the foundational security architecture implemented for the AWS account.

## Overview

The architecture focuses on securing the AWS environment by applying IAM best practices, enforcing least-privilege access, and implementing proactive cost-monitoring controls.

## Architecture Diagram

<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 400">
  <rect width="600" height="400" fill="#f8f9fa" rx="10"/>
  <rect x="50" y="50" width="150" height="80" fill="#ffcccb" stroke="#d32f2f" stroke-width="2" rx="5"/>
  <text x="125" y="90" font-family="Arial" font-size="14" text-anchor="middle" font-weight="bold">Root User</text>
  <text x="125" y="110" font-family="Arial" font-size="12" text-anchor="middle">(Secured with MFA)</text>
  <rect x="50" y="250" width="150" height="80" fill="#c8e6c9" stroke="#388e3c" stroke-width="2" rx="5"/>
  <text x="125" y="290" font-family="Arial" font-size="14" text-anchor="middle" font-weight="bold">IAM Admin User</text>
  <text x="125" y="310" font-family="Arial" font-size="12" text-anchor="middle">(CLI & Console Access)</text>
  <rect x="350" y="100" width="180" height="60" fill="#bbdefb" stroke="#1976d2" stroke-width="2" rx="5"/>
  <text x="440" y="135" font-family="Arial" font-size="14" text-anchor="middle" font-weight="bold">CloudWatch Alarm</text>
  <rect x="350" y="220" width="180" height="60" fill="#ffe0b2" stroke="#f57c00" stroke-width="2" rx="5"/>
  <text x="440" y="255" font-family="Arial" font-size="14" text-anchor="middle" font-weight="bold">SNS Topic</text>
  <rect x="350" y="320" width="180" height="40" fill="#e1bee7" stroke="#8e24aa" stroke-width="2" rx="5"/>
  <text x="440" y="345" font-family="Arial" font-size="14" text-anchor="middle">Email Notification</text>
  <path d="M 440 160 L 440 215" stroke="#333" stroke-width="2" marker-end="url(#arrow)"/>
  <path d="M 440 280 L 440 315" stroke="#333" stroke-width="2" marker-end="url(#arrow)"/>
  <defs>
    <marker id="arrow" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#333" />
    </marker>
  </defs>
</svg>

## Component Details

1. **Root User**: The primary account owner. It is secured with Multi-Factor Authentication (MFA) and is not to be used for daily operations.
2. **IAM Admin User**: A dedicated administrative user (`admin-yourname`) created with `AdministratorAccess`. This user accesses AWS via the Management Console and programmatically via AWS CLI v2.
3. **CloudWatch Alarm**: Monitors estimated AWS charges and triggers when costs exceed a predefined threshold (e.g., $5).
4. **SNS Topic**: Receives alerts from CloudWatch and broadcasts them to subscribed endpoints.
5. **Email Notification**: Delivers the billing alert to the administrator's email, preventing unexpected cost overruns.

## Traffic & Workflow

- The **IAM Admin User** is the primary actor, interacting securely with AWS resources.
- If AWS usage generates costs exceeding the $5 threshold, **CloudWatch** triggers an alarm.
- The alarm publishes a message to an **SNS Topic**, which immediately dispatches an **Email Notification** to the account owner.
