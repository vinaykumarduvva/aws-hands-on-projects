## 🔐 Comprehensive S3 Replication IAM Role Breakdown

Cross-Region Replication (CRR) is an asynchronous background process entirely managed by AWS. However, the S3 service itself does not have inherent permission to move your data around. You must explicitly grant the S3 service the right to read from your source bucket and write to your destination bucket.

We achieve this by creating an **IAM Service Role**.

---

### 👤 The IAM Role: `s3-replication-role`

- **Role Name:** `s3-replication-role`
- **Purpose:** Provide the S3 replication engine with strictly scoped permissions to copy objects, tags, and delete markers between two specific buckets.

#### 1. The Trust Policy (AssumeRole)
```json
"Principal": {
  "Service": "s3.amazonaws.com"
}
```
This is a critical IAM concept. This policy dictates *who* or *what* is allowed to assume the role. By setting the principal to `s3.amazonaws.com`, we are stating that only the S3 backend service can utilize these permissions. No human user, EC2 instance, or Lambda function can assume this role.

#### 2. Source Bucket Permissions (Read-Only)
The role must be able to read the configuration and the data from the source bucket.
- **`s3:GetReplicationConfiguration`**: Allows S3 to read the rules you set up (e.g., which prefixes to replicate).
- **`s3:ListBucket`**: Allows S3 to see what objects exist in the bucket. *(Applied to the bucket ARN: `arn:aws:s3:::SOURCE`)*
- **`s3:GetObjectVersionForReplication`**: The most important permission. It allows S3 to read the actual data of a specific object version. *(Applied to the object ARN: `arn:aws:s3:::SOURCE/*`)*
- **`s3:GetObjectVersionAcl` & `s3:GetObjectVersionTagging`**: Ensures that metadata and tags are copied alongside the file.

#### 3. Destination Bucket Permissions (Write-Only)
The role must be able to write the data into the destination bucket.
- **`s3:ReplicateObject`**: The core permission allowing S3 to perform a cross-region `PUT` operation into the replica bucket.
- **`s3:ReplicateDelete`**: Crucial for our architecture. It allows S3 to replicate "Delete Markers" so that if a file is soft-deleted in Prod, it is also soft-deleted in DR.
- **`s3:ReplicateTags`**: Allows updating tags on the replicated object.
*(These permissions are applied strictly to the destination object ARN: `arn:aws:s3:::DESTINATION/*`)*

---

### 🛡️ The Principle of Least Privilege in Action

Notice what this role **cannot** do:
- It **cannot** delete data from the Source Bucket.
- It **cannot** read data from any other bucket in your AWS account.
- It **cannot** alter Bucket Policies or turn off Block Public Access.

If a malicious actor somehow managed to manipulate this role, the blast radius is contained entirely to the replication flow between these two specific buckets.
