# Project 4 — S3 Versioning, Lifecycle Policies & Cross-Region Replication

[![AWS](https://img.shields.io/badge/AWS-S3-orange?style=flat&logo=amazon-aws)](https://aws.amazon.com/s3/)
[![Level](https://img.shields.io/badge/Level-Beginner-green?style=flat)](../README.md)
[![Free Tier](https://img.shields.io/badge/Cost-Free%20Tier-brightgreen?style=flat)](https://aws.amazon.com/free/)
[![Region](https://img.shields.io/badge/Region-ap--south--1%20%7C%20ap--south--2-blue?style=flat)](https://aws.amazon.com/about-aws/global-infrastructure/)

---

## Overview

Implemented Amazon S3's core data protection features from scratch —
versioning for point-in-time recovery, lifecycle policies for automated
cost optimization, and cross-region replication for disaster recovery.
These are the same patterns used by production teams at companies of
every size to protect data, meet compliance requirements, and reduce
storage costs by up to 95% on aging data.

> **Real-world context:** Every company storing data on S3 uses at least
> one of these features. A Solutions Architect is expected to design
> storage strategies using all three together. This project demonstrates
> exactly that end-to-end design.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS Account                                  │
│                                                                      │
│   ┌──────────────────────────────────┐                              │
│   │   SOURCE BUCKET (ap-south-1)    │                              │
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
│   │   Day 30  → S3 Standard-IA       │──────────────────────────►  │
│   │   Day 90  → S3 Glacier           │                              │
│   │   Day 365 → Expire               │                              │
│   │                                  │                              │
│   │   IAM Replication Role ──────────┤                              │
│   └──────────────────────────────────┘                              │
│                                                                      │
│   ┌──────────────────────────────────┐                              │
│   │   DESTINATION BUCKET (ap-south-2) │                              │
│   │   s3-versioning-lab-yourname-    │                              │
│   │   replica                        │                              │
│   │                                  │                              │
│   │   Versioning: ENABLED            │                              │
│   │   ReplicationStatus: REPLICA     │                              │
│   │   Automatic DR copy of all       │                              │
│   │   objects written to source      │                              │
│   └──────────────────────────────────┘                              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## AWS Services Used

| Service | Purpose | Free Tier |
|---|---|---|
| Amazon S3 | Object storage — versioning, lifecycle, replication | 5 GB / 12 months |
| IAM Role | Grants S3 permission to replicate cross-region | Always free |
| CloudWatch | S3 storage metrics and monitoring | 10 metrics free |

---

## S3 Storage Classes Reference

| Storage Class | Best For | Retrieval Time | vs Standard |
|---|---|---|---|
| S3 Standard | Frequently accessed — daily use | Instant | Baseline |
| S3 Standard-IA | Infrequent — accessed monthly | Instant | ~58% cheaper |
| S3 Glacier Instant | Archives — accessed quarterly | Instant | ~68% cheaper |
| S3 Glacier Flexible | Long-term archives | 1–12 hours | ~85% cheaper |
| S3 Glacier Deep Archive | 7–10 year retention | 12–48 hours | ~95% cheaper |

> Lifecycle policies automate moving objects through these classes —
> this is how companies save thousands per month on S3 without
> any manual intervention.

---

## Prerequisites

- AWS account with IAM admin user (Project 1 ✅)
- AWS CLI v2 installed and configured on Windows (Project 1 ✅)
- Familiarity with S3 basics — buckets, objects, upload (Project 2 ✅)
- Default VPC in ap-south-1

Verify before starting:
```powershell
aws sts get-caller-identity
aws configure get region
# Expected: ap-south-1
```

---

## Repository Structure

```
project-04-s3-versioning/
│
├── README.md                        ← This file
│
├── scripts/
│   ├── lifecycle-policy.json        ← Lifecycle rule JSON
│   └── replication-policy.json      ← IAM replication permissions policy
│
├── docs/
│   └── storage-class-notes.md       ← Personal reference on storage classes
│
└── screenshots/
    ├── 01-versioning-enabled.png
    ├── 02-multiple-versions.png
    ├── 03-delete-marker.png
    ├── 04-file-recovered.png
    ├── 05-lifecycle-policy.png
    ├── 06-replication-rule.png
    ├── 07-replica-in-west.png
    └── 08-replication-completed.png
```

---

## Cost Estimate

| Resource | Free Tier Allowance | This Project | Cost |
|---|---|---|---|
| S3 Standard storage | 5 GB / 12 months | < 1 MB test files | $0.00 |
| PUT/COPY requests | 2,000 / month free | ~20 requests | $0.00 |
| GET requests | 20,000 / month free | ~50 requests | $0.00 |
| Cross-region transfer | Not free | < 1 KB replicated | ~$0.00 |
| Glacier transitions | Not free | Policy created, not triggered | $0.00 |
| **Total** | | | **~$0.00** |

> ⚠️ Always run cleanup steps before the lifecycle policy triggers
> (Day 30+). Since we clean up immediately after testing, no
> Glacier transitions or storage charges apply.

---

## Key Variables Used Throughout

```powershell
$SOURCE_BUCKET = "s3-versioning-lab-yourname"
$DEST_BUCKET   = "s3-versioning-lab-yourname-replica"
$SOURCE_REGION = "ap-south-1"
$DEST_REGION   = "ap-south-2"
$ACCOUNT_ID    = aws sts get-caller-identity --query "Account" --output text
```

---

## Full Setup Guide

---

### Part 1 — Create Source Bucket with Versioning

#### Console
1. S3 → **Create bucket**
2. Name: `s3-versioning-lab-yourname` · Region: `ap-south-1`
3. Block Public Access: leave all **ON** (private bucket)
4. Bucket Versioning: **Enable**
5. Click **Create bucket**
6. Verify: bucket → Properties → Bucket Versioning → **Enabled**

#### AWS CLI
```powershell
# Create source bucket
aws s3api create-bucket `
  --bucket $SOURCE_BUCKET `
  --region $SOURCE_REGION

# Enable versioning
aws s3api put-bucket-versioning `
  --bucket $SOURCE_BUCKET `
  --versioning-configuration Status=Enabled

# Verify
aws s3api get-bucket-versioning --bucket $SOURCE_BUCKET
# Expected: { "Status": "Enabled" }
```

---

### Part 2 — Test Versioning

#### Step 1 — Create test files locally
```powershell
mkdir C:\Users\$env:USERNAME\s3-versioning-lab
cd C:\Users\$env:USERNAME\s3-versioning-lab

"Version 1 - original content. Created: $(Get-Date)" `
  | Out-File -FilePath "document.txt" -Encoding utf8
```

#### Step 2 — Upload version 1
```powershell
aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt

# List versions
aws s3api list-object-versions `
  --bucket $SOURCE_BUCKET --prefix document.txt `
  --query "Versions[*].{VersionId:VersionId,IsLatest:IsLatest}" `
  --output table
# Expected: one version, IsLatest = True
```

#### Step 3 — Overwrite with version 2
```powershell
"Version 2 - updated content. Updated: $(Get-Date)" `
  | Out-File -FilePath "document.txt" -Encoding utf8

aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt

# List versions — should show two now
aws s3api list-object-versions `
  --bucket $SOURCE_BUCKET --prefix document.txt `
  --query "Versions[*].{VersionId:VersionId,IsLatest:IsLatest}" `
  --output table
```

#### Step 4 — Overwrite with version 3 and save all version IDs
```powershell
"Version 3 - final content. Finalized: $(Get-Date)" `
  | Out-File -FilePath "document.txt" -Encoding utf8

aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt

# Save version IDs
$VERSIONS = aws s3api list-object-versions `
  --bucket $SOURCE_BUCKET `
  --prefix document.txt | ConvertFrom-Json

$V1_ID = $VERSIONS.Versions[-1].VersionId
$V2_ID = $VERSIONS.Versions[-2].VersionId
$V3_ID = $VERSIONS.Versions[0].VersionId

Write-Host "V1: $V1_ID"
Write-Host "V2: $V2_ID"
Write-Host "V3: $V3_ID"
```

#### Step 5 — Recover version 1 specifically
```powershell
aws s3api get-object `
  --bucket $SOURCE_BUCKET `
  --key document.txt `
  --version-id $V1_ID `
  recovered-v1.txt

cat recovered-v1.txt
# Expected: "Version 1 - original content"
```

#### Step 6 — Simulate deletion and recover
```powershell
# Delete (creates a delete marker — not a real delete)
aws s3 rm s3://$SOURCE_BUCKET/document.txt

# Confirm file appears gone
aws s3 cp s3://$SOURCE_BUCKET/document.txt test.txt
# Expected: 404 error

# Get the delete marker ID
$DELETE_MARKER_ID = (aws s3api list-object-versions `
  --bucket $SOURCE_BUCKET `
  --prefix document.txt | ConvertFrom-Json).DeleteMarkers[0].VersionId

# Remove the delete marker to restore the file
aws s3api delete-object `
  --bucket $SOURCE_BUCKET `
  --key document.txt `
  --version-id $DELETE_MARKER_ID

# Download restored file
aws s3 cp s3://$SOURCE_BUCKET/document.txt restored.txt
cat restored.txt
# Expected: Version 3 content (latest before deletion)
```

---

### Part 3 — Create Lifecycle Policy

#### scripts/lifecycle-policy.json
```json
{
  "Rules": [
    {
      "ID": "cost-optimization-policy",
      "Status": "Enabled",
      "Filter": {"Prefix": ""},
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ],
      "NoncurrentVersionTransitions": [
        {
          "NoncurrentDays": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "NoncurrentDays": 90,
          "StorageClass": "GLACIER"
        }
      ],
      "Expiration": {
        "Days": 365
      },
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 90
      },
      "AbortIncompleteMultipartUpload": {
        "DaysAfterInitiation": 7
      }
    }
  ]
}
```

#### Apply via CLI
```powershell
aws s3api put-bucket-lifecycle-configuration `
  --bucket $SOURCE_BUCKET `
  --lifecycle-configuration file://scripts/lifecycle-policy.json

# Verify
aws s3api get-bucket-lifecycle-configuration --bucket $SOURCE_BUCKET
```

#### What each rule does

| Rule | Trigger | Action |
|---|---|---|
| Transition current → IA | Day 30 | Move to Standard-IA (58% cheaper) |
| Transition current → Glacier | Day 90 | Move to Glacier (85% cheaper) |
| Transition noncurrent → IA | 30 days noncurrent | Old versions to IA |
| Transition noncurrent → Glacier | 90 days noncurrent | Old versions to Glacier |
| Expire current version | Day 365 | Permanently delete current |
| Delete noncurrent versions | 90 days noncurrent | Permanently delete old versions |
| Abort incomplete multipart | 7 days | Clean up failed uploads |

---

### Part 4 — Cross-Region Replication Setup

#### Step 1 — Create destination bucket in ap-south-2

```powershell
# Create destination bucket
aws s3api create-bucket `
  --bucket $DEST_BUCKET `
  --region $DEST_REGION `
  --create-bucket-configuration LocationConstraint=$DEST_REGION

# Enable versioning (required for CRR)
aws s3api put-bucket-versioning `
  --bucket $DEST_BUCKET `
  --versioning-configuration Status=Enabled

# Verify
aws s3api get-bucket-versioning --bucket $DEST_BUCKET
# Expected: { "Status": "Enabled" }
```

#### Step 2 — Create IAM replication role

```powershell
# Create role with S3 trust policy
aws iam create-role `
  --role-name s3-replication-role `
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "s3.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach permissions policy (saved as scripts/replication-policy.json)
aws iam put-role-policy `
  --role-name s3-replication-role `
  --policy-name s3-replication-permissions `
  --policy-document file://scripts/replication-policy.json

# Get role ARN for next step
$ROLE_ARN = aws iam get-role `
  --role-name s3-replication-role `
  --query "Role.Arn" --output text

Write-Host "Role ARN: $ROLE_ARN"
```

#### scripts/replication-policy.json
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::SOURCE-BUCKET-NAME"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging"
      ],
      "Resource": "arn:aws:s3:::SOURCE-BUCKET-NAME/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Resource": "arn:aws:s3:::DESTINATION-BUCKET-NAME/*"
    }
  ]
}
```

> Replace `SOURCE-BUCKET-NAME` and `DESTINATION-BUCKET-NAME` with
> your actual bucket names before applying.

#### Step 3 — Enable replication on source bucket

```powershell
aws s3api put-bucket-replication `
  --bucket $SOURCE_BUCKET `
  --replication-configuration "{
    `"Role`": `"$ROLE_ARN`",
    `"Rules`": [{
      `"ID`": `"replicate-to-ap-south-2`",
      `"Status`": `"Enabled`",
      `"Filter`": {`"Prefix`":`"`"},
      `"Destination`": {
        `"Bucket`": `"arn:aws:s3:::$DEST_BUCKET`",
        `"StorageClass`": `"STANDARD`"
      },
      `"DeleteMarkerReplication`": {
        `"Status`": `"Enabled`"
      }
    }]
  }"

# Verify replication config
aws s3api get-bucket-replication --bucket $SOURCE_BUCKET
```

---

### Part 5 — Test Cross-Region Replication

```powershell
# Upload test file to source
"CRR Test — uploaded $(Get-Date)" `
  | Out-File -FilePath "crr-test.txt" -Encoding utf8

aws s3 cp crr-test.txt s3://$SOURCE_BUCKET/crr-test.txt
Write-Host "Uploaded. Waiting 30 seconds for replication..."
Start-Sleep -Seconds 30

# Verify object exists in destination (ap-south-2)
aws s3api head-object `
  --bucket $DEST_BUCKET `
  --key crr-test.txt `
  --region $DEST_REGION
# Expected: object metadata with ReplicationStatus: REPLICA

# List destination bucket
aws s3 ls s3://$DEST_BUCKET --region $DEST_REGION
# Expected: crr-test.txt listed

# Confirm COMPLETED status on source
aws s3api head-object `
  --bucket $SOURCE_BUCKET `
  --key crr-test.txt
# Expected: "ReplicationStatus": "COMPLETED"
```

---

## Verification Checklist

Run through all of these before marking the project complete:

```powershell
# 1. Versioning enabled on source
aws s3api get-bucket-versioning --bucket $SOURCE_BUCKET
# Expected: Status = Enabled

# 2. Three versions of document.txt exist
aws s3api list-object-versions `
  --bucket $SOURCE_BUCKET --prefix document.txt `
  --query "Versions[*].VersionId" --output table
# Expected: three version IDs listed

# 3. Lifecycle policy applied
aws s3api get-bucket-lifecycle-configuration --bucket $SOURCE_BUCKET
# Expected: full lifecycle rules JSON printed

# 4. Replication configured
aws s3api get-bucket-replication --bucket $SOURCE_BUCKET
# Expected: replication config with role ARN and destination

# 5. CRR test file in destination
aws s3 ls s3://$DEST_BUCKET --region $DEST_REGION
# Expected: crr-test.txt listed

# 6. Replication status completed
aws s3api head-object --bucket $SOURCE_BUCKET --key crr-test.txt
# Expected: ReplicationStatus = COMPLETED
```

---

## Key Commands Reference

```powershell
# Enable versioning
aws s3api put-bucket-versioning `
  --bucket $BUCKET --versioning-configuration Status=Enabled

# List all versions of an object
aws s3api list-object-versions `
  --bucket $BUCKET --prefix filename.txt --output table

# Download a specific version
aws s3api get-object `
  --bucket $BUCKET --key filename.txt `
  --version-id VERSION_ID output-file.txt

# Delete specific version (permanent)
aws s3api delete-object `
  --bucket $BUCKET --key filename.txt --version-id VERSION_ID

# Apply lifecycle policy
aws s3api put-bucket-lifecycle-configuration `
  --bucket $BUCKET --lifecycle-configuration file://policy.json

# Get lifecycle policy
aws s3api get-bucket-lifecycle-configuration --bucket $BUCKET

# Apply replication config
aws s3api put-bucket-replication `
  --bucket $BUCKET --replication-configuration file://replication.json

# Check replication status on object
aws s3api head-object --bucket $BUCKET --key filename.txt
# Look for ReplicationStatus field
```

---

## How Versioning Works — Concept Summary

```
NORMAL UPLOAD (versioning on):
  PUT object → new version created → old version becomes noncurrent
  All versions preserved until explicitly deleted

DELETION (versioning on):
  DELETE object → delete marker created → object appears gone
  Actual versions still exist in storage
  Remove delete marker → object is restored instantly

PERMANENT DELETE:
  DELETE object with specific --version-id → that version gone forever
  No recovery possible after this operation

BILLING:
  Every version counts toward storage billing
  10 versions of a 1 MB file = 10 MB billed
  Use lifecycle noncurrent version expiration to control this
```

---

## How Lifecycle Policies Work — Concept Summary

```
Day 0   → Object uploaded to S3 Standard
Day 30  → Automatically moved to Standard-IA
           No action needed. No data loss. Instant retrieval still.
Day 90  → Automatically moved to Glacier Flexible
           Retrieval now takes 1-12 hours. Cost is 85% less.
Day 365 → Object permanently expired and deleted
           Storage cost goes to zero for this object.

Noncurrent versions (old overwritten copies):
Day 30  → Moved to Standard-IA
Day 90  → Moved to Glacier
           Then permanently deleted at 90 days noncurrent.
```

---

## How Cross-Region Replication Works — Concept Summary

```
New object written to source bucket (ap-south-1)
         │
         ▼
S3 service detects new version
         │
         ▼
S3 assumes s3-replication-role (your IAM role)
         │
         ▼
Role grants permission to read from source
         │
         ▼
Object copied to destination bucket (ap-south-2)
         │
         ▼
ReplicationStatus on source = COMPLETED (~15-30 seconds)
ReplicationStatus on destination object = REPLICA

Important notes:
- Only NEW objects replicate (existing objects do not replicate)
- Both buckets MUST have versioning enabled
- Replication is one-way by default (source → destination)
- Delete markers replicate if DeleteMarkerReplication is Enabled
- Encrypted objects can replicate with additional KMS config
```

---

## Cleanup — Full Teardown

```powershell
# Step 1 — Delete all versions from source bucket
$ALL_VERSIONS = aws s3api list-object-versions `
  --bucket $SOURCE_BUCKET | ConvertFrom-Json

foreach ($v in $ALL_VERSIONS.Versions) {
  aws s3api delete-object `
    --bucket $SOURCE_BUCKET `
    --key $v.Key `
    --version-id $v.VersionId | Out-Null
  Write-Host "Deleted version: $($v.Key) - $($v.VersionId)"
}

foreach ($m in $ALL_VERSIONS.DeleteMarkers) {
  aws s3api delete-object `
    --bucket $SOURCE_BUCKET `
    --key $m.Key `
    --version-id $m.VersionId | Out-Null
  Write-Host "Deleted marker: $($m.Key) - $($m.VersionId)"
}

# Step 2 — Delete source bucket
aws s3api delete-bucket `
  --bucket $SOURCE_BUCKET --region $SOURCE_REGION
Write-Host "Source bucket deleted"

# Step 3 — Empty and delete destination bucket
$DEST_VERSIONS = aws s3api list-object-versions `
  --bucket $DEST_BUCKET --region $DEST_REGION | ConvertFrom-Json

foreach ($v in $DEST_VERSIONS.Versions) {
  aws s3api delete-object `
    --bucket $DEST_BUCKET `
    --key $v.Key `
    --version-id $v.VersionId `
    --region $DEST_REGION | Out-Null
}

aws s3api delete-bucket `
  --bucket $DEST_BUCKET --region $DEST_REGION
Write-Host "Destination bucket deleted"

# Step 4 — Delete IAM replication role
aws iam delete-role-policy `
  --role-name s3-replication-role `
  --policy-name s3-replication-permissions

aws iam delete-role --role-name s3-replication-role
Write-Host "IAM role deleted"

# Step 5 — Final verification (all should return empty/error)
aws s3 ls | Select-String "versioning-lab"
aws iam get-role --role-name s3-replication-role
```

---

## Troubleshooting

| Problem | Likely Cause | Fix |
|---|---|---|
| `BucketAlreadyExists` | Name taken globally | Add random suffix to bucket name |
| Versioning won't enable | Conflicting bucket policy | Try enabling from console; check no deny policies |
| Objects not replicating | IAM role ARN wrong or versioning off on destination | Verify both buckets have versioning; check role ARN in replication config |
| `ReplicationStatus: FAILED` | Role missing permissions | Recheck `replication-policy.json` has correct source and destination ARNs |
| Cannot delete bucket | Versions still exist | Must delete all versions before deleting versioned bucket |
| `head-object` shows no ReplicationStatus | Object uploaded before replication was enabled | Upload a new test file — only new objects replicate |
| Lifecycle rule not appearing | Console cache | Wait 30 seconds and hard refresh the Management tab |

---

## Concepts Learned

| Concept | Explanation |
|---|---|
| **Versioning** | Every PUT creates a new version. DELETE creates a delete marker. No data is truly gone unless you delete a specific version ID. |
| **Delete marker** | A placeholder created when you delete a versioned object. Removing the marker restores the file. |
| **Noncurrent version** | Any version that is not the latest. Lifecycle policies can target these separately. |
| **Storage class transition** | Moving an object to a cheaper tier automatically. The object is still accessible — just at different cost and retrieval speed. |
| **Lifecycle expiration** | Permanent automatic deletion after N days. Used for log rotation, temp files, compliance retention windows. |
| **CRR** | Cross-Region Replication. Asynchronous copy of every new object to another region. Used for DR, compliance, latency. |
| **IAM service role** | A role assumed by an AWS service (S3 here) to perform actions on your behalf. Same pattern as EC2 instance profiles. |
| **ReplicationStatus** | `COMPLETED` on source = replica exists. `REPLICA` on destination = this is a copy. `FAILED` = check IAM permissions. |

---

## What I Would Do Differently in Production

- Enable **S3 Object Lock** (WORM) for compliance data that must never
  be modified or deleted within a retention period
- Use **S3 Replication Time Control (RTC)** to guarantee 99.99% of
  objects replicate within 15 minutes — needed for strict RPO requirements
- Add **KMS encryption** on both buckets and update the replication
  role to include `kms:Decrypt` on source and `kms:GenerateDataKey`
  on destination
- Use **S3 Inventory** to generate daily CSV reports of all object
  versions and their storage classes for cost auditing
- Enable **S3 Storage Lens** for organization-wide visibility into
  storage usage, activity, and cost optimization opportunities
- Set up **CloudWatch alerts** on `NumberOfObjects` and
  `BucketSizeBytes` metrics to catch unexpected storage growth
- Use **Terraform** to manage both buckets, lifecycle policies, and
  replication config as version-controlled infrastructure code

---

## Next Project

**Project 5 — Custom VPC: Subnets, Internet Gateway,**
**Route Tables & NAT Gateway**

Build a production-grade AWS network from scratch with public and
private subnets across two availability zones — the networking
foundation every cloud engineering role requires.

Services: VPC · Subnets · Internet Gateway · Route Tables ·
NAT Gateway · Security Groups · NACLs

---

## Further Reading

- [S3 Versioning — AWS Docs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
- [S3 Lifecycle Policies — AWS Docs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
- [Cross-Region Replication — AWS Docs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)
- [S3 Storage Classes — AWS Docs](https://aws.amazon.com/s3/storage-classes/)
- [S3 Pricing Calculator](https://aws.amazon.com/s3/pricing/)

---

*Part of the [AWS Cloud Engineering Bootcamp](../README.md)*
*14 projects · Beginner → Advanced · 100% AWS Free Tier*