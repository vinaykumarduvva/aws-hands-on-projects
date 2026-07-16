# Deployment Guide: Event-Driven Pipeline

This guide details the complete process for deploying the S3 → SQS → Lambda pipeline.

## 🏗️ PART 1 — PRE-FLIGHT CHECKS

### 🖥️ Method 1: AWS Management Console
1. Navigate to the top right corner of the AWS Management Console.
2. Verify that you are operating in the **ap-south-1 (Mumbai)** region.
3. Note your AWS Account ID (the 12-digit number) for use in naming globally unique resources.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# 00-pre-flight.sh

export REGION=$(aws configure get region)
export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

echo "Region: $REGION"
echo "Account ID: $ACCOUNT_ID"

export SOURCE_BUCKET="event-pipeline-source-$ACCOUNT_ID"
export OUTPUT_BUCKET="event-pipeline-output-$ACCOUNT_ID"
export QUEUE_NAME="file-processing-queue"
export DLQ_NAME="file-processing-dlq"
export LAMBDA_NAME="file-processor"
export LAMBDA_ROLE="lambda-file-processor-role"

echo "Source bucket:  $SOURCE_BUCKET"
echo "Output bucket:  $OUTPUT_BUCKET"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Confirm region ap-south-1
aws configure get region

# Get account ID
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
Write-Host "Account ID: $ACCOUNT_ID"

# Set bucket names (must be globally unique)
$SOURCE_BUCKET  = "event-pipeline-source-$ACCOUNT_ID"
$OUTPUT_BUCKET  = "event-pipeline-output-$ACCOUNT_ID"
$QUEUE_NAME     = "file-processing-queue"
$DLQ_NAME       = "file-processing-dlq"
$LAMBDA_NAME    = "file-processor"
$LAMBDA_ROLE    = "lambda-file-processor-role"

Write-Host "Source bucket:  $SOURCE_BUCKET"
Write-Host "Output bucket:  $OUTPUT_BUCKET"
```

## 🏗️ PART 2 — CREATE S3 BUCKETS

### 🖥️ Method 1: AWS Management Console
1. Navigate to the **S3 Console**.
2. Click **Create bucket**. Name it `event-pipeline-source-[YOUR-ACCOUNT-ID]`.
3. Choose Region: **ap-south-1**.
4. Enable **Bucket Versioning**.
5. Ensure **Block all public access** is checked. Click **Create bucket**.
6. Repeat the steps to create a second bucket named `event-pipeline-output-[YOUR-ACCOUNT-ID]`.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# 01-create-s3.sh
source ./00-pre-flight.sh

aws s3api create-bucket \
  --bucket $SOURCE_BUCKET \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws s3api create-bucket \
  --bucket $OUTPUT_BUCKET \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws s3api put-bucket-versioning \
  --bucket $SOURCE_BUCKET \
  --versioning-configuration Status=Enabled

for BUCKET in $SOURCE_BUCKET $OUTPUT_BUCKET; do
  aws s3api put-public-access-block \
    --bucket $BUCKET \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  echo "Public access blocked: $BUCKET"
done

aws s3 ls | grep "event-pipeline"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
. .\00-pre-flight.ps1

# Create source bucket
aws s3api create-bucket `
  --bucket $SOURCE_BUCKET `
  --region ap-south-1 `
  --create-bucket-configuration LocationConstraint=ap-south-1

# Create output bucket
aws s3api create-bucket `
  --bucket $OUTPUT_BUCKET `
  --region ap-south-1 `
  --create-bucket-configuration LocationConstraint=ap-south-1

# Enable versioning on source bucket
aws s3api put-bucket-versioning `
  --bucket $SOURCE_BUCKET `
  --versioning-configuration Status=Enabled

# Block all public access on both buckets
foreach ($BUCKET in @($SOURCE_BUCKET, $OUTPUT_BUCKET)) {
  aws s3api put-public-access-block `
    --bucket $BUCKET `
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  Write-Host "Public access blocked: $BUCKET"
}

# Verify both buckets exist
aws s3 ls | Select-String "event-pipeline"
```

