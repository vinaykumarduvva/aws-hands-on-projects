import os
import re
import shutil

root_dir = r"e:\AWS Hands-on Projects"
projects = [f for f in os.listdir(root_dir) if f.startswith("project-") and os.path.isdir(os.path.join(root_dir, f))]
projects.sort()

# Only process 1-10
projects = projects[:10]

def extract_section(content, section_name):
    # Regex to find a heading and capture everything until the next heading of same or higher level
    # Assumes ## section_name
    pattern = re.compile(rf"(##\s+{section_name}.*?)(?=\n##\s+|$)", re.DOTALL | re.IGNORECASE)
    match = pattern.search(content)
    return match.group(1).strip() if match else ""

def generate_docs():
    for proj in projects:
        print(f"Processing {proj}...")
        proj_path = os.path.join(root_dir, proj)
        docs_path = os.path.join(proj_path, "docs")
        readme_path = os.path.join(proj_path, "README.md")
        
        os.makedirs(docs_path, exist_ok=True)
        
        readme_content = ""
        if os.path.exists(readme_path):
            with open(readme_path, "r", encoding="utf-8") as f:
                readme_content = f.read()
                
        # Read all existing markdown files in docs
        existing_docs = {}
        for f in os.listdir(docs_path):
            if f.endswith('.md'):
                with open(os.path.join(docs_path, f), "r", encoding="utf-8") as file:
                    existing_docs[f] = file.read()
        
        # 1. project-overview.md
        overview_content = existing_docs.get('project-overview.md', '')
        if not overview_content:
            overview_text = extract_section(readme_content, "Overview")
            overview_content = f"# Project Overview\n\n{overview_text}" if overview_text else "# Project Overview\n\nOverview details for this project."
        
        # 2. architecture.md
        arch_content = existing_docs.get('architecture.md', '')
        if not arch_content:
            arch_text = extract_section(readme_content, "Architecture")
            if not arch_text: arch_text = extract_section(readme_content, "Architecture Diagram")
            arch_content = f"# Architecture\n\n{arch_text}" if arch_text else "# Architecture\n\nArchitecture details and diagrams."

        # 3. deployment-guide.md
        deploy_content = existing_docs.get('deployment-guide.md', '')
        if not deploy_content:
            setup_text = extract_section(readme_content, "Setup Steps")
            if not setup_text: setup_text = extract_section(readme_content, "Full Setup Guide")
            if not setup_text: setup_text = extract_section(readme_content, "Implementation Guide")
            
            cleanup_text = extract_section(readme_content, "Cleanup")
            if not cleanup_text: cleanup_text = existing_docs.get('cleanup-guide.md', '')
            
            existing_impl = existing_docs.get('implementation-guide.md', '')
            
            deploy_content = f"# Deployment Guide\n\n"
            deploy_content += "## Automated Scripts Available\n"
            deploy_content += "> [!TIP]\n> **Dual-Platform Execution:** This project contains fully automated deployment and teardown scripts for both Windows (PowerShell) and Linux/macOS (Bash). Check the `scripts/` directory for `.ps1` files and the `bash-scripts/` directory for `.sh` files.\n\n"
            
            if setup_text: deploy_content += f"{setup_text}\n\n"
            if existing_impl: deploy_content += f"{existing_impl}\n\n"
            if cleanup_text: deploy_content += f"## Cleanup Guide\n\n{cleanup_text}\n\n"
            
        # 4. troubleshooting.md
        troubleshoot_content = existing_docs.get('troubleshooting.md', '')
        if not troubleshoot_content:
            troubleshoot_text = extract_section(readme_content, "Troubleshooting")
            if not troubleshoot_text: troubleshoot_text = existing_docs.get('troubleshooting-instrustions.md', '')
            troubleshoot_content = f"# Troubleshooting Manual\n\n{troubleshoot_text}" if troubleshoot_text else "# Troubleshooting Manual\n\nCommon issues and resolutions."
            
        # 5. Optional design-specifications.md if it doesn't exist
        design_content = existing_docs.get('design-specifications.md', '')
        if not design_content:
            design_content = "# Design Specifications\n\n"
            # Scrape some tables from README
            sg_text = extract_section(readme_content, "Security Group")
            iam_text = extract_section(readme_content, "IAM Role")
            if sg_text: design_content += f"{sg_text}\n\n"
            if iam_text: design_content += f"{iam_text}\n\n"
            
        # Write files
        with open(os.path.join(docs_path, "project-overview.md"), "w", encoding="utf-8") as f: f.write(overview_content)
        with open(os.path.join(docs_path, "architecture.md"), "w", encoding="utf-8") as f: f.write(arch_content)
        with open(os.path.join(docs_path, "deployment-guide.md"), "w", encoding="utf-8") as f: f.write(deploy_content)
        with open(os.path.join(docs_path, "troubleshooting.md"), "w", encoding="utf-8") as f: f.write(troubleshoot_content)
        if design_content.strip() != "# Design Specifications":
            with open(os.path.join(docs_path, "design-specifications.md"), "w", encoding="utf-8") as f: f.write(design_content)
        
    print("Done generating docs.")

if __name__ == '__main__':
    generate_docs()
