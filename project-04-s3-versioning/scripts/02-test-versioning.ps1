$SOURCE_BUCKET = "s3-versioning-lab-yourname"
"Version 1 - original content. Created: $(Get-Date)" | Out-File -FilePath "document.txt" -Encoding utf8
aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt
"Version 2 - updated content. Updated: $(Get-Date)" | Out-File -FilePath "document.txt" -Encoding utf8
aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt
"Version 3 - final content. Finalized: $(Get-Date)" | Out-File -FilePath "document.txt" -Encoding utf8
aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt

aws s3api list-object-versions `
  --bucket $SOURCE_BUCKET --prefix document.txt `
  --query "Versions[*].{VersionId:VersionId,IsLatest:IsLatest}" `
  --output table

Write-Host -ForegroundColor Green "Versioning tested. Three versions uploaded."