## 🏗️ PART 3 — CREATE SQS QUEUES

### 🖥️ Method 1: AWS Management Console
1. Navigate to the **SQS Console**. Click **Create queue**.
2. Create the Dead Letter Queue first: Type: **Standard**, Name: `file-processing-dlq`, Message retention: **14 days**. Click **Create**.
3. Create the main processing queue: Type: **Standard**, Name: `file-processing-queue`, Visibility timeout: **60 seconds**.
4. Dead-letter queue: **Enabled**. Choose `file-processing-dlq` and set Maximum receives to **3**. Click **Create**.
5. Select `file-processing-queue`, go to **Access policy**, click **Edit**.
6. Add a statement allowing `s3.amazonaws.com` to `sqs:SendMessage` if `aws:SourceArn` matches your source S3 bucket ARN.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# 02-create-sqs.sh
source ./00-pre-flight.sh

export DLQ_URL=$(aws sqs create-queue \
  --queue-name $DLQ_NAME \
  --attributes '{"MessageRetentionPeriod": "1209600", "Tags": {"Project": "project-12"}}' \
  --query "QueueUrl" --output text)

export DLQ_ARN=$(aws sqs get-queue-attributes \
  --queue-url $DLQ_URL \
  --attribute-names QueueArn \
  --query "Attributes.QueueArn" --output text)

echo "DLQ URL: $DLQ_URL"
echo "DLQ ARN: $DLQ_ARN"

export QUEUE_URL=$(aws sqs create-queue \
  --queue-name $QUEUE_NAME \
  --attributes "{
    \"VisibilityTimeout\": \"60\",
    \"MessageRetentionPeriod\": \"345600\",
    \"ReceiveMessageWaitTimeSeconds\": \"20\",
    \"RedrivePolicy\": \"{\\\"deadLetterTargetArn\\\":\\\"$DLQ_ARN\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"
  }" \
  --query "QueueUrl" --output text)

export QUEUE_ARN=$(aws sqs get-queue-attributes \
  --queue-url $QUEUE_URL \
  --attribute-names QueueArn \
  --query "Attributes.QueueArn" --output text)

echo "Queue URL: $QUEUE_URL"
echo "Queue ARN: $QUEUE_ARN"

SQS_POLICY="{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Sid\":\"AllowS3ToSendMessages\",
    \"Effect\":\"Allow\",
    \"Principal\":{\"Service\":\"s3.amazonaws.com\"},
    \"Action\":\"sqs:SendMessage\",
    \"Resource\":\"$QUEUE_ARN\",
    \"Condition\":{
      \"ArnLike\":{
        \"aws:SourceArn\":\"arn:aws:s3:::$SOURCE_BUCKET\"
      }
    }
  }]
}"

aws sqs set-queue-attributes \
  --queue-url $QUEUE_URL \
  --attributes "Policy=$SQS_POLICY"

echo "SQS policy applied"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
. .\00-pre-flight.ps1

# Create DLQ first
$DLQ_URL = aws sqs create-queue `
  --queue-name $DLQ_NAME `
  --attributes '{"MessageRetentionPeriod": "1209600", "Tags": {"Project": "project-12"}}' `
  --query "QueueUrl" --output text

$DLQ_ARN = aws sqs get-queue-attributes `
  --queue-url $DLQ_URL `
  --attribute-names QueueArn `
  --query "Attributes.QueueArn" --output text

Write-Host "DLQ URL: $DLQ_URL"
Write-Host "DLQ ARN: $DLQ_ARN"

# Create main queue with DLQ configured
$QUEUE_URL = aws sqs create-queue `
  --queue-name $QUEUE_NAME `
  --attributes "{
    `"VisibilityTimeout`": `"60`",
    `"MessageRetentionPeriod`": `"345600`",
    `"ReceiveMessageWaitTimeSeconds`": `"20`",
    `"RedrivePolicy`": `"{ \\`"deadLetterTargetArn\\`":\\`"$DLQ_ARN\\`", \\`"maxReceiveCount\\`":\\`"3\\`" }`"
  }"  `
  --query "QueueUrl" --output text

