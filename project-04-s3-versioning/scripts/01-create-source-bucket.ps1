$SOURCE_BUCKET = "s3-versioning-lab-yourname"
$SOURCE_REGION = "ap-south-1"

aws s3api create-bucket `
  --bucket $SOURCE_BUCKET `
  --region $SOURCE_REGION `
  --create-bucket-configuration LocationConstraint=$SOURCE_REGION

aws s3api put-bucket-versioning `
  --bucket $SOURCE_BUCKET `
  --versioning-configuration Status=Enabled

$status = aws s3api get-bucket-versioning --bucket $SOURCE_BUCKET | ConvertFrom-Json
Write-Host -ForegroundColor Green "Created Source Bucket with Versioning: $($status.Status)"
