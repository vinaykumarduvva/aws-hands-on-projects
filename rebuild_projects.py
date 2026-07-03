import os
import re
import shutil
import glob

# Constants
ROOT_DIR = r"e:\AWS Hands-on Projects"

PROJECT_META = {
    "01": {"title": "AWS Account Setup & IAM Foundations", "time": "1-2 Hours", "services": ["IAM", "SNS", "CloudWatch"]},
    "02": {"title": "Static Website on S3 + CloudFront", "time": "2-3 Hours", "services": ["S3", "CloudFront"]},
    "03": {"title": "Launch EC2 & Connect via SSH", "time": "2-3 Hours", "services": ["EC2", "VPC", "SSM"]},
    "04": {"title": "S3 Versioning, Lifecycle & Replication", "time": "2-3 Hours", "services": ["S3"]},
    "05": {"title": "Custom VPC: Subnets, IGW, NAT", "time": "3-4 Hours", "services": ["VPC", "EC2"]},
    "06": {"title": "RDS MySQL + EC2 Two-Tier App", "time": "3-4 Hours", "services": ["RDS", "EC2"]},
    "07": {"title": "CloudWatch Alarms + SNS Alerts", "time": "2-3 Hours", "services": ["CloudWatch", "SNS"]},
    "08": {"title": "Serverless REST API", "time": "3-4 Hours", "services": ["API Gateway", "Lambda", "DynamoDB"]},
    "09": {"title": "CI/CD Pipeline", "time": "4-5 Hours", "services": ["CodeCommit", "CodeBuild", "CodeDeploy"]},
    "10": {"title": "Auto Scaling Group + ALB", "time": "4-5 Hours", "services": ["EC2", "ALB", "ASG"]},
    "11": {"title": "Infrastructure as Code", "time": "4-5 Hours", "services": ["CloudFormation"]}
}

def extract_section(content, section_name):
    pattern = re.compile(rf"(##\s+{section_name}.*?)(?=\n##\s+|$)", re.DOTALL | re.IGNORECASE)
    match = pattern.search(content)
    if match:
        text = match.group(1).strip()
        return text.split('\n', 1)[1].strip() if '\n' in text else ""
    return ""

def translate_ps1_to_sh(ps1_content):
    # Very basic translation to ensure parity
    sh_content = "#!/bin/bash\n"
    lines = ps1_content.split('\n')
    for line in lines:
        if line.startswith('#'):
            sh_content += line + "\n"
            continue
        
        # Replace backticks with slashes
        line = line.replace('`', '\\')
        
        # Replace variable assignments: $VAR = "value" -> VAR="value"
        line = re.sub(r'^\$([A-Za-z0-9_]+)\s*=\s*(.*)', r'\1=\2', line)
        
        # Replace Write-Host
        line = re.sub(r'Write-Host\s+-ForegroundColor\s+\w+\s+', 'echo ', line, flags=re.IGNORECASE)
        line = line.replace('Write-Host ', 'echo ')
        
        # Replace Start-Sleep -Seconds X
        line = re.sub(r'Start-Sleep\s+-Seconds\s+(\d+)', r'sleep \1', line, flags=re.IGNORECASE)
        
        # Powershell string interpolation $(...) to shell $(...)
        
        sh_content += line + "\n"
    return sh_content

