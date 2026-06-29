$INSTANCE_ID = aws ec2 describe-instances --filters "Name=tag:Name,Values=my-first-ec2" --query "Reservations[0].Instances[0].InstanceId" --output text
$SG_ID = aws ec2 describe-security-groups --group-names ec2-web-sg --query "SecurityGroups[0].GroupId" --output text

aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
aws ec2 delete-security-group --group-id $SG_ID
aws ec2 delete-key-pair --key-name aws-ec2-keypair

aws iam remove-role-from-instance-profile `
  --instance-profile-name ec2-ssm-profile --role-name ec2-ssm-role
aws iam detach-role-policy `
  --role-name ec2-ssm-role `
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam delete-instance-profile --instance-profile-name ec2-ssm-profile
aws iam delete-role --role-name ec2-ssm-role

Write-Host -ForegroundColor Green "Cleanup complete"
