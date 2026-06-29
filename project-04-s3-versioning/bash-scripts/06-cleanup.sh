#!/bin/bash

SOURCE_BUCKET="s3-versioning-lab-yourname"
DEST_BUCKET="s3-versioning-lab-yourname-replica"
SOURCE_REGION="ap-south-1"
DEST_REGION="ap-south-2"

ALL_VERSIONS=$(aws s3api list-object-versions \
  --bucket $SOURCE_BUCKET --output json)

versions=$(echo "$ALL_VERSIONS" | jq -r '.Versions[]? | "\(.Key)\t\(.VersionId)"')
if [ -n "$versions" ]; then
  echo "$versions" | while IFS=$'\t' read -r key versionId; do
    aws s3api delete-object \
      --bucket $SOURCE_BUCKET \
      --key "$key" \
      --version-id "$versionId" > /dev/null
  done
fi

markers=$(echo "$ALL_VERSIONS" | jq -r '.DeleteMarkers[]? | "\(.Key)\t\(.VersionId)"')
if [ -n "$markers" ]; then
  echo "$markers" | while IFS=$'\t' read -r key versionId; do
    aws s3api delete-object \
      --bucket $SOURCE_BUCKET \
      --key "$key" \
      --version-id "$versionId" > /dev/null
  done
fi

aws s3api delete-bucket --bucket $SOURCE_BUCKET --region $SOURCE_REGION 2>/dev/null || true

DEST_VERSIONS=$(aws s3api list-object-versions \
  --bucket $DEST_BUCKET --region $DEST_REGION --output json 2>/dev/null)

if [ -n "$DEST_VERSIONS" ]; then
  d_versions=$(echo "$DEST_VERSIONS" | jq -r '.Versions[]? | "\(.Key)\t\(.VersionId)"')
  if [ -n "$d_versions" ]; then
    echo "$d_versions" | while IFS=$'\t' read -r key versionId; do
      aws s3api delete-object \
        --bucket $DEST_BUCKET \
        --key "$key" \
        --version-id "$versionId" \
        --region $DEST_REGION > /dev/null
    done
  fi

  d_markers=$(echo "$DEST_VERSIONS" | jq -r '.DeleteMarkers[]? | "\(.Key)\t\(.VersionId)"')
  if [ -n "$d_markers" ]; then
    echo "$d_markers" | while IFS=$'\t' read -r key versionId; do
      aws s3api delete-object \
        --bucket $DEST_BUCKET \
        --key "$key" \
        --version-id "$versionId" \
        --region $DEST_REGION > /dev/null
    done
  fi
  aws s3api delete-bucket --bucket $DEST_BUCKET --region $DEST_REGION 2>/dev/null || true
fi

aws iam delete-role-policy \
  --role-name s3-replication-role \
  --policy-name s3-replication-permissions 2>/dev/null || true
aws iam delete-role --role-name s3-replication-role 2>/dev/null || true

echo -e "\e[32mProject 4 cleanup complete\e[0m"