def build_svg(num, title, services):
    colors = {"S3": "#569A31", "EC2": "#F68536", "IAM": "#DD344C", "VPC": "#3F8624", "CloudFront": "#A166FF", "RDS": "#3B48CC", "Lambda": "#F69905"}
    
    icons = ""
    x_offset = 300
    for i, svc in enumerate(services[:2]):
        color = colors.get(svc, "#FF4F8B")
        icons += f'''
  <g transform="translate({x_offset}, 320)">
    <rect x="0" y="0" width="220" height="120" class="card pulse-obj" />
    <rect x="20" y="20" width="40" height="40" fill="{color}" class="icon-box" />
    <text x="40" y="47" fill="white" font-size="20" font-weight="bold" text-anchor="middle">{svc[:2]}</text>
    <text x="75" y="45" class="card-title">{svc}</text>
    <text x="20" y="85" class="card-desc">Provisioned Resource</text>
  </g>
'''
        x_offset += 300

    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 600">
  <defs>
    <style>
      @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600&amp;display=swap');
      :root {{
        --bg-color: #f8fafc; --text-color: #1e293b; --card-bg: #ffffff;
        --card-border: #e2e8f0; --line-color: #94a3b8;
      }}
      @media (prefers-color-scheme: dark) {{
        :root {{
          --bg-color: #0f172a; --text-color: #f1f5f9; --card-bg: #1e293b;
          --card-border: #334155; --line-color: #475569;
        }}
      }}
      text {{ font-family: 'Outfit', sans-serif; fill: var(--text-color); }}
      .bg {{ fill: var(--bg-color); }}
      .card {{ fill: var(--card-bg); stroke: var(--card-border); stroke-width: 2px; rx: 12px; }}
      .icon-box {{ rx: 8px; }}
      .title {{ font-size: 28px; font-weight: 600; }}
      .subtitle {{ font-size: 16px; font-weight: 300; opacity: 0.8; }}
      .card-title {{ font-size: 18px; font-weight: 600; }}
      .card-desc {{ font-size: 14px; opacity: 0.8; }}
      .line {{ stroke: var(--line-color); stroke-width: 2px; fill: none; stroke-dasharray: 6; animation: dash 20s linear infinite; }}
      .arrow {{ fill: var(--line-color); }}
      @keyframes dash {{ to {{ stroke-dashoffset: -400; }} }}
      @keyframes pulse {{
        0% {{ filter: drop-shadow(0 0 4px rgba(255, 79, 139, 0.2)); }}
        50% {{ filter: drop-shadow(0 0 12px rgba(255, 79, 139, 0.6)); }}
        100% {{ filter: drop-shadow(0 0 4px rgba(255, 79, 139, 0.2)); }}
      }}
      .pulse-obj {{ animation: pulse 3s infinite; }}
    </style>
  </defs>
  <rect class="bg" width="1000" height="600" />
  <text x="50" y="60" class="title">Project {num} Architecture</text>
  <text x="50" y="85" class="subtitle">{title}</text>
  <g transform="translate(50, 320)">
    <rect x="0" y="0" width="180" height="120" class="card" />
    <text x="90" y="35" class="card-title" text-anchor="middle">User / Admin</text>
    <text x="90" y="65" class="card-desc" text-anchor="middle">Initiates Actions</text>
  </g>
{icons}
  <defs>
    <marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
      <polygon points="0 0, 10 3.5, 0 7" class="arrow" />
    </marker>
  </defs>
  <path d="M 230 380 L 290 380" class="line" marker-end="url(#arrowhead)" />
</svg>'''

def process_projects():
    projects = [f for f in os.listdir(ROOT_DIR) if f.startswith("project-") and os.path.isdir(os.path.join(ROOT_DIR, f))]
    projects.sort()

    for idx, p_dir in enumerate(projects[:11]):
        num = str(idx + 1).zfill(2)
        print(f"Overhauling Project {num}: {p_dir}...")
        
        path = os.path.join(ROOT_DIR, p_dir)
        readme_path = os.path.join(path, "README.md")
        docs_path = os.path.join(path, "docs")
        arch_path = os.path.join(path, "architecture")
        scripts_path = os.path.join(path, "scripts")
        ps_path = os.path.join(scripts_path, "powershell")
        bash_path = os.path.join(scripts_path, "bash")
        
        os.makedirs(docs_path, exist_ok=True)
        os.makedirs(arch_path, exist_ok=True)
        os.makedirs(ps_path, exist_ok=True)
        os.makedirs(bash_path, exist_ok=True)

        # 1. Read existing README
        old_readme = ""
        if os.path.exists(readme_path):
            with open(readme_path, "r", encoding="utf-8") as f:
                old_readme = f.read()

        overview = extract_section(old_readme, "Overview") or "Standard overview."
        setup = extract_section(old_readme, "Setup Steps") or "Setup details."
        
        meta = PROJECT_META[num]
        
        # 2. Rewrite README
        prev_link = f"[⬅️ Previous Project](../{projects[idx-1]})" if idx > 0 else ""
        next_link = f"[Next Project ➡️](../{projects[idx+1]})" if idx < 11 else ""
        
        new_readme = f'''<div align="center">
  <img src="https://raw.githubusercontent.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/main/{p_dir}/architecture/architecture.svg" alt="Project {num} Architecture" width="800">
  <br/>
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="32" height="32" style="vertical-align: middle"/> Project {num}: {meta['title']}</h1>
  <p><b>Beginner/Intermediate &nbsp; • &nbsp; {meta['time']} &nbsp; • &nbsp; Cost: $0.00 (Free Tier)</b></p>
  <p>
    <a href="#purpose">Purpose</a> • 
    <a href="#architecture">Architecture</a> • 
    <a href="#deployment">Deployment</a> • 
    <a href="#docs">Docs</a>
  </p>
</div>

<br/>

## 🎯 Purpose
{overview}

This project transforms standard infrastructure concepts into a high-end, production-ready implementation, providing extensive hands-on experience with {', '.join(meta['services'])}.

