import os
import re

base_dir = r"e:\AWS Hands-on Projects"
projects = [
    "project-01-iam-setup",
    "project-02-s3-static-website",
    "project-03-Launch-EC2-Connect-via-SSH",
    "project-04-s3-versioning",
    "project-05-Custom-VPC",
    "project-06-rds-ec2",
    "project-07-cloudwatch-monitoring",
    "project-08-serverless-rest-api",
    "project-09-cicd-pipeline",
    "project-10-auto-scaling-alb",
    "project-13-ecs-fargate-container"
]

def parse_filename(filename):
    # Remove extension
    name = os.path.splitext(filename)[0]
    # Remove leading numbers and dash (e.g., 01-, 02-)
    name = re.sub(r'^\d+-?', '', name)
    # Replace hyphens/underscores with spaces
    name = name.replace('-', ' ').replace('_', ' ')
    # Capitalize words
    return name.title()

for proj in projects:
    images_dir = os.path.join(base_dir, proj, "images")
    if os.path.exists(images_dir):
        files = [f for f in os.listdir(images_dir) if os.path.isfile(os.path.join(images_dir, f)) and f.endswith(('.png', '.jpg', '.jpeg'))]
        files.sort()
        
        md_content = f"# {proj.replace('-', ' ').title()} Screenshots\n\n"
        md_content += f"This document provides a detailed list of screenshots captured during the execution of **{proj}**. These images serve as visual proof of the project's milestones and infrastructure setup.\n\n"
        md_content += "## Screenshot Details\n\n"
        
        for file in files:
            desc = parse_filename(file)
            md_content += f"### {desc}\n"
            md_content += f"* **File:** `{file}`\n"
            md_content += f"* **Description:** Visual confirmation of the {desc} step/resource in this project.\n\n"
            
        md_path = os.path.join(images_dir, "screenshots.md")
        with open(md_path, "w", encoding="utf-8") as f:
            f.write(md_content)
        
        print(f"Updated screenshots.md for {proj}")
