#!/bin/bash
# 02-create-changeset.sh

# Create a change set (does NOT apply changes yet)
aws cloudformation create-change-set \
  --stack-name my-app-stack \
  --change-set-name increase-max-capacity \
  --template-body file://templates/main-stack.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=cfn-web-app \
    ParameterKey=EnvironmentType,ParameterValue=dev \
    ParameterKey=InstanceType,ParameterValue=t2.micro \
    ParameterKey=KeyPairName,ParameterValue=aws-ec2-keypair \
    ParameterKey=MinInstances,ParameterValue=2 \
    ParameterKey=MaxInstances,ParameterValue=6 \
    ParameterKey=DesiredInstances,ParameterValue=2 \
  --capabilities CAPABILITY_IAM

# Wait for change set to be ready
aws cloudformation wait change-set-create-complete \
  --stack-name my-app-stack \
  --change-set-name increase-max-capacity

# Preview exactly what will change
aws cloudformation describe-change-set \
  --stack-name my-app-stack \
  --change-set-name increase-max-capacity \
  --query "Changes[*].ResourceChange.{Action:Action,Resource:LogicalResourceId,Replacement:Replacement}" \
  --output table
