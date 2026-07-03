#!/bin/bash
SOURCE_BUCKET="s3-versioning-lab-yourname"
DEST_BUCKET="s3-versioning-lab-yourname-replica"
DEST_REGION="us-west-2"

# Upload a new test file to SOURCE bucket
cat << EOF > crr-test.txt
CRR Test file - uploaded $(date)
This object should automatically replicate to us-west-2
EOF

aws s3 cp crr-test.txt s3://$SOURCE_BUCKET/crr-test.txt
echo "Uploaded to source bucket. Waiting 30 seconds for replication..."

# Wait for replication (usually 15-30 seconds for small objects)
sleep 30

# Check if the object exists in the DESTINATION bucket (us-west-2)
aws s3api head-object \
  --bucket $DEST_BUCKET \
  --key crr-test.txt \
  --region $DEST_REGION

# List objects in destination to confirm
aws s3 ls s3://$DEST_BUCKET --region $DEST_REGION

# Check replication status on source object
aws s3api head-object \
  --bucket $SOURCE_BUCKET \
  --key crr-test.txt

# Upload a second file and verify it also replicates
cat << EOF > crr-test-2.txt
Second CRR test - $(date)
EOF

aws s3 cp crr-test-2.txt s3://$SOURCE_BUCKET/crr-test-2.txt
sleep 30

aws s3 ls s3://$DEST_BUCKET --region $DEST_REGION
