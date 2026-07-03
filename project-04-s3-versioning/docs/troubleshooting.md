# Troubleshooting Manual

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