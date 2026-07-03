#!/bin/bash
SOURCE_BUCKET="s3-versioning-lab-yourname"
DEST_BUCKET="s3-versioning-lab-yourname-replica"
DEST_REGION="us-west-2"

# Create destination bucket in us-west-2
aws s3api create-bucket \
  --bucket $DEST_BUCKET \
  --region $DEST_REGION \
  --create-bucket-configuration LocationConstraint=$DEST_REGION

# Enable versioning on destination (required for CRR)
aws s3api put-bucket-versioning \
  --bucket $DEST_BUCKET \
  --versioning-configuration Status=Enabled

# Verify
aws s3api get-bucket-versioning --bucket $DEST_BUCKET

# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity \
  --query "Account" --output text)

echo "Account ID: $ACCOUNT_ID"

# Create the replication IAM role
aws iam create-role \
  --role-name s3-replication-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  }'

# Create replication permissions policy
cat << EOF > replication-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::$SOURCE_BUCKET"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging"
      ],
      "Resource": "arn:aws:s3:::$SOURCE_BUCKET/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Resource": "arn:aws:s3:::$DEST_BUCKET/*"
    }
  ]
}
EOF

# Create and attach the policy to the role
aws iam put-role-policy \
  --role-name s3-replication-role \
  --policy-name s3-replication-permissions \
  --policy-document file://replication-policy.json

echo "Replication IAM role created and policy attached"

# Get the role ARN
ROLE_ARN=$(aws iam get-role \
  --role-name s3-replication-role \
  --query "Role.Arn" --output text)

echo "Role ARN: $ROLE_ARN"

# Enable replication on source bucket
aws s3api put-bucket-replication \
  --bucket $SOURCE_BUCKET \
  --replication-configuration "{
    \"Role\": \"$ROLE_ARN\",
    \"Rules\": [{
      \"ID\": \"replicate-to-us-west-2\",
      \"Status\": \"Enabled\",
      \"Filter\": {\"Prefix\":\"\"},
      \"Destination\": {
        \"Bucket\": \"arn:aws:s3:::$DEST_BUCKET\",
        \"StorageClass\": \"STANDARD\"
      },
      \"DeleteMarkerReplication\": {
        \"Status\": \"Enabled\"
      }
    }]
  }"

# Verify replication configuration
aws s3api get-bucket-replication --bucket $SOURCE_BUCKET
