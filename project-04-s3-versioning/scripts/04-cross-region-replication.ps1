$SOURCE_BUCKET = "s3-versioning-lab-yourname"
$DEST_BUCKET   = "s3-versioning-lab-yourname-replica"
$DEST_REGION   = "ap-south-2"

aws s3api create-bucket `
  --bucket $DEST_BUCKET `
  --region $DEST_REGION `
  --create-bucket-configuration LocationConstraint=$DEST_REGION

aws s3api put-bucket-versioning `
  --bucket $DEST_BUCKET `
  --versioning-configuration Status=Enabled

aws iam create-role `
  --role-name s3-replication-role `
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "s3.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam put-role-policy `
  --role-name s3-replication-role `
  --policy-name s3-replication-permissions `
  --policy-document file://scripts/replication-policy.json

$ROLE_ARN = aws iam get-role `
  --role-name s3-replication-role `
  --query "Role.Arn" --output text

Start-Sleep -Seconds 10

aws s3api put-bucket-replication `
  --bucket $SOURCE_BUCKET `
  --replication-configuration "{
    `"Role`": `"$ROLE_ARN`",
    `"Rules`": [{
      `"ID`": `"replicate-to-ap-south-2`",
      `"Status`": `"Enabled`",
      `"Filter`": {`"Prefix`":`"`"},
      `"Destination`": {
        `"Bucket`": `"arn:aws:s3:::$DEST_BUCKET`",
        `"StorageClass`": `"STANDARD`"
      },
      `"DeleteMarkerReplication`": {
        `"Status`": `"Enabled`"
      }
    }]
  }"
  
Write-Host -ForegroundColor Green "Cross-Region Replication Setup Complete"
