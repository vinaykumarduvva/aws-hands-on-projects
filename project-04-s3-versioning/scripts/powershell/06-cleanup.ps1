$SOURCE_BUCKET = "s3-versioning-lab-yourname"
$DEST_BUCKET   = "s3-versioning-lab-yourname-replica"
$SOURCE_REGION = "us-east-1"
$DEST_REGION   = "us-west-2"

# Step 1 — Delete all versions from source bucket
Write-Host "Deleting all versions from source bucket..."

$ALL_VERSIONS = aws s3api list-object-versions `
  --bucket $SOURCE_BUCKET | ConvertFrom-Json

if ($ALL_VERSIONS.Versions) {
  foreach ($version in $ALL_VERSIONS.Versions) {
    aws s3api delete-object `
      --bucket $SOURCE_BUCKET `
      --key $version.Key `
      --version-id $version.VersionId | Out-Null
  }
}

if ($ALL_VERSIONS.DeleteMarkers) {
  foreach ($marker in $ALL_VERSIONS.DeleteMarkers) {
    aws s3api delete-object `
      --bucket $SOURCE_BUCKET `
      --key $marker.Key `
      --version-id $marker.VersionId | Out-Null
  }
}

Write-Host "All versions deleted from source bucket"

# Step 2 — Delete source bucket
aws s3api delete-bucket --bucket $SOURCE_BUCKET --region $SOURCE_REGION
Write-Host "Source bucket deleted"

# Step 3 — Empty and delete destination bucket
Write-Host "Deleting destination bucket..."
aws s3 rm s3://$DEST_BUCKET --recursive --region $DEST_REGION

$DEST_VERSIONS = aws s3api list-object-versions `
  --bucket $DEST_BUCKET --region $DEST_REGION | ConvertFrom-Json

if ($DEST_VERSIONS.Versions) {
  foreach ($version in $DEST_VERSIONS.Versions) {
    aws s3api delete-object `
      --bucket $DEST_BUCKET `
      --key $version.Key `
      --version-id $version.VersionId `
      --region $DEST_REGION | Out-Null
  }
}

if ($DEST_VERSIONS.DeleteMarkers) {
  foreach ($marker in $DEST_VERSIONS.DeleteMarkers) {
    aws s3api delete-object `
      --bucket $DEST_BUCKET `
      --key $marker.Key `
      --version-id $marker.VersionId `
      --region $DEST_REGION | Out-Null
  }
}

aws s3api delete-bucket --bucket $DEST_BUCKET --region $DEST_REGION
Write-Host "Destination bucket deleted"

# Step 4 — Delete IAM replication role
aws iam delete-role-policy `
  --role-name s3-replication-role `
  --policy-name s3-replication-permissions -ErrorAction SilentlyContinue

aws iam delete-role --role-name s3-replication-role -ErrorAction SilentlyContinue
Write-Host "IAM replication role deleted"

# Step 5 — Verify everything is gone
aws s3 ls | Select-String "versioning-lab"
