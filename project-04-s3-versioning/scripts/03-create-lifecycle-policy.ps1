$SOURCE_BUCKET = "s3-versioning-lab-yourname"

aws s3api put-bucket-lifecycle-configuration `
  --bucket $SOURCE_BUCKET `
  --lifecycle-configuration file://scripts/lifecycle-policy.json

Write-Host -ForegroundColor Green "Applied lifecycle policy."
