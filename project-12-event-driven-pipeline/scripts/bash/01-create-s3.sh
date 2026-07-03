#!/bin/bash
# 01-create-s3.sh
source ./00-pre-flight.sh

aws s3api create-bucket \
  --bucket $SOURCE_BUCKET \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws s3api create-bucket \
  --bucket $OUTPUT_BUCKET \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws s3api put-bucket-versioning \
  --bucket $SOURCE_BUCKET \
  --versioning-configuration Status=Enabled

for BUCKET in $SOURCE_BUCKET $OUTPUT_BUCKET; do
  aws s3api put-public-access-block \
    --bucket $BUCKET \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  echo "Public access blocked: $BUCKET"
done

aws s3 ls | grep "event-pipeline"
