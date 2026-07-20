import os
import glob
import re

workspace = r"e:\AWS Hands-on Projects"

def generate_ui_steps(part_title):
    title_lower = part_title.lower()
    service = "AWS Console"
    
    # Determine the most likely service based on the part title
    if "s3" in title_lower or "bucket" in title_lower:
        service = "S3"
    elif "ec2" in title_lower or "instance" in title_lower or "sg " in title_lower or "security group" in title_lower:
        service = "EC2"
    elif "vpc" in title_lower or "subnet" in title_lower or "igw" in title_lower or "nat" in title_lower:
        service = "VPC"
    elif "rds" in title_lower or "mysql" in title_lower or "database" in title_lower:
        service = "RDS"
    elif "cloudwatch" in title_lower or "alarm" in title_lower or "log" in title_lower:
        service = "CloudWatch"
    elif "sns" in title_lower or "topic" in title_lower:
        service = "SNS"
    elif "lambda" in title_lower or "function" in title_lower:
        service = "Lambda"
    elif "api gateway" in title_lower or "rest api" in title_lower:
        service = "API Gateway"
    elif "dynamodb" in title_lower or "table" in title_lower:
        service = "DynamoDB"
    elif "codebuild" in title_lower or "codecommit" in title_lower or "codedeploy" in title_lower or "codepipeline" in title_lower or "ci/cd" in title_lower:
        service = "Developer Tools"
    elif "alb" in title_lower or "load balancer" in title_lower or "target group" in title_lower:
        service = "EC2 > Load Balancing"
    elif "asg" in title_lower or "auto scaling" in title_lower:
        service = "EC2 > Auto Scaling"
    elif "iam" in title_lower or "role" in title_lower or "policy" in title_lower:
        service = "IAM"
    elif "cloudfront" in title_lower or "cdn" in title_lower:
        service = "CloudFront"
    elif "eventbridge" in title_lower or "event" in title_lower:
        service = "EventBridge"
    elif "sqs" in title_lower or "queue" in title_lower:
        service = "SQS"
    elif "cloudformation" in title_lower or "iac" in title_lower or "stack" in title_lower:
        service = "CloudFormation"

    steps = f"""1. Log into the AWS Management Console and use the top search bar to navigate to the **{service}** dashboard.
2. Locate and click the primary **Create**, **Launch**, or **Configure** button relevant to the task.
3. In the configuration wizard, ensure you input the names, regions, and parameters exactly as defined in your environment variables.
4. Review the security and networking settings carefully. (Tip: Use the exact property names and values shown in the CLI commands in Method 2 below).
5. Click to finalize and create the resource, then wait for its status to change to **Available**, **Active**, or **Running**."""
    
    return steps

for i in range(2, 13):
    project_pattern = f"project-{i:02d}-*"
    search_path = os.path.join(workspace, project_pattern, "docs", "deployment-guide.md")
    files = glob.glob(search_path)
    
    for file in files:
        with open(file, "r", encoding="utf-8") as f:
            content = f.read()
            
        lines = content.split('\n')
        new_lines = []
        current_part = "AWS Resource"
        
        skip_next = False
        for idx, line in enumerate(lines):
            if skip_next:
                skip_next = False
                continue
                
            if line.startswith("## ") and "PART" in line:
                current_part = line.strip()
                
            if line.strip() == "### 🖥️ Method 1: AWS Management Console":
                new_lines.append(line)
                # Next line is usually the *(Refer...)* text. We want to replace it.
                if idx + 1 < len(lines) and "*(Refer to the repository instructions or script comments for UI steps)*" in lines[idx+1]:
                    new_lines.append(generate_ui_steps(current_part))
                    skip_next = True
                else:
                    # Just in case it's not the exact next line or was modified
                    # If the next line isn't the placeholder, we don't replace it
                    # But if it is empty, we inject after. Let's just check if the placeholder is in the file at all.
                    pass
                continue
            
            new_lines.append(line)
            
        with open(file, "w", encoding="utf-8") as f:
            f.write('\n'.join(new_lines))
        print(f"Updated {file}")

print("Done.")
