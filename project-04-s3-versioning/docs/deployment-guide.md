# Deployment Guide

## Automated Scripts Available
> [!TIP]
> **Dual-Platform Execution:** This project contains fully automated deployment and teardown scripts for both Windows (PowerShell) and Linux/macOS (Bash). Check the `scripts/` directory for `.ps1` files and the `bash-scripts/` directory for `.sh` files.

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

## Cleanup Guide

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

