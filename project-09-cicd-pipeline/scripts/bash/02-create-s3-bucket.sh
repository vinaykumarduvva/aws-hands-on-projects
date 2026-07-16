#!/bin/bash

# =============================================================================
# Project 9 — Script 02: Create S3 Artifact Bucket
# CodePipeline stores build artifacts between stages in this bucket
# Region: ap-south-1
# =============================================================================

echo -e "\e[36m=== Project 9 — Create S3 Artifact Bucket ===\e[0m"
echo ""

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
ARTIFACT_BUCKET="codepipeline-artifacts-$ACCOUNT_ID-ap-south-1"

echo -e "\e[33mBucket name: $ARTIFACT_BUCKET\e[0m"

# ── CREATE BUCKET ─────────────────────────────────────────────────────────────
echo -e "\e[33m[1/3] Creating bucket...\e[0m"
aws s3api create-bucket \
    --bucket $ARTIFACT_BUCKET \
    --region ap-south-1 \
    --create-bucket-configuration LocationConstraint=ap-south-1

echo -e "\e[32mBucket created.\e[0m"

# ── ENABLE VERSIONING ─────────────────────────────────────────────────────────
echo -e "\e[33m[2/3] Enabling versioning (required by CodePipeline)...\e[0m"
aws s3api put-bucket-versioning \
    --bucket $ARTIFACT_BUCKET \
    --versioning-configuration Status=Enabled
echo -e "\e[32mVersioning enabled.\e[0m"

# ── BLOCK PUBLIC ACCESS ───────────────────────────────────────────────────────
echo -e "\e[33m[3/3] Blocking all public access...\e[0m"
aws s3api put-public-access-block \
    --bucket $ARTIFACT_BUCKET \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo -e "\e[32mPublic access blocked.\e[0m"

# ── VERIFY ────────────────────────────────────────────────────────────────────
aws s3api get-bucket-versioning --bucket $ARTIFACT_BUCKET --query "Status" --output text

echo ""
echo -e "\e[36m=== S3 Bucket Complete ===\e[0m"
echo "  ARTIFACT_BUCKET = $ARTIFACT_BUCKET"
echo ""
echo -e "\e[36mNext step: Run 03-create-codecommit.sh\e[0m"