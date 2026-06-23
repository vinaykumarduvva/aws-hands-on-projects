aws secretsmanager describe-secret `
    --secret-id "rds/myapp/credentials" `
    --query "{Name:Name,ARN:ARN,Created:CreatedDate}" `
    --output table
