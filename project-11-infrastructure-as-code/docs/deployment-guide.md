# Deployment Guide: Infrastructure as Code

This guide covers the full lifecycle of a CloudFormation stack: Validation, Deployment, Modification, and Cleanup.

## 🏗️ PART 1 — PRE-FLIGHT CHECKS

### 🖥️ Method 1: AWS Management Console
1. Navigate to the top right corner of the AWS Management Console.
2. Verify that you are operating in the **ap-south-1 (Mumbai)** region.
3. Navigate to **EC2** > **Key Pairs** and ensure `aws-ec2-keypair` exists in this region.

### 🐧 Method 2: AWS CLI (Bash)
```bash
# Confirm region (should be ap-south-1)
aws configure get region

# Confirm identity
aws sts get-caller-identity

# Confirm your EC2 key pair exists in the region
aws ec2 describe-key-pairs --key-names aws-ec2-keypair \
  --query "KeyPairs[0].KeyName" --output text
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
# Confirm region (should be ap-south-1)
aws configure get region

# Confirm identity
aws sts get-caller-identity

# Confirm your EC2 key pair exists in the region
aws ec2 describe-key-pairs --key-names aws-ec2-keypair `
  --query "KeyPairs[0].KeyName" --output text
```

## 🏗️ PART 2 — VALIDATION

Always validate your template syntax locally before pushing it to AWS. This catches YAML formatting and structural errors immediately.

### 🖥️ Method 1: AWS Management Console
*(Template validation is performed automatically when you upload a template in the CloudFormation console during stack creation. To pre-validate, you must use the CLI or AWS Application Composer).*

### 🐧 Method 2: AWS CLI (Bash)
```bash
aws cloudformation validate-template \
  --template-body file://templates/main-stack.yaml
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
aws cloudformation validate-template `
  --template-body file://templates/main-stack.yaml
```

## 🏗️ PART 3 — INITIAL DEPLOYMENT (CREATE STACK)

### 🖥️ Method 1: AWS Management Console
1. Navigate to the **CloudFormation** console.
2. Click **Create stack** > **With new resources (standard)**.
3. Select **Template is ready** and **Upload a template file**.
4. Upload `templates/main-stack.yaml` and click Next.
5. Stack name: `my-app-stack`.
6. Fill in the parameters (ProjectName, EnvironmentType, InstanceType, KeyPairName, etc.) and click Next.
7. Acknowledge IAM resource creation at the bottom of the review page and click **Submit**.
8. Wait for the status to change to `CREATE_COMPLETE`.

### 🐧 Method 2: AWS CLI (Bash)
```bash
aws cloudformation create-stack \
  --stack-name my-app-stack \
  --template-body file://templates/main-stack.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=cfn-web-app \
    ParameterKey=EnvironmentType,ParameterValue=dev \
    ParameterKey=InstanceType,ParameterValue=t2.micro \
    ParameterKey=KeyPairName,ParameterValue=aws-ec2-keypair \
    ParameterKey=MinInstances,ParameterValue=2 \
    ParameterKey=MaxInstances,ParameterValue=4 \
    ParameterKey=DesiredInstances,ParameterValue=2 \
  --capabilities CAPABILITY_IAM

# Monitor the creation process until CREATE_COMPLETE
aws cloudformation wait stack-create-complete --stack-name my-app-stack
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
aws cloudformation create-stack `
  --stack-name my-app-stack `
  --template-body file://templates/main-stack.yaml `
  --parameters `
    ParameterKey=ProjectName,ParameterValue=cfn-web-app `
    ParameterKey=EnvironmentType,ParameterValue=dev `
    ParameterKey=InstanceType,ParameterValue=t2.micro `
    ParameterKey=KeyPairName,ParameterValue=aws-ec2-keypair `
    ParameterKey=MinInstances,ParameterValue=2 `
    ParameterKey=MaxInstances,ParameterValue=4 `
    ParameterKey=DesiredInstances,ParameterValue=2 `
  --capabilities CAPABILITY_IAM

# Monitor the creation process until CREATE_COMPLETE
aws cloudformation wait stack-create-complete --stack-name my-app-stack
```

## 🏗️ PART 4 — TESTING THE DEPLOYMENT

### 🖥️ Method 1: AWS Management Console
1. In the **CloudFormation** console, select `my-app-stack`.
2. Click on the **Outputs** tab.
3. Copy the Value for the `ALBUrl` key.
4. Paste it into your browser. It may take 2-3 minutes for the EC2 instances to pass health checks and display the webpage.

### 🐧 Method 2: AWS CLI (Bash)
```bash
ALB_URL=$(aws cloudformation describe-stacks \
  --stack-name my-app-stack \
  --query "Stacks[0].Outputs[?OutputKey=='ALBUrl'].OutputValue" \
  --output text)

