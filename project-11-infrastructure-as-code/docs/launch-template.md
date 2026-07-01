# EC2 Launch Template Design

The `WebServerLaunchTemplate` resource in our CloudFormation stack serves as the blueprint for all EC2 instances launched by the Auto Scaling Group. Using a Launch Template over a Launch Configuration provides versioning and advanced features.

## Launch Template Specifications

- **AMI (Amazon Machine Image)**: 
  Instead of hardcoding an AMI ID (which varies by region and gets outdated), the template uses an AWS Systems Manager (SSM) Parameter Store resolution to always fetch the latest Amazon Linux 2023 AMI:
  `{{resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64}}`
- **Instance Type**: Parameterized (default is `t2.micro` for Free Tier compatibility, with `t3.micro` allowed).
- **Key Pair**: Parameterized (`KeyPairName`) for optional SSH access, although SSH ports are closed by default for security.
- **Security Groups**: Associated with the `EC2SecurityGroup`.
- **Tags**: Instances are tagged with the Project Name and `ManagedBy: CloudFormation`.

## User Data Script

The User Data script is executed as the `root` user during the first boot cycle of the instance. It automates the web server setup.

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
echo "<html><body style='font-family:Arial;text-align:center;padding:60px;background:#f0f2f5'>
<h1>CloudFormation Deployed Instance</h1>
<p>Instance: $INSTANCE_ID</p>
<p>AZ: $AZ</p>
<p>Environment: ${EnvironmentType}</p>
<p>Stack: ${AWS::StackName}</p>
</body></html>" > /var/www/html/index.html
```

### Key Highlights of User Data:
1. **Installs Apache (`httpd`)** and ensures it starts automatically.
2. **Retrieves Metadata**: Uses IMDS (Instance Metadata Service) to fetch the specific `instance-id` and `availability-zone`.
3. **CloudFormation Substitution**: Uses the `Fn::Sub` intrinsic function to inject the `${EnvironmentType}` parameter and the `${AWS::StackName}` pseudo-parameter directly into the HTML payload before the script is run on the instance.
