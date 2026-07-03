# Architecture

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CUSTOM VPC — 10.0.0.0/16                         │
│                    Region: us-east-1                                │
│                                                                     │
│  ┌─────────────────────────┐    ┌─────────────────────────┐        │
│  │  Availability Zone A    │    │  Availability Zone B    │        │
│  │  us-east-1a             │    │  us-east-1b             │        │
│  │                         │    │                         │        │
│  │  ┌───────────────────┐  │    │  ┌───────────────────┐  │        │
│  │  │  PUBLIC SUBNET A  │  │    │  │  PUBLIC SUBNET B  │  │        │
│  │  │  10.0.1.0/24      │  │    │  │  10.0.2.0/24      │  │        │
│  │  │                   │  │    │  │                   │  │        │
│  │  │  Bastion Host     │  │    │  │  (Future: ALB)    │  │        │
│  │  │  Public IP ✅     │  │    │  │                   │  │        │
│  │  │  NAT Gateway      │  │    │  │                   │  │        │
│  │  └───────────────────┘  │    │  └───────────────────┘  │        │
│  │                         │    │                         │        │
│  │  ┌───────────────────┐  │    │  ┌───────────────────┐  │        │
│  │  │  PRIVATE SUBNET A │  │    │  │  PRIVATE SUBNET B │  │        │
│  │  │  10.0.3.0/24      │  │    │  │  10.0.4.0/24      │  │        │
│  │  │                   │  │    │  │                   │  │        │
│  │  │  Private Instance │  │    │  │  (Future: RDS)    │  │        │
│  │  │  No Public IP ✅  │  │    │  │                   │  │        │
│  │  └───────────────────┘  │    │  └───────────────────┘  │        │
│  └─────────────────────────┘    └─────────────────────────┘        │
│                                                                     │
│  Internet Gateway (IGW) ←→ Public Internet                         │
│  NAT Gateway (in Public Subnet A) → Private outbound only          │
└─────────────────────────────────────────────────────────────────────┘
```

> See `diagrams/vpc-architecture.png` for the full visual diagram.

---