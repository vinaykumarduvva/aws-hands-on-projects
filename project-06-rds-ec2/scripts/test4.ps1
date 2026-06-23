$SECRET_ARN = aws secretsmanager create-secret `
    --name "rds/myapp/credentials" `
    --description "RDS MySQL admin credentials for Project 6" `
    --secret-string '{
    "username": "admin",
    "password": "MyDB#Secure2024!",
    "engine": "mysql",
    "port": 3306,
    "dbname": "appdb"
  }' `
    --query "ARN" --output text
