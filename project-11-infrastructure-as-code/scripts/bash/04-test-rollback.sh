#!/bin/bash
# 04-test-rollback.sh

# Create a broken change set (invalid instance type)
aws cloudformation create-change-set \
  --stack-name my-app-stack \
  --change-set-name test-rollback \
  --template-body file://templates/main-stack.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=cfn-web-app \
    ParameterKey=EnvironmentType,ParameterValue=dev \
    ParameterKey=InstanceType,ParameterValue=invalid.type \
    ParameterKey=KeyPairName,ParameterValue=aws-ec2-keypair \
    ParameterKey=MinInstances,ParameterValue=2 \
    ParameterKey=MaxInstances,ParameterValue=6 \
    ParameterKey=DesiredInstances,ParameterValue=2 \
  --capabilities CAPABILITY_IAM
