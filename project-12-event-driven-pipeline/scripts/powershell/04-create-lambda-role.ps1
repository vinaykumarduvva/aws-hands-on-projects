. .\00-pre-flight.ps1

# Create Lambda execution role
aws iam create-role `
  --role-name $LAMBDA_ROLE `
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach basic execution (CloudWatch Logs)
aws iam attach-role-policy `
  --role-name $LAMBDA_ROLE `
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Attach SQS access
aws iam attach-role-policy `
  --role-name $LAMBDA_ROLE `
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole

# Add S3 access inline policy
aws iam put-role-policy `
  --role-name $LAMBDA_ROLE `
  --policy-name s3-pipeline-access `
  --policy-document "{
    `"Version`":`"2012-10-17`",
    `"Statement`":[
      {
        `"Sid`":`"ReadSourceBucket`",
        `"Effect`":`"Allow`",
        `"Action`":[`"s3:GetObject`", `"s3:GetObjectVersion`", `"s3:HeadObject`"],
        `"Resource`":`"arn:aws:s3:::$SOURCE_BUCKET/*`"
      },
      {
        `"Sid`":`"WriteOutputBucket`",
        `"Effect`":`"Allow`",
        `"Action`":[`"s3:PutObject`", `"s3:PutObjectTagging`"],
        `"Resource`":`"arn:aws:s3:::$OUTPUT_BUCKET/*`"
      }
    ]
  }"

$LAMBDA_ROLE_ARN = aws iam get-role --role-name $LAMBDA_ROLE --query "Role.Arn" --output text
Write-Host "Lambda role ARN: $LAMBDA_ROLE_ARN"
Start-Sleep -Seconds 10