echo "Application URL: $ALB_URL"

# Wait ~2 minutes for instances to pass ALB health checks, then test:
curl -I $ALB_URL
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
$ALB_URL = aws cloudformation describe-stacks `
  --stack-name my-app-stack `
  --query "Stacks[0].Outputs[?OutputKey=='ALBUrl'].OutputValue" `
  --output text

Write-Host "Application URL: $ALB_URL"

# Wait ~2 minutes for instances to pass ALB health checks, then test:
Invoke-WebRequest -Uri $ALB_URL -UseBasicParsing | Select-Object StatusCode
```

## 🏗️ PART 5 — SAFE UPDATES (CHANGE SETS)

Never update a stack blindly in production. Always preview the impact.

### 🖥️ Method 1: AWS Management Console
1. In the **CloudFormation** console, select `my-app-stack` and click **Update**.
2. Select **Replace current template** and upload a modified `main-stack.yaml` (or just modify parameters if using the same template).
3. Click through the wizard. On the final page, CloudFormation will automatically generate a Change Set preview.
4. Review the preview carefully to ensure no critical resources show "Replacement: True".
5. Click **Submit** to execute the changes.

### 🐧 Method 2: AWS CLI (Bash)
```bash
aws cloudformation create-change-set \
  --stack-name my-app-stack \
  --change-set-name increase-capacity-preview \
  --template-body file://templates/main-stack.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=cfn-web-app \
    ParameterKey=EnvironmentType,ParameterValue=dev \
    ParameterKey=InstanceType,ParameterValue=t2.micro \
    ParameterKey=KeyPairName,ParameterValue=aws-ec2-keypair \
    ParameterKey=MinInstances,ParameterValue=2 \
    ParameterKey=MaxInstances,ParameterValue=6 \
    ParameterKey=DesiredInstances,ParameterValue=2 \
  --capabilities CAPABILITY_IAM

aws cloudformation wait change-set-create-complete \
  --stack-name my-app-stack --change-set-name increase-capacity-preview

# Review the changes (ensure Replacement: False for critical resources)
aws cloudformation describe-change-set \
  --stack-name my-app-stack \
  --change-set-name increase-capacity-preview \
  --query "Changes[*].ResourceChange.{Action:Action,Resource:LogicalResourceId,Replacement:Replacement}" \
  --output table

# Execute
aws cloudformation execute-change-set \
  --stack-name my-app-stack \
  --change-set-name increase-capacity-preview

aws cloudformation wait stack-update-complete --stack-name my-app-stack
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
aws cloudformation create-change-set `
  --stack-name my-app-stack `
  --change-set-name increase-capacity-preview `
  --template-body file://templates/main-stack.yaml `
  --parameters `
    ParameterKey=ProjectName,ParameterValue=cfn-web-app `
    ParameterKey=EnvironmentType,ParameterValue=dev `
    ParameterKey=InstanceType,ParameterValue=t2.micro `
    ParameterKey=KeyPairName,ParameterValue=aws-ec2-keypair `
    ParameterKey=MinInstances,ParameterValue=2 `
    ParameterKey=MaxInstances,ParameterValue=6 `
    ParameterKey=DesiredInstances,ParameterValue=2 `
  --capabilities CAPABILITY_IAM

aws cloudformation wait change-set-create-complete `
  --stack-name my-app-stack --change-set-name increase-capacity-preview

# Review the changes (ensure Replacement: False for critical resources)
aws cloudformation describe-change-set `
  --stack-name my-app-stack `
  --change-set-name increase-capacity-preview `
  --query "Changes[*].ResourceChange.{Action:Action,Resource:LogicalResourceId,Replacement:Replacement}" `
  --output table

# Execute
aws cloudformation execute-change-set `
  --stack-name my-app-stack `
  --change-set-name increase-capacity-preview

aws cloudformation wait stack-update-complete --stack-name my-app-stack
```

## 🏗️ PART 6 — CLEANUP (TEARDOWN)

The greatest benefit of IaC is cleanly destroying the entire environment.

See the [Cleanup Guide](cleanup-guide.md) for full teardown instructions.
