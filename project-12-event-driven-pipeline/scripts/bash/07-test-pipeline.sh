#!/bin/bash
# 07-test-pipeline.sh
source ./00-pre-flight.sh

cat << 'EOF' > test-employees.csv
id,name,department,salary,age
1,Vinay Kumar,Engineering,85000,28
2,AWS Engineer,DevOps,92000,31
3,Cloud Learner,Architecture,78000,26
EOF

cat << 'EOF' > test-orders.json
[
  {"orderId": "ORD-001", "product": "AWS Course", "price": 199.99},
  {"orderId": "ORD-002", "product": "Cloud Book", "price": 49.99}
]
EOF

aws s3 cp test-employees.csv s3://$SOURCE_BUCKET/uploads/test-employees.csv
echo "CSV uploaded — pipeline triggered"
sleep 5

aws s3 cp test-orders.json s3://$SOURCE_BUCKET/uploads/test-orders.json
echo "JSON uploaded — pipeline triggered"

echo "Waiting for processing..."
sleep 15

aws s3 ls s3://$OUTPUT_BUCKET/processed/ --recursive

rm test-employees.csv test-orders.json
