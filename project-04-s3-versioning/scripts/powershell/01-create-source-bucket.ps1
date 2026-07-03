# Set variables
$SOURCE_BUCKET = "s3-versioning-lab-yourname"
$SOURCE_REGION = "us-east-1"

# Create source bucket
aws s3api create-bucket `
  --bucket $SOURCE_BUCKET `
  --region $SOURCE_REGION

# Enable versioning on source bucket
aws s3api put-bucket-versioning `
  --bucket $SOURCE_BUCKET `
  --versioning-configuration Status=Enabled

# Verify versioning is enabled
aws s3api get-bucket-versioning --bucket $SOURCE_BUCKET
