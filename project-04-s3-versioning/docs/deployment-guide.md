# Comprehensive Deployment Guide

This guide details the complete, enterprise-grade process for provisioning S3 versioning, architecting lifecycle policies, and enabling Cross-Region Replication (CRR). We will walk through the conceptual "why" alongside the technical "how".

## 🚀 PRE-FLIGHT CHECKS

Before deploying cloud infrastructure, always validate your terminal session identity and regional configuration. Attempting to deploy replication policies with the wrong IAM permissions or in the wrong region will result in cascading failures.

Run these commands in PowerShell to confirm your environment is ready:
```powershell
# Confirm you are authenticated as an Administrator or Power User
aws sts get-caller-identity

# Confirm your default region is set correctly (e.g., us-east-1)
aws configure get region

# Baseline Check: View existing buckets to ensure CLI connectivity
aws s3 ls
```

---

## 🏗️ PART 1 — PROVISION THE SOURCE BUCKET

The Source Bucket acts as the primary data lake or application storage layer. By enabling Versioning at creation, we ensure that from day 1, no data can be accidentally permanently overwritten.

### Console Execution
1. Navigate to **S3** → **Create bucket**.
2. **Bucket name**: `s3-versioning-lab-yourname` (Bucket names must be globally unique across all AWS customers).
3. **Region**: `US East (N. Virginia) us-east-1`
4. **Object Ownership**: ACLs disabled (default). This is an AWS best practice ensuring the bucket owner retains full control of all objects regardless of who uploads them.
5. **Block Public Access**: Leave ALL blocks ON. This prevents any accidental data leaks to the internet.
6. **Bucket Versioning**: **Enable**. This is the critical setting for this lab.
7. **Encryption**: SSE-S3 (default). AWS automatically manages the encryption keys.
8. Click **Create bucket**.

---

## 🧪 PART 2 — THE VERSIONING WORKFLOW 

This phase demonstrates how Versioning protects you from catastrophic data loss.

1. **Upload the Initial Object (v1)**:
   Create a local `document.txt` and run:
   ```powershell
   aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt
   ```
2. **Simulate an Overwrite (v2)**:
   Modify the local `document.txt` with entirely new text and re-upload it. In a normal bucket, the old file is gone forever. With versioning, both exist.
   ```powershell
   aws s3api list-object-versions --bucket $SOURCE_BUCKET --prefix document.txt
   ```
   *Notice the JSON output. S3 maintains a `VersionId` for every iteration.*
3. **Execute Point-in-Time Recovery**:
   Find the older Version ID from the JSON list, and explicitly request that exact state in time:
   ```powershell
   aws s3api get-object --bucket $SOURCE_BUCKET --key document.txt --version-id <V1_ID> recovered-v1.txt
   ```
4. **Simulate Accidental Deletion**:
   Run a standard delete: `aws s3 rm s3://$SOURCE_BUCKET/document.txt`.
   The file appears gone. However, S3 merely stacked a **Delete Marker** on top of the file.
5. **Execute Undelete**:
   To bring the file back, you simply delete the Delete Marker!
   ```powershell
   aws s3api delete-object --bucket $SOURCE_BUCKET --key document.txt --version-id <DELETE_MARKER_ID>
   ```

---

## 📉 PART 3 — ARCHITECTING LIFECYCLE POLICIES

To prevent versioning from doubling or tripling your storage costs over time, we deploy an automated Lifecycle Policy. This policy dictates data tiering rules.

### Console Execution
1. Click your source bucket → **Management** tab → **Create lifecycle rule**.
2. **Lifecycle rule name**: `cost-optimization-policy`
3. **Rule scope**: Apply to all objects in the bucket.
4. **Lifecycle rule actions** (check ALL): 
   - Transition current versions...
   - Transition noncurrent versions...
   - Expire current versions...
   - Permanently delete noncurrent versions...
   - Delete expired object delete markers or incomplete multipart uploads
5. **Configure Tiering Logistics**:
   - **Current Versions:** Move to `Standard-IA` (30 days) → Move to `Glacier Flexible Retrieval` (90 days).
   - **Noncurrent Versions:** Move to `Standard-IA` (30 days) → Move to `Glacier Flexible Retrieval` (90 days).
   - **Expiration/Deletion:** Expire current versions at 365 days. Permanently delete noncurrent versions at 90 days.
   - **Hygiene:** Delete incomplete multipart uploads after 7 days (prevents paying for broken, half-uploaded large files).
6. Click **Create rule**.

---

## 🌍 PART 4 — CONFIGURING CROSS-REGION REPLICATION (CRR)

For Disaster Recovery (DR), we want every object in `us-east-1` to automatically replicate to a datacenter hundreds of miles away in `us-west-2`.

1. **Provision the Destination (DR) Bucket**:
   - Create `s3-versioning-lab-yourname-replica` in `US West (Oregon) us-west-2`.
   - **CRITICAL:** You *must* enable Bucket Versioning on the destination bucket, or replication will fail.
2. **Provision the IAM Service Role**:
   - Create an IAM role (e.g., `s3-replication-role`) that allows S3 to assume it.
   - Attach a policy granting `s3:ReplicateObject` on the destination, and `s3:GetObjectVersionForReplication` on the source.
3. **Deploy the Replication Rule**:
   - On the source bucket → **Management** tab → **Replication rules** → **Create replication rule**.
   - **Destination**: Choose the replica bucket in us-west-2.
   - **IAM role**: Select the replication role you just built.
   - **Delete marker replication**: Enable (ensures that if you soft-delete a file in Prod, it is soft-deleted in DR).
   - Click **Save**. *Choose NOT to replicate existing objects to save time and bandwidth.*

---

## 🔍 PART 5 — VALIDATE REPLICATION SLA

1. Upload a new test file (`crr-test.txt`) to the SOURCE bucket.
2. S3 Replication is asynchronous. Wait roughly 15-30 seconds.
3. Query the destination bucket in `us-west-2` to prove the AWS backbone successfully transferred the data.
   ```powershell
   aws s3api head-object --bucket $DEST_BUCKET --key crr-test.txt --region us-west-2
   ```
   *Look for `ReplicationStatus: REPLICA` in the metadata response. This proves the architecture is working perfectly.*

---

## 🧹 PART 6 — PROPER INFRASTRUCTURE TEARDOWN

To prevent recurring AWS charges, proceed to the `docs/cleanup-guide.md` to run the tear-down scripts. Versioned buckets require a specialized deletion loop to destroy underlying versions before the bucket can be removed.