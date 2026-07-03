# Security Protocols & Compliance

Security is paramount when configuring Amazon S3, especially when dealing with data replication across geographic boundaries. This project strictly enforces AWS security best practices, aligning with the **AWS Well-Architected Framework (Security Pillar)**.

---

## 🔐 1. Identity and Access Management (IAM)

### The Principle of Least Privilege (PoLP)
In this project, Cross-Region Replication (CRR) relies on a dedicated IAM Service Role. Rather than granting S3 broad `s3:*` permissions, the IAM policy is highly restrictive:
- **Source Bucket Scope:** The role is only permitted to perform `s3:GetObjectVersionForReplication` and `s3:ListBucket` on `arn:aws:s3:::<SOURCE_BUCKET>/*`. It cannot read data from any other bucket in the AWS account.
- **Destination Bucket Scope:** The role is only permitted to perform `s3:ReplicateObject`, `s3:ReplicateDelete`, and `s3:ReplicateTags` on `arn:aws:s3:::<DEST_BUCKET>/*`. It cannot overwrite or modify data outside of this replica bucket.

### Trust Policies (Assume Role)
The IAM role utilizes a Trust Policy that explicitly restricts assumption of the role to the `s3.amazonaws.com` service principal. This ensures that no human user or EC2 instance can assume this role to bypass standard access controls.

---

## 🛡️ 2. Data Protection (At Rest and In Transit)

### Encryption In Transit
All data replicated between the `us-east-1` and `us-west-2` regions travels entirely over the AWS private global backbone infrastructure. All inter-region traffic is encrypted in transit using TLS 1.2+, ensuring protection against packet sniffing and man-in-the-middle (MITM) attacks.

### Encryption At Rest (SSE-S3)
By default, both the Source and Destination buckets are configured with **Server-Side Encryption with Amazon S3 managed keys (SSE-S3)**. 
- S3 encrypts each object with a unique key.
- It encrypts the key itself with a master key that it regularly rotates.
- It uses 256-bit Advanced Encryption Standard (AES-256) block cipher.

*(Note: For higher security workloads, SSE-KMS would be used, requiring the IAM Replication role to also have `kms:Decrypt` and `kms:Encrypt` permissions).*

---

## 🚧 3. S3 Block Public Access (BPA)
Misconfigured S3 buckets are a leading cause of enterprise data leaks. This project explicitly leaves **Block Public Access (BPA)** enabled at the bucket level.
This setting overrides any Object Access Control Lists (ACLs) or Bucket Policies that might accidentally grant `PublicRead` access, ensuring the DR and Source buckets remain completely isolated from the internet.

---

## ♻️ 4. Ransomware & Accidental Deletion Protection
**Bucket Versioning** serves as a rudimentary defense against ransomware and malicious insider threats.
- If a malicious actor (or a buggy script) encrypts or overwrites an object, the original, unencrypted version is preserved as a "Noncurrent" version.
- If an attacker issues a `DELETE` API call, S3 merely places a Delete Marker on the object. The data is not destroyed unless the attacker specifically iterates through and deletes specific `VersionId`s.

> [!TIP]
> **Enterprise Upgrade (Object Lock):** For true immutable storage (WORM - Write Once, Read Many), organizations pair Versioning with **S3 Object Lock**. Object Lock prevents ANY user, even the AWS Root Account, from deleting a version of a file until a specified retention period expires.