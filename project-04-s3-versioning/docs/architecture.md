# Architecture

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS Account                                 │
│                                                                     │
│   ┌──────────────────────────────────┐                              │
│   │   SOURCE BUCKET (ap-south-1)     │                              │
│   │   s3-versioning-lab-yourname     │                              │
│   │                                  │                              │
│   │   Versioning: ENABLED            │                              │
│   │   ┌────────────────────────┐     │                              │
│   │   │  document.txt          │     │                              │
│   │   │  ├── v1 (noncurrent)   │     │                              │
│   │   │  ├── v2 (noncurrent)   │     │                              │
│   │   │  └── v3 (current) ✅   │     │                              │
│   │   └────────────────────────┘     │                              │
│   │                                  │   Cross-Region               │
│   │   Lifecycle Policy:              │   Replication                │
│   │   Day  0  → S3 Standard          │   (automatic, ~30 sec)       │
│   │   Day 30  → S3 Standard-IA       │──────────────────────────►   │
│   │   Day 90  → S3 Glacier           │                              │
│   │   Day 365 → Expire               │                              │
│   │                                  │                              │
│   │   IAM Replication Role ──────────┤                              │
│   └──────────────────────────────────┘                              │
│                                                                     │
│   ┌──────────────────────────────────┐                              │
│   │   DESTINATION BUCKET (ap-south-2)│                              │
│   │   s3-versioning-lab-yourname-    │                              │
│   │   replica                        │                              │
│   │                                  │                              │
│   │   Versioning: ENABLED            │                              │
│   │   ReplicationStatus: REPLICA     │                              │
│   │   Automatic DR copy of all       │                              │
│   │   objects written to source      │                              │
│   └──────────────────────────────────┘                              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---