$QUEUE_ARN = aws sqs get-queue-attributes `
  --queue-url $QUEUE_URL `
  --attribute-names QueueArn `
  --query "Attributes.QueueArn" --output text

Write-Host "Queue URL: $QUEUE_URL"
Write-Host "Queue ARN: $QUEUE_ARN"

# Allow S3 to publish messages to SQS
$SQS_POLICY = "{
  `"Version`":`"2012-10-17`",
  `"Statement`":[{
    `"Sid`":`"AllowS3ToSendMessages`",
    `"Effect`":`"Allow`",
    `"Principal`":{`"Service`":`"s3.amazonaws.com`"},
    `"Action`":`"sqs:SendMessage`",
    `"Resource`":`"$QUEUE_ARN`",
    `"Condition`":{
      `"ArnLike`":{
        `"aws:SourceArn`":`"arn:aws:s3:::$SOURCE_BUCKET`"
      }
    }
  }]
}"

aws sqs set-queue-attributes `
  --queue-url $QUEUE_URL `
  --attributes "Policy=$SQS_POLICY"

Write-Host "SQS policy applied"
```

## 🏗️ PART 4 — CONFIGURE S3 EVENT NOTIFICATION

### 🖥️ Method 1: AWS Management Console
1. Go to the **S3 Console** and open `event-pipeline-source-[YOUR-ACCOUNT-ID]`.
2. Go to the **Properties** tab. Scroll down to **Event notifications** and click **Create event notification**.
3. Name: `SendToSQSOnUpload`. Prefix: `uploads/`. Suffix: `.csv`.
4. Event types: Check **All object create events**.
5. Destination: Choose **SQS queue**, and select `file-processing-queue`. Click **Save changes**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# 03-s3-event-notification.sh
source ./00-pre-flight.sh

QUEUE_URL=$(aws sqs get-queue-url --queue-name $QUEUE_NAME --query "QueueUrl" --output text)
QUEUE_ARN=$(aws sqs get-queue-attributes --queue-url $QUEUE_URL --attribute-names QueueArn --query "Attributes.QueueArn" --output text)

NOTIFICATION_CONFIG="{
  \"QueueConfigurations\":[{
    \"Id\":\"SendToSQSOnUpload\",
    \"QueueArn\":\"$QUEUE_ARN\",
    \"Events\":[\"s3:ObjectCreated:*\"],
    \"Filter\":{
      \"Key\":{
        \"FilterRules\":[
          {\"Name\":\"prefix\",\"Value\":\"uploads/\"},
          {\"Name\":\"suffix\",\"Value\":\".csv\"}
        ]
      }
    }
  },{
    \"Id\":\"SendToSQSOnJsonUpload\",
    \"QueueArn\":\"$QUEUE_ARN\",
    \"Events\":[\"s3:ObjectCreated:*\"],
    \"Filter\":{
      \"Key\":{
        \"FilterRules\":[
          {\"Name\":\"prefix\",\"Value\":\"uploads/\"},
          {\"Name\":\"suffix\",\"Value\":\".json\"}
        ]
      }
    }
  }]
}"

aws s3api put-bucket-notification-configuration \
  --bucket $SOURCE_BUCKET \
  --notification-configuration "$NOTIFICATION_CONFIG"

echo "S3 event notifications configured"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
. .\00-pre-flight.ps1
$QUEUE_URL = aws sqs get-queue-url --queue-name $QUEUE_NAME --query "QueueUrl" --output text
$QUEUE_ARN = aws sqs get-queue-attributes --queue-url $QUEUE_URL --attribute-names QueueArn --query "Attributes.QueueArn" --output text

