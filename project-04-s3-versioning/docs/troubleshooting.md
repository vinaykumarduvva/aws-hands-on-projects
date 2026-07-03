# Comprehensive Troubleshooting Guide

Cloud engineering requires robust debugging skills. Below is an exhaustive list of common failure states encountered when configuring advanced S3 features like Versioning and Replication, along with their root causes and remediation steps.

---

## 🪣 Bucket Provisioning Errors

| Symptom / Error | Root Cause Analysis | Remediation Steps |
|:----------------|:--------------------|:------------------|
| **`BucketAlreadyExists` or `BucketAlreadyOwnedByYou`** | S3 bucket names share a single, global namespace across all AWS customers. The name you chose is taken by someone else in the world. | Append a random string of numbers, your initials, or a timestamp to the end of the bucket name (e.g., `s3-versioning-lab-jd-20240501`). |
| **`InvalidLocationConstraint`** | You attempted to create a bucket in a region using a CLI command without specifying the proper `--create-bucket-configuration` payload. | When creating a bucket in any region *other* than `us-east-1` via CLI, you must explicitly pass the LocationConstraint parameter matching the region. |

---

## 🔄 Versioning & Lifecycle Issues

| Symptom / Error | Root Cause Analysis | Remediation Steps |
|:----------------|:--------------------|:------------------|
| **Cannot delete a bucket (`BucketNotEmpty`)** | The bucket has versioning enabled. Standard deletion only places a Delete Marker on top of the objects; the historical versions still exist underneath and are blocking bucket deletion. | You must script a loop that explicitly runs `delete-object` against every individual `VersionId` and every `DeleteMarker` ID before deleting the bucket. See `cleanup-guide.md`. |
| **Lifecycle rules aren't running immediately** | S3 Lifecycle policies are evaluated as a batch job asynchronously, usually once per day at Midnight UTC. | There is no "Run Now" button for lifecycle policies. You must simply wait up to 48 hours for the rules to process the objects. You can validate the rules are applied correctly via `aws s3api get-bucket-lifecycle-configuration`. |

---

## 🔀 Cross-Region Replication (CRR) Failures

| Symptom / Error | Root Cause Analysis | Remediation Steps |
|:----------------|:--------------------|:------------------|
| **ReplicationStatus: `FAILED`** | The IAM Service Role attached to the replication rule does not have the correct permissions. The trust policy might be wrong, or the ARNs in the permission policy might have typos. | 1. Ensure Trust Policy allows `s3.amazonaws.com`. <br> 2. Ensure Permission Policy explicitly lists `arn:aws:s3:::<SOURCE>/*` and `arn:aws:s3:::<DEST>/*`. <br> 3. Delete the replication rule and recreate it with the fixed Role. |
| **ReplicationStatus is missing entirely** | 1. The object was uploaded *before* the replication rule was created. <br> 2. Versioning is not enabled on the destination bucket. | 1. Upload a brand new object to trigger the replication engine. <br> 2. Go to the destination bucket properties and ensure Versioning is explicitly Enabled. |
| **Delete Markers aren't replicating** | By default, S3 CRR does not replicate delete markers to prevent accidental cross-region data purges. | Edit the Replication Rule in the S3 console and explicitly check the box for "Replicate Delete Markers". |
| **Encrypted Objects aren't replicating** | If you are using custom KMS keys (SSE-KMS) instead of SSE-S3, the replication role must have explicit permission to Decrypt the source and Encrypt the destination. | Update the IAM Role to include `kms:Decrypt` for the source region key, and `kms:GenerateDataKey` / `kms:Encrypt` for the destination region key. |