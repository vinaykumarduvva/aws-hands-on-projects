#!/bin/bash
# 05-detect-drift.sh

# Start drift detection
DRIFT_ID=$(aws cloudformation detect-stack-drift \
  --stack-name my-app-stack \
  --query "StackDriftDetectionId" --output text)

echo "Drift detection started: $DRIFT_ID"

# Wait a moment then check results
sleep 30

aws cloudformation describe-stack-drift-detection-status \
  --stack-drift-detection-id $DRIFT_ID \
  --query "{Status:DetectionStatus,DriftStatus:StackDriftStatus}" \
  --output table

# See which specific resources have drifted
aws cloudformation describe-stack-resource-drifts \
  --stack-name my-app-stack \
  --query "StackResourceDrifts[*].{
    Resource:LogicalResourceId,
    DriftStatus:StackResourceDriftStatus}" \
  --output table