# Configure S3 to send events to SQS
$NOTIFICATION_CONFIG = "{
  `"QueueConfigurations`":[{
    `"Id`":`"SendToSQSOnUpload`",
    `"QueueArn`":`"$QUEUE_ARN`",
    `"Events`":[`"s3:ObjectCreated:*`"],
    `"Filter`":{
      `"Key`":{
        `"FilterRules`":[
          {`"Name`":`"prefix`",`"Value`":`"uploads/`"},
          {`"Name`":`"suffix`",`"Value`":`".csv`"}
        ]
      }
    }
  },{
    `"Id`":`"SendToSQSOnJsonUpload`",
    `"QueueArn`":`"$QUEUE_ARN`",
    `"Events`":[`"s3:ObjectCreated:*`"],
    `"Filter`":{
      `"Key`":{
        `"FilterRules`":[
          {`"Name`":`"prefix`",`"Value`":`"uploads/`"},
          {`"Name`":`"suffix`",`"Value`":`".json`"}
        ]
      }
    }
  }]
}"

aws s3api put-bucket-notification-configuration `
  --bucket $SOURCE_BUCKET `
  --notification-configuration $NOTIFICATION_CONFIG

Write-Host "S3 event notifications configured"
```

## 🏗️ PART 5 — CONFIGURE IAM ROLE

### 🖥️ Method 1: AWS Management Console
1. Navigate to the **IAM Console** > **Roles** > **Create role**.
2. Select **AWS Service** > **Lambda** and click **Next**.
3. Attach `AWSLambdaBasicExecutionRole` and `AWSLambdaSQSQueueExecutionRole`.
4. Name the role `lambda-file-processor-role` and click **Create**.
5. Select the role, click **Add permissions** > **Create inline policy**.
6. Grant `s3:GetObject` on `arn:aws:s3:::event-pipeline-source-[ACCOUNT-ID]/*` and `s3:PutObject` on `arn:aws:s3:::event-pipeline-output-[ACCOUNT-ID]/*`. Save as `s3-pipeline-access`.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# 04-create-lambda-role.sh
source ./00-pre-flight.sh

aws iam create-role \
  --role-name $LAMBDA_ROLE \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy \
  --role-name $LAMBDA_ROLE \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam attach-role-policy \
  --role-name $LAMBDA_ROLE \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole

aws iam put-role-policy \
  --role-name $LAMBDA_ROLE \
  --policy-name s3-pipeline-access \
  --policy-document "{
    \"Version\":\"2012-10-17\",
    \"Statement\":[
      {
        \"Sid\":\"ReadSourceBucket\",
        \"Effect\":\"Allow\",
        \"Action\":[\"s3:GetObject\", \"s3:GetObjectVersion\", \"s3:HeadObject\"],
        \"Resource\":\"arn:aws:s3:::$SOURCE_BUCKET/*\"
      },
      {
        \"Sid\":\"WriteOutputBucket\",
        \"Effect\":\"Allow\",
        \"Action\":[\"s3:PutObject\", \"s3:PutObjectTagging\"],
        \"Resource\":\"arn:aws:s3:::$OUTPUT_BUCKET/*\"
      }
    ]
  }"

LAMBDA_ROLE_ARN=$(aws iam get-role --role-name $LAMBDA_ROLE --query "Role.Arn" --output text)
echo "Lambda role ARN: $LAMBDA_ROLE_ARN"
sleep 10
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
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
```

## 🏗️ PART 6 — DEPLOY LAMBDA FUNCTION

### 🖥️ Method 1: AWS Management Console
1. Navigate to the **Lambda Console** and click **Create function**.
2. Name: `file-processor`, Runtime: **Python 3.12**, Role: `lambda-file-processor-role`.
3. Click **Create function**.
4. In the code editor, paste the contents of `lambda_function.py`.
5. Go to **Configuration** > **Environment variables** and add `OUTPUT_BUCKET` pointing to your output bucket.
6. Click **Deploy**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# 05-deploy-lambda.sh
source ./00-pre-flight.sh

LAMBDA_ROLE_ARN=$(aws iam get-role --role-name $LAMBDA_ROLE --query "Role.Arn" --output text)

cd ../../lambda || exit
zip -r function.zip lambda_function.py
cd - || exit

LAMBDA_ARN=$(aws lambda create-function \
  --function-name $LAMBDA_NAME \
  --runtime python3.12 \
  --role $LAMBDA_ROLE_ARN \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://../../lambda/function.zip \
  --timeout 60 \
  --memory-size 256 \
  --environment Variables="{OUTPUT_BUCKET=$OUTPUT_BUCKET,REGION=ap-south-1}" \
  --description "Event-driven file processor" \
  --query "FunctionArn" --output text)

echo "Lambda ARN: $LAMBDA_ARN"
aws lambda wait function-active --function-name $LAMBDA_NAME
echo "Lambda is active"

rm ../../lambda/function.zip
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
. .\00-pre-flight.ps1
$LAMBDA_ROLE_ARN = aws iam get-role --role-name $LAMBDA_ROLE --query "Role.Arn" --output text

# Package Lambda
Compress-Archive `
  -Path ..\..\lambda\lambda_function.py `
  -DestinationPath function.zip `
  -Force

# Deploy Lambda
$LAMBDA_ARN = aws lambda create-function `
  --function-name $LAMBDA_NAME `
  --runtime python3.12 `
  --role $LAMBDA_ROLE_ARN `
  --handler lambda_function.lambda_handler `
  --zip-file fileb://function.zip `
  --timeout 60 `
  --memory-size 256 `
  --environment Variables="{OUTPUT_BUCKET=$OUTPUT_BUCKET,REGION=ap-south-1}" `
  --description "Event-driven file processor" `
  --query "FunctionArn" --output text

Write-Host "Lambda ARN: $LAMBDA_ARN"

# Wait for Lambda to be active
aws lambda wait function-active --function-name $LAMBDA_NAME
Write-Host "Lambda is active"

Remove-Item function.zip -Force
```

## 🏗️ PART 7 — CONNECT SQS TO LAMBDA

### 🖥️ Method 1: AWS Management Console
1. In the **Lambda Console**, for your `file-processor` function, click **Add trigger**.
2. Source: **SQS**.
3. SQS queue: Select `file-processing-queue`.
4. Batch size: **1**.
5. Click **Add**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# 06-connect-sqs-lambda.sh
source ./00-pre-flight.sh

QUEUE_URL=$(aws sqs get-queue-url --queue-name $QUEUE_NAME --query "QueueUrl" --output text)
QUEUE_ARN=$(aws sqs get-queue-attributes --queue-url $QUEUE_URL --attribute-names QueueArn --query "Attributes.QueueArn" --output text)

ESM_UUID=$(aws lambda create-event-source-mapping \
  --function-name $LAMBDA_NAME \
  --event-source-arn $QUEUE_ARN \
  --batch-size 1 \
  --maximum-batching-window-in-seconds 0 \
  --function-response-types ReportBatchItemFailures \
  --query "UUID" --output text)

echo "Event source mapping UUID: $ESM_UUID"

aws lambda get-event-source-mapping \
  --uuid $ESM_UUID \
  --query "{State:State,BatchSize:BatchSize,Queue:EventSourceArn}" \
  --output table
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
. .\00-pre-flight.ps1

$QUEUE_URL = aws sqs get-queue-url --queue-name $QUEUE_NAME --query "QueueUrl" --output text
$QUEUE_ARN = aws sqs get-queue-attributes --queue-url $QUEUE_URL --attribute-names QueueArn --query "Attributes.QueueArn" --output text

# Create event source mapping (SQS triggers Lambda)
$ESM_UUID = aws lambda create-event-source-mapping `
  --function-name $LAMBDA_NAME `
  --event-source-arn $QUEUE_ARN `
  --batch-size 1 `
  --maximum-batching-window-in-seconds 0 `
  --function-response-types ReportBatchItemFailures `
  --query "UUID" --output text

Write-Host "Event source mapping UUID: $ESM_UUID"

# Verify it is enabled
aws lambda get-event-source-mapping `
  --uuid $ESM_UUID `
  --query "{State:State,BatchSize:BatchSize,Queue:EventSourceArn}" `
  --output table
```
