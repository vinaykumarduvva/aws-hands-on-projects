# Architecture Details & System Design

This document outlines the high-level architecture and the underlying technical mechanisms utilized in this S3 Versioning and Replication project.

## 🏗️ System Overview & Data Flow

```mermaid
flowchart TD
    subgraph "Primary Region (e.g., us-east-1)"
        Client([Administrator / CLI])
        
        subgraph "Source Environment"
            SourceBucket[("Source Bucket\n(Versioning: ON)")]
            
            subgraph "Lifecycle Engine"
                Rule1(Day 30: Move to Standard-IA)
                Rule2(Day 90: Move to Glacier Flexible)
                Rule3(Day 365: Expire / Delete)
            end
        end
    end

    subgraph "Disaster Recovery Region (e.g., us-west-2)"
        subgraph "Destination Environment"
            DestBucket[("Destination / Replica Bucket\n(Versioning: ON)")]
        end
    end

    subgraph "AWS Identity & Access Management (IAM)"
        ReplRole{"S3 Replication Role\n(AssumeRole: s3.amazonaws.com)"}
    end

    Client -- "1. Uploads / Overwrites (PUT)" --> SourceBucket
    Client -- "2. Deletes Object (DELETE)" --> SourceBucket
    
    SourceBucket -. "Evaluates Age" .-> Lifecycle Engine
    
    SourceBucket -- "3. Asynchronous Copy via AWS Backbone" --> DestBucket
    ReplRole -. "Grants s3:ReplicateObject" .-> DestBucket
    ReplRole -. "Grants s3:GetObjectVersionForReplication" .-> SourceBucket
```

---

## 🧩 Architectural Components & Technical Deep Dive

### 1. Amazon S3 Versioning Mechanics
When versioning is enabled on a bucket, Amazon S3 automatically generates a unique `VersionId` for every object uploaded. 
- **Overwrites:** If you upload a file named `document.txt` multiple times, S3 does not replace the data blocks. Instead, it stacks them. The newest upload becomes the "Current" version (`IsLatest: true`), and previous uploads become "Noncurrent" versions.
- **Deletions:** If you issue a standard `DELETE` request, S3 does not destroy the file. It places a **Delete Marker** on top of the stack. The object appears deleted to standard `GET` requests (returning a 404), but administrators can retrieve the underlying data by deleting the Delete Marker or requesting a specific previous `VersionId`.

### 2. Cross-Region Replication (CRR) Engine
Replication in S3 is an asynchronous, background process. When an object is written to the Source Bucket, S3 queues a replication job.
- **Data Transfer:** The data travels securely across the private AWS global network backbone, never traversing the public internet.
- **Delete Marker Replication:** In this architecture, we specifically enable Delete Marker replication. If a user soft-deletes a file in the primary region, that soft-delete is mirrored to the DR region to ensure consistency.
- **Replication Status:** Objects in the source bucket will show a `ReplicationStatus` of `PENDING`, `COMPLETED`, or `FAILED`. Objects in the destination bucket will show `REPLICA`.

### 3. AWS IAM Replication Role
S3 cannot automatically read and write your data between buckets without explicit permission. We employ the **Principle of Least Privilege (PoLP)** by creating a dedicated IAM Role.
- **Trust Policy:** Allows the `s3.amazonaws.com` service principal to "Assume" the role.
- **Permission Policy:** Grants read access (`s3:GetObjectVersionForReplication`) strictly to the Source Bucket ARN, and write access (`s3:ReplicateObject`) strictly to the Destination Bucket ARN.

### 4. Automated Storage Tiering (Lifecycle Policies)
Lifecycle rules are XML/JSON configurations attached to the bucket that are evaluated daily by AWS.
- **Cost Optimization Loop:** In our architecture, after 30 days of inactivity, the object is moved to Standard-IA (cheaper storage, higher retrieval cost). At 90 days, it moves to Glacier (cold archive). At 365 days, it is permanently purged to prevent indefinite storage costs. 
- **Noncurrent Expiration:** Crucially, our architecture also dictates that old versions (Noncurrent versions) are permanently deleted after 90 days. This prevents version-stacking from bloating the AWS bill.