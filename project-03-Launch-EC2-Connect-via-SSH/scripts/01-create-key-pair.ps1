aws ec2 create-key-pair `
  --key-name aws-ec2-keypair `
  --key-type RSA `
  --key-format ppk `
  --query "KeyMaterial" `
  --output text | Out-File `
  -FilePath "C:\Users\$env:USERNAME\aws-keys\aws-ec2-keypair.ppk" `
  -Encoding ascii

Write-Host -ForegroundColor Green "Created key pair: aws-ec2-keypair"
