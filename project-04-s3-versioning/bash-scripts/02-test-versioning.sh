#!/bin/bash

SOURCE_BUCKET="s3-versioning-lab-yourname"

echo "Version 1 - original content. Created: $(date)" > document.txt
aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt

echo "Version 2 - updated content. Updated: $(date)" > document.txt
aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt

echo "Version 3 - final content. Finalized: $(date)" > document.txt
aws s3 cp document.txt s3://$SOURCE_BUCKET/document.txt

aws s3api list-object-versions \
  --bucket $SOURCE_BUCKET --prefix document.txt \
  --query "Versions[*].{VersionId:VersionId,IsLatest:IsLatest}" \
  --output table

echo -e "\e[32mVersioning tested. Three versions uploaded.\e[0m"
