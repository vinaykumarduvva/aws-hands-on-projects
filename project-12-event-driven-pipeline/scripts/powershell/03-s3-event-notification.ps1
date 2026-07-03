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
