# Comprehensive Cleanup Guide

Failing to properly clean up resources in AWS is the #1 cause of unexpected charges. For this project, cleanup is unusually complex because S3 has built-in protections against deleting data. 

**Core Concept:** Amazon S3 will categorically block the deletion of a bucket if there is *even a single object or delete marker remaining inside it.* Because Versioning is enabled, simply selecting all objects in the console and clicking "Delete" is not enough. You must delete every single underlying version ID.

---

## 🛑 The "Bucket Not Empty" Error
If you attempt to run `aws s3api delete-bucket` on a versioned bucket without emptying it first, you will receive a `BucketNotEmpty` error. 

To solve this, we must perform a programmatic teardown. The scripts provided in `scripts/bash/06-cleanup.sh` and `scripts/powershell/06-cleanup.ps1` handle this automatically by:
1. Querying S3 for a master JSON list of all Object Versions.
2. Querying S3 for a master JSON list of all Delete Markers.
3. Looping through the array and executing a permanent `delete-object` command against every specific `VersionId`.
4. Repeating this process for both the Source and Destination buckets.

---

## 🧹 Step-by-Step Manual Teardown Logic

If you wish to understand what the automated script is doing under the hood, here is the manual methodology:

### Step 1: Liquidate the Source Bucket
First, generate the manifest of everything in the bucket.
```powershell
aws s3api list-object-versions --bucket <SOURCE_BUCKET_NAME>
```
For every item in the `Versions` array, issue a permanent delete:
```powershell
aws s3api delete-object --bucket <SOURCE_BUCKET_NAME> --key <FILENAME> --version-id <VERSION_ID_HERE>
```
For every item in the `DeleteMarkers` array, issue a permanent delete:
```powershell
aws s3api delete-object --bucket <SOURCE_BUCKET_NAME> --key <FILENAME> --version-id <DELETE_MARKER_ID_HERE>
```
Once empty, destroy the bucket:
```powershell
aws s3api delete-bucket --bucket <SOURCE_BUCKET_NAME> --region us-east-1
```

### Step 2: Liquidate the Destination (Replica) Bucket
You must repeat the exact same process for the replica bucket located in `us-west-2`. The replication engine does not automatically delete versions in the destination bucket just because you deleted them in the source. This is a deliberate design choice by AWS to protect against malicious mass-deletions.

### Step 3: Dismantle the IAM Infrastructure
Do not leave orphaned IAM roles in your account. The Replication Role we created has powerful permissions. 

First, detach the inline policy:
```powershell
aws iam delete-role-policy --role-name s3-replication-role --policy-name s3-replication-permissions
```
Then, delete the empty role itself:
```powershell
aws iam delete-role --role-name s3-replication-role
```

---

## ✅ Final Verification
Run the following command to list all buckets in your account. If the teardown was successful, your `s3-versioning-lab` buckets should not appear in the output.
```powershell
aws s3 ls
```