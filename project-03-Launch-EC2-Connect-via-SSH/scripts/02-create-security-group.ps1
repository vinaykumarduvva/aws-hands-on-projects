$VPC_ID = aws ec2 describe-vpcs `
  --filters "Name=isDefault,Values=true" `
  --query "Vpcs[0].VpcId" --output text

$MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" `
  -UseBasicParsing).Content.Trim()

$SG_ID = aws ec2 create-security-group `
  --group-name ec2-web-sg `
  --description "Allow SSH and HTTP access" `
  --vpc-id $VPC_ID `
  --query "GroupId" --output text

aws ec2 authorize-security-group-ingress `
  --group-id $SG_ID --protocol tcp --port 22 --cidr "$MY_IP/32"

aws ec2 authorize-security-group-ingress `
  --group-id $SG_ID --protocol tcp --port 80 --cidr "0.0.0.0/0"
Write-Host -ForegroundColor Green "Created SG: $SG_ID"
