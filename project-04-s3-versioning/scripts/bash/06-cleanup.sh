#!/bin/bash
SOURCE_BUCKET="s3-versioning-lab-yourname"
DEST_BUCKET="s3-versioning-lab-yourname-replica"
SOURCE_REGION="us-east-1"
DEST_REGION="us-west-2"

# Step 1 — Delete all versions from source bucket
echo "Deleting all versions from source bucket..."

ALL_VERSIONS=$(aws s3api list-object-versions --bucket $SOURCE_BUCKET)

if [ -n "$ALL_VERSIONS" ] && [ "$ALL_VERSIONS" != "null" ]; then
  # Delete all versions
  VERSIONS=$(echo "$ALL_VERSIONS" | jq -c '.Versions[]? | {Key: .Key, VersionId: .VersionId}')
  for v in $VERSIONS; do
    KEY=$(echo $v | jq -r .Key)
    VID=$(echo $v | jq -r .VersionId)
    aws s3api delete-object --bucket $SOURCE_BUCKET --key "$KEY" --version-id "$VID" >/dev/null
  done

  # Delete all delete markers
  MARKERS=$(echo "$ALL_VERSIONS" | jq -c '.DeleteMarkers[]? | {Key: .Key, VersionId: .VersionId}')
  for m in $MARKERS; do
    KEY=$(echo $m | jq -r .Key)
    VID=$(echo $m | jq -r .VersionId)
    aws s3api delete-object --bucket $SOURCE_BUCKET --key "$KEY" --version-id "$VID" >/dev/null
  done
fi

echo "All versions deleted from source bucket"

# Step 2 — Delete source bucket
aws s3api delete-bucket --bucket $SOURCE_BUCKET --region $SOURCE_REGION
echo "Source bucket deleted"

# Step 3 — Empty and delete destination bucket
echo "Deleting destination bucket..."
aws s3 rm s3://$DEST_BUCKET --recursive --region $DEST_REGION

DEST_VERSIONS=$(aws s3api list-object-versions --bucket $DEST_BUCKET --region $DEST_REGION)

if [ -n "$DEST_VERSIONS" ] && [ "$DEST_VERSIONS" != "null" ]; then
  VERSIONS=$(echo "$DEST_VERSIONS" | jq -c '.Versions[]? | {Key: .Key, VersionId: .VersionId}')
  for v in $VERSIONS; do
    KEY=$(echo $v | jq -r .Key)
    VID=$(echo $v | jq -r .VersionId)
    aws s3api delete-object --bucket $DEST_BUCKET --key "$KEY" --version-id "$VID" --region $DEST_REGION >/dev/null
  done

  MARKERS=$(echo "$DEST_VERSIONS" | jq -c '.DeleteMarkers[]? | {Key: .Key, VersionId: .VersionId}')
  for m in $MARKERS; do
    KEY=$(echo $m | jq -r .Key)
    VID=$(echo $m | jq -r .VersionId)
    aws s3api delete-object --bucket $DEST_BUCKET --key "$KEY" --version-id "$VID" --region $DEST_REGION >/dev/null
  done
fi

aws s3api delete-bucket --bucket $DEST_BUCKET --region $DEST_REGION
echo "Destination bucket deleted"

# Step 4 — Delete IAM replication role
aws iam delete-role-policy \
  --role-name s3-replication-role \
  --policy-name s3-replication-permissions 2>/dev/null || true

aws iam delete-role --role-name s3-replication-role 2>/dev/null || true
echo "IAM replication role deleted"

# Step 5 — Verify everything is gone
aws s3 ls | grep "versioning-lab"
