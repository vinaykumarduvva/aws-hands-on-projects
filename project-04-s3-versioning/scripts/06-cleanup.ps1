$SOURCE_BUCKET = "s3-versioning-lab-yourname"
$DEST_BUCKET   = "s3-versioning-lab-yourname-replica"
$SOURCE_REGION = "ap-south-1"
$DEST_REGION   = "ap-south-2"

$ALL_VERSIONS = aws s3api list-object-versions `
  --bucket $SOURCE_BUCKET | ConvertFrom-Json

foreach ($v in $ALL_VERSIONS.Versions) {
  aws s3api delete-object `
    --bucket $SOURCE_BUCKET `
    --key $v.Key `
    --version-id $v.VersionId | Out-Null
}

foreach ($m in $ALL_VERSIONS.DeleteMarkers) {
  aws s3api delete-object `
    --bucket $SOURCE_BUCKET `
    --key $m.Key `
    --version-id $m.VersionId | Out-Null
}

aws s3api delete-bucket --bucket $SOURCE_BUCKET --region $SOURCE_REGION

$DEST_VERSIONS = aws s3api list-object-versions `
  --bucket $DEST_BUCKET --region $DEST_REGION | ConvertFrom-Json

foreach ($v in $DEST_VERSIONS.Versions) {
  aws s3api delete-object `
    --bucket $DEST_BUCKET `
    --key $v.Key `
    --version-id $v.VersionId `
    --region $DEST_REGION | Out-Null
}
foreach ($m in $DEST_VERSIONS.DeleteMarkers) {
  aws s3api delete-object `
    --bucket $DEST_BUCKET `
    --key $m.Key `
    --version-id $m.VersionId `
    --region $DEST_REGION | Out-Null
}

aws s3api delete-bucket --bucket $DEST_BUCKET --region $DEST_REGION

aws iam delete-role-policy `
  --role-name s3-replication-role `
  --policy-name s3-replication-permissions
aws iam delete-role --role-name s3-replication-role

Write-Host -ForegroundColor Green "Project 4 cleanup complete"
