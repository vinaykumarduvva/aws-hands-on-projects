. .\00-pre-flight.ps1

# Create source bucket
aws s3api create-bucket `
  --bucket $SOURCE_BUCKET `
  --region ap-south-1 `
  --create-bucket-configuration LocationConstraint=ap-south-1

# Create output bucket
aws s3api create-bucket `
  --bucket $OUTPUT_BUCKET `
  --region ap-south-1 `
  --create-bucket-configuration LocationConstraint=ap-south-1

# Enable versioning on source bucket
aws s3api put-bucket-versioning `
  --bucket $SOURCE_BUCKET `
  --versioning-configuration Status=Enabled

# Block all public access on both buckets
foreach ($BUCKET in @($SOURCE_BUCKET, $OUTPUT_BUCKET)) {
  aws s3api put-public-access-block `
    --bucket $BUCKET `
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  Write-Host "Public access blocked: $BUCKET"
}

# Verify both buckets exist
aws s3 ls | Select-String "event-pipeline"
