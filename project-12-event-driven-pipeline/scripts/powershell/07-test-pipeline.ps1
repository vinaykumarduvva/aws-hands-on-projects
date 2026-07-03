. .\00-pre-flight.ps1

# Create test CSV file
$CSV_CONTENT = @"
id,name,department,salary,age
1,Vinay Kumar,Engineering,85000,28
2,AWS Engineer,DevOps,92000,31
3,Cloud Learner,Architecture,78000,26
"@
$CSV_CONTENT | Out-File -FilePath "test-employees.csv" -Encoding utf8

# Create test JSON file
$JSON_CONTENT = @"
[
  {"orderId": "ORD-001", "product": "AWS Course", "price": 199.99},
  {"orderId": "ORD-002", "product": "Cloud Book", "price": 49.99}
]
"@
$JSON_CONTENT | Out-File -FilePath "test-orders.json" -Encoding utf8

# Upload CSV — triggers pipeline
aws s3 cp test-employees.csv s3://$SOURCE_BUCKET/uploads/test-employees.csv
Write-Host "CSV uploaded — pipeline triggered"
Start-Sleep -Seconds 5

# Upload JSON — triggers pipeline
aws s3 cp test-orders.json s3://$SOURCE_BUCKET/uploads/test-orders.json
Write-Host "JSON uploaded — pipeline triggered"

Write-Host "Waiting for processing..."
Start-Sleep -Seconds 15

# Check output bucket for results
aws s3 ls s3://$OUTPUT_BUCKET/processed/ --recursive

# Cleanup local test files
Remove-Item test-employees.csv, test-orders.json -Force
