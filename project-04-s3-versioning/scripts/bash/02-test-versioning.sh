#!/bin/bash
SOURCE_BUCKET="s3-versioning-lab-yourname"

# Create a working directory
mkdir -p ~/s3-versioning-lab
cd ~/s3-versioning-lab

# Create version 1 of a test file
cat << EOF > document.txt
This is version 1 of my important document.
Created: $(date)
Author: YourName
EOF

# Upload version 1
aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt

# Overwrite with version 2
cat << EOF > document.txt
This is version 2 - UPDATED content.
Updated: $(date)
Important changes made here.
EOF

aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt

# Upload version 3
cat << EOF > document.txt
This is version 3 - FINAL content.
Finalized: $(date)
This is the current production version.
EOF

aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt

# Save all version IDs for later use
VERSIONS=$(aws s3api list-object-versions --bucket $SOURCE_BUCKET --prefix document.txt)

V1_ID=$(echo "$VERSIONS" | jq -r '.Versions[-1].VersionId')  # oldest = version 1
V2_ID=$(echo "$VERSIONS" | jq -r '.Versions[-2].VersionId')  # middle = version 2
V3_ID=$(echo "$VERSIONS" | jq -r '.Versions[0].VersionId')   # newest = version 3

echo "Version 1 ID: $V1_ID"
echo "Version 2 ID: $V2_ID"
echo "Version 3 ID: $V3_ID"

# Download version 1 specifically
aws s3api get-object \
  --bucket $SOURCE_BUCKET \
  --key document.txt \
  --version-id $V1_ID \
  recovered-v1.txt

echo "Recovered version 1 content:"
cat recovered-v1.txt

# Delete the object
aws s3 rm s3://$SOURCE_BUCKET/document.txt

# Get the delete marker version ID
DELETE_MARKER_ID=$(aws s3api list-object-versions \
  --bucket $SOURCE_BUCKET \
  --prefix document.txt | jq -r '.DeleteMarkers[0].VersionId')

echo "Delete marker ID: $DELETE_MARKER_ID"

# RECOVER — remove the delete marker to restore the file
aws s3api delete-object \
  --bucket $SOURCE_BUCKET \
  --key document.txt \
  --version-id $DELETE_MARKER_ID

# Now download it again — file is back
aws s3 cp s3://$SOURCE_BUCKET/document.txt recovered-from-delete.txt
echo "Recovered after delete content:"
cat recovered-from-delete.txt
