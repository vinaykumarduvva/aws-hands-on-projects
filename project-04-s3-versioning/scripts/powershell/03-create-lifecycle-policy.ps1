$SOURCE_BUCKET = "s3-versioning-lab-yourname"

# Create the lifecycle policy JSON
$LIFECYCLE_POLICY = '{
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
}'

# Save to file
$LIFECYCLE_POLICY | Out-File -FilePath "lifecycle-policy.json" -Encoding utf8

# Apply the lifecycle policy
aws s3api put-bucket-lifecycle-configuration `
  --bucket $SOURCE_BUCKET `
  --lifecycle-configuration file://lifecycle-policy.json

# Verify the policy was applied
aws s3api get-bucket-lifecycle-configuration --bucket $SOURCE_BUCKET
