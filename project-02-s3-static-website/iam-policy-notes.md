## Project 2 — S3 Bucket Policy (Public Read)

Attached to: S3 bucket (aws-sample-webiste-2026)
Effect: Allows anyone on the internet to read objects from this bucket.
Use case: Static website hosting — needed so browsers can fetch HTML/CSS/JS.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::aws-sample-webiste-2026/*"
    }
  ]
}
```

### Key concepts from this policy:
- Principal: "*" means anyone — the entire internet
- Action: s3:GetObject means read-only — nobody can upload, delete, or list
- Resource: the /* at the end means every object inside the bucket
- This policy does NOT allow s3:ListBucket — so /index.html works
  but visiting the bucket root directly shows Access Denied (good)

### Production note:
In a real company you would NOT use Principal "*".
Instead you would use CloudFront Origin Access Control (OAC)
so only CloudFront can read S3 — direct S3 URLs would be blocked.
This is covered in the Mini Challenge 5 for Project 2.