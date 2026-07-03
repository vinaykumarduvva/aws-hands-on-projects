$SOURCE_BUCKET = "s3-versioning-lab-yourname"

# Create a working directory
mkdir C:\Users\$env:USERNAME\s3-versioning-lab -ErrorAction SilentlyContinue
cd C:\Users\$env:USERNAME\s3-versioning-lab

# Create version 1 of a test file
"This is version 1 of my important document.
Created: $(Get-Date)
Author: YourName" | Out-File -FilePath "document.txt" -Encoding utf8

# Upload version 1
aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt

# Overwrite with version 2
"This is version 2 - UPDATED content.
Updated: $(Get-Date)
Important changes made here." | Out-File -FilePath "document.txt" -Encoding utf8

aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt

# Upload version 3
"This is version 3 - FINAL content.
Finalized: $(Get-Date)
This is the current production version." | Out-File -FilePath "document.txt" -Encoding utf8

aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt

# Save all version IDs for later use
$VERSIONS = aws s3api list-object-versions `
  --bucket $SOURCE_BUCKET `
  --prefix document.txt | ConvertFrom-Json

$V1_ID = $VERSIONS.Versions[-1].VersionId  # oldest = version 1
$V2_ID = $VERSIONS.Versions[-2].VersionId  # middle = version 2
$V3_ID = $VERSIONS.Versions[0].VersionId   # newest = version 3

Write-Host "Version 1 ID: $V1_ID"
Write-Host "Version 2 ID: $V2_ID"
Write-Host "Version 3 ID: $V3_ID"

# Download version 1 specifically
aws s3api get-object `
  --bucket $SOURCE_BUCKET `
  --key document.txt `
  --version-id $V1_ID `
  recovered-v1.txt

Write-Host "Recovered version 1 content:"
cat recovered-v1.txt

# Delete the object
aws s3 rm s3://$SOURCE_BUCKET/document.txt

# Get the delete marker version ID
$DELETE_MARKER_ID = (aws s3api list-object-versions `
  --bucket $SOURCE_BUCKET `
  --prefix document.txt | ConvertFrom-Json).DeleteMarkers[0].VersionId

Write-Host "Delete marker ID: $DELETE_MARKER_ID"

# RECOVER — remove the delete marker to restore the file
aws s3api delete-object `
  --bucket $SOURCE_BUCKET `
  --key document.txt `
  --version-id $DELETE_MARKER_ID

# Now download it again — file is back
aws s3 cp s3://$SOURCE_BUCKET/document.txt recovered-from-delete.txt
Write-Host "Recovered after delete content:"
cat recovered-from-delete.txt
