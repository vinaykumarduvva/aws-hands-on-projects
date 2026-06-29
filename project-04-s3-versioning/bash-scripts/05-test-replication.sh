#!/bin/bash

SOURCE_BUCKET="s3-versioning-lab-yourname"
DEST_BUCKET="s3-versioning-lab-yourname-replica"
DEST_REGION="ap-south-2"

echo "CRR Test - uploaded $(date)" > crr-test.txt
aws s3 cp crr-test.txt s3://$SOURCE_BUCKET/crr-test.txt
echo "Uploaded. Waiting 30 seconds for replication..."
sleep 30

aws s3api head-object \
  --bucket $DEST_BUCKET \
  --key crr-test.txt \
  --region $DEST_REGION

aws s3 ls s3://$DEST_BUCKET --region $DEST_REGION

echo -e "\e[32mTest replication complete\e[0m"
