$SOURCE_BUCKET = "s3-versioning-lab-yourname"
$DEST_BUCKET   = "s3-versioning-lab-yourname-replica"
$DEST_REGION   = "ap-south-2"

"CRR Test - uploaded $(Get-Date)" | Out-File -FilePath "crr-test.txt" -Encoding utf8
aws s3 cp crr-test.txt s3://$SOURCE_BUCKET/crr-test.txt
Write-Host "Uploaded. Waiting 30 seconds for replication..."
Start-Sleep -Seconds 30

aws s3api head-object `
  --bucket $DEST_BUCKET `
  --key crr-test.txt `
  --region $DEST_REGION

aws s3 ls s3://$DEST_BUCKET --region $DEST_REGION

Write-Host -ForegroundColor Green "Test replication complete"