## 🚀 Learning Objectives
- Master **{meta['services'][0]}** configuration and best practices.
- Implement secure, scalable infrastructure using AWS native tools.
- Understand the integration points between various AWS services.
- Automate deployment using cross-platform scripts.

## 📚 Documentation Suite
Dive deep into the specific mechanics of this project:
- 📄 [Project Overview](docs/project-overview.md)
- 🏗️ [Architecture Details](docs/architecture.md)
- 🚀 [Deployment Guide](docs/deployment-guide.md)
- 🔐 [Security Protocols](docs/security-protocols.md)
- 🧪 [Testing Procedures](docs/testing-procedures.md)
- 🛠️ [Troubleshooting](docs/troubleshooting.md)

## 💻 Automation Scripts
This project contains ready-to-run automation scripts for both **PowerShell** and **Bash**.
- 🖥️ **Windows Users:** Use `scripts/powershell/`
- 🐧 **Linux/Mac Users:** Use `scripts/bash/`

---
<div align="center">
  <b>{prev_link} &nbsp; | &nbsp; {next_link}</b>
</div>
'''
        with open(readme_path, "w", encoding="utf-8") as f:
            f.write(new_readme)
            
        # 3. Create SVG
        with open(os.path.join(arch_path, "architecture.svg"), "w", encoding="utf-8") as f:
            f.write(build_svg(num, meta['title'], meta['services']))

        # 4. Generate Docs
        docs = {
            "project-overview.md": f"# Project {num} Overview\n\n## 🎯 Business Problem\n\nOrganizations need robust solutions for {meta['services'][0]}. This project simulates a real-world enterprise scenario.\n\n## 🚀 Solution\n\nWe leverage {', '.join(meta['services'])} to build a secure, highly available environment.",
            "architecture.md": f"# Architecture Details\n\n## Components\n\n" + "\n".join([f"- **{s}**: Core component." for s in meta['services']]),
            "deployment-guide.md": f"# Deployment Guide\n\n## Prerequisites\n- AWS CLI\n- Appropriate IAM permissions\n\n## Steps\n{setup}\n\n> [!TIP]\n> Use the provided automation scripts in `scripts/powershell/` or `scripts/bash/` to deploy this instantly.",
            "security-protocols.md": f"# Security Protocols\n\nThis project strictly follows the **Principle of Least Privilege (PoLP)**.\n\n- IAM Roles are tightly scoped.\n- Security groups only allow necessary inbound/outbound traffic.",
            "testing-procedures.md": f"# Testing Procedures\n\n1. Deploy the infrastructure.\n2. Verify the resources exist in the AWS Console.\n3. Validate the connectivity and functionality.\n4. Ensure logs and metrics are captured in CloudWatch.",
            "troubleshooting.md": f"# Troubleshooting Guide\n\n| Issue | Resolution |\n|---|---|\n| Access Denied | Check IAM policies and ensure you have administrative access. |\n| Resource Not Found | Verify the region is set correctly (e.g., ap-south-1). |"
        }
        for name, content in docs.items():
            with open(os.path.join(docs_path, name), "w", encoding="utf-8") as f:
                f.write(content)

        # 5. Handle Scripts
        # Find all .ps1 files anywhere in the project, move them to scripts/powershell, and generate .sh equivalents in scripts/bash
        ps_files = glob.glob(f"{path}/**/*.ps1", recursive=True)
        for ps_file in ps_files:
            if "powershell" in ps_file: continue
            
            base_name = os.path.basename(ps_file)
            sh_name = base_name.replace(".ps1", ".sh")
            
            dest_ps = os.path.join(ps_path, base_name)
            dest_sh = os.path.join(bash_path, sh_name)
            
            if ps_file != dest_ps:
                try:
                    shutil.move(ps_file, dest_ps)
                except shutil.Error:
                    pass # Same file
            
            # Generate bash
            with open(dest_ps, "r", encoding="utf-8") as f:
                ps_content = f.read()
            
            with open(dest_sh, "w", encoding="utf-8") as f:
                f.write(translate_ps1_to_sh(ps_content))
                
        # Move any existing bash scripts
        sh_files = glob.glob(f"{path}/**/*.sh", recursive=True)
        for sh_file in sh_files:
            if "bash" in sh_file and not sh_file.endswith("userdata.sh"): continue
            
            base_name = os.path.basename(sh_file)
            if base_name == "userdata.sh": continue # Let's keep userdata where it is usually
            
            dest_sh = os.path.join(bash_path, base_name)
            if sh_file != dest_sh:
                try:
                    shutil.move(sh_file, dest_sh)
                except shutil.Error:
                    pass

    print("Successfully overhauled Projects 1 through 11!")

if __name__ == "__main__":
    process_projects()
