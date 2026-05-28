## Project 4 — S3 Replication IAM Role

Role name: s3-replication-role
Trusted entity: s3.amazonaws.com
Purpose: Allows S3 to read from source bucket and
         write replicas to destination bucket automatically

### Permissions breakdown:

On SOURCE bucket:
- s3:GetReplicationConfiguration  → read the replication config
- s3:ListBucket                   → list objects to replicate
- s3:GetObjectVersionForReplication → read each object version
- s3:GetObjectVersionAcl          → read access control info
- s3:GetObjectVersionTagging      → read object tags

On DESTINATION bucket:
- s3:ReplicateObject              → write the replica
- s3:ReplicateDelete              → replicate delete markers
- s3:ReplicateTags                → copy object tags

### Why least privilege matters here:
The role has NO permission to delete the source,
NO permission to read other buckets,
NO permission to change bucket policies.
It can only do exactly what replication needs.

### Key concept — service trust policy:
"Principal": {"Service": "s3.amazonaws.com"}
This means S3 the service assumes this role — not a user.
Same pattern used for Lambda, EC2, CodeBuild roles.