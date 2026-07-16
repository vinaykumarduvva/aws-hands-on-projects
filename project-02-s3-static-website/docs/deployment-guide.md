# Comprehensive Deployment Guide

This guide details the complete process for deploying this project's resources.

## 🏗️ PART 1 — CREATES THE INITIAL S3 BUCKET

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **S3** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
source ../../.env
aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
$BUCKET_NAME = (Get-Content ..\..\.env | Where-Object { $_ -match '^BUCKET_NAME=' } | ForEach-Object { $_ -replace '^BUCKET_NAME=','' })
$AWS_REGION = (Get-Content ..\..\.env | Where-Object { $_ -match '^AWS_REGION=' } | ForEach-Object { $_ -replace '^AWS_REGION=','' })
aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION
```

---

## 🏗️ PART 2 — ENABLES STATIC WEBSITE HOSTING

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **AWS Console** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
source ../../.env
aws s3api put-bucket-website --bucket "$BUCKET_NAME" --website-configuration '{"IndexDocument": {"Suffix": "index.html"},"ErrorDocument": {"Key": "error.html"}}'
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
$BUCKET_NAME = (Get-Content ..\..\.env | Where-Object { $_ -match '^BUCKET_NAME=' } | ForEach-Object { $_ -replace '^BUCKET_NAME=','' })
aws s3api put-bucket-website --bucket $BUCKET_NAME --website-configuration '{"IndexDocument": {"Suffix": "index.html"},"ErrorDocument": {"Key": "error.html"}}'
```

---

## 🏗️ PART 3 — APPLIES PUBLIC READ BUCKET POLICY

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **S3** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
source ../../.env
aws s3api put-public-access-block --bucket "$BUCKET_NAME" --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy '{"Version":"2012-10-17","Statement":[{"Sid":"PublicReadGetObject","Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::'"$BUCKET_NAME"'/*"}]}'
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
$BUCKET_NAME = (Get-Content ..\..\.env | Where-Object { $_ -match '^BUCKET_NAME=' } | ForEach-Object { $_ -replace '^BUCKET_NAME=','' })
aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy "{\`"Version\`":\`"2012-10-17\`",\`"Statement\`":[{\`"Sid\`":\`"PublicReadGetObject\`",\`"Effect\`":\`"Allow\`",\`"Principal\`":\`"*\`",\`"Action\`":\`"s3:GetObject\`",\`"Resource\`":\`"arn:aws:s3:::$BUCKET_NAME/*\`"}]}"
```

---

## 🏗️ PART 4 — UPLOADS HTML/CSS FILES TO S3

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **S3** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
source ../../.env
aws s3 sync ../../website/ s3://"$BUCKET_NAME"/ --region "$AWS_REGION"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
$BUCKET_NAME = (Get-Content ..\..\.env | Where-Object { $_ -match '^BUCKET_NAME=' } | ForEach-Object { $_ -replace '^BUCKET_NAME=','' })
$AWS_REGION = (Get-Content ..\..\.env | Where-Object { $_ -match '^AWS_REGION=' } | ForEach-Object { $_ -replace '^AWS_REGION=','' })
aws s3 sync ..\..\website\ s3://$BUCKET_NAME/ --region $AWS_REGION
```

---

## 🏗️ PART 5 — FORCES CLOUDFRONT TO PULL NEW FILES

### 🖥️ Method 1: AWS Management Console
1. Log into the AWS Management Console and use the top search bar to navigate to the **CloudFront** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**.

### 🐧 Method 2: AWS CLI (Bash)
```bash
#!/bin/bash
# Load environment variables
if [ -f "../../.env" ]; then
    source ../../.env
elif [ -f "../.env" ]; then
    source ../.env
elif [ -f ".env" ]; then
    source .env
else
    echo -e "\e[31mError: .env file not found.\e[0m"
    exit 1
fi

if [ -z "$DISTRIBUTION_ID" ]; then
    echo -e "\e[31mError: DISTRIBUTION_ID must be set in .env\e[0m"
    exit 1
fi

echo -e "\e[36mCreating CloudFront cache invalidation for distribution: $DISTRIBUTION_ID...\e[0m"
aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --paths "/*"

echo -e "\e[32mInvalidation request submitted.\e[0m"
```

### 🪟 Method 3: AWS CLI (PowerShell)
```powershell
<#
.SYNOPSIS
Invalidates the CloudFront cache.
#>

# Load environment variables
$envFile = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "..\..\.env"
if (-not (Test-Path $envFile)) {
    $envFile = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "..\.env"
}
if (-not (Test-Path $envFile)) {
    $envFile = ".env"
}

if (Test-Path $envFile) {
    Get-Content $envFile | Where-Object { $_ -match '^export\s+([^=]+)=(.*)$' } | ForEach-Object {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim(' "''')
        Set-Item -Path "env:\$name" -Value $value
    }
} else {
    Write-Host "Error: .env file not found." -ForegroundColor Red
    exit 1
}

$DistId = $env:DISTRIBUTION_ID

if ([string]::IsNullOrEmpty($DistId)) {
    Write-Host "Error: DISTRIBUTION_ID must be set in .env" -ForegroundColor Red
    exit 1
}

Write-Host "Creating CloudFront cache invalidation for distribution: $DistId..." -ForegroundColor Cyan
aws cloudfront create-invalidation `
  --distribution-id $DistId `
  --paths "/*"

Write-Host "Invalidation request submitted." -ForegroundColor Green
```

---

## 🧹 TEARDOWN
To prevent recurring AWS charges, proceed to the `docs/cleanup-guide.md` to run the tear-down scripts.
