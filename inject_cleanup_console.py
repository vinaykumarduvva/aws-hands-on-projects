import os
import glob
import re

workspace = r"e:\AWS Hands-on Projects"

def generate_ui_cleanup_steps():
    steps = """1. Log into the AWS Management Console and use the top search bar to navigate to the relevant service dashboard (e.g., EC2, VPC, S3, RDS).
2. Locate the resources you created for this project (refer to the `Resources to Delete` table above for the required deletion order).
3. Select each resource and click the primary **Delete**, **Terminate**, or **Empty** button.
4. In the confirmation dialog, type the required confirmation text (e.g., `delete`, `permanently delete`, or the resource name).
5. Click to finalize the deletion, and wait for the resource to completely disappear from the console list before moving to the next service."""
    return steps

for i in range(1, 13):
    project_pattern = f"project-{i:02d}-*"
    search_path = os.path.join(workspace, project_pattern, "docs", "cleanup-guide.md")
    files = glob.glob(search_path)
    
    for file in files:
        with open(file, "r", encoding="utf-8") as f:
            content = f.read()
            
        lines = content.split('\n')
        new_lines = []
        
        skip_next = False
        for idx, line in enumerate(lines):
            if skip_next:
                skip_next = False
                continue
                
            if line.strip() == "### 🖥️ Method 1: AWS Management Console":
                new_lines.append(line)
                # Next line might be the placeholder
                if idx + 1 < len(lines) and "*(Refer to " in lines[idx+1] and "UI cleanup steps)*" in lines[idx+1]:
                    new_lines.append(generate_ui_cleanup_steps())
                    skip_next = True
                elif idx + 1 < len(lines) and "*(Refer to the repository instructions or script comments for UI steps)*" in lines[idx+1]:
                    new_lines.append(generate_ui_cleanup_steps())
                    skip_next = True
                else:
                    pass
                continue
            
            new_lines.append(line)
            
        with open(file, "w", encoding="utf-8") as f:
            f.write('\n'.join(new_lines))
        print(f"Updated {file}")

print("Done.")
