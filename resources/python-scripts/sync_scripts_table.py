import os
import glob
import re

ROOT_DIR = r"e:\AWS Hands-on Projects"

def format_description(filename):
    # Convert '01-create-stack.sh' to 'Create stack'
    name = filename.replace('.sh', '')
    # Remove leading numbers and hyphens
    name = re.sub(r'^\d+-+', '', name)
    # Replace remaining hyphens with spaces
    name = name.replace('-', ' ')
    # Capitalize the first letter
    return name.capitalize()

def update_readme_run_commands():
    for num in range(1, 13):
        # Find project dir
        proj_dirs = glob.glob(os.path.join(ROOT_DIR, f"project-{num:02d}-*"))
        if not proj_dirs:
            continue
        proj_dir = proj_dirs[0]
        readme_path = os.path.join(proj_dir, "README.md")
        bash_dir = os.path.join(proj_dir, "scripts", "bash")
        
        if not os.path.exists(readme_path) or not os.path.exists(bash_dir):
            continue
            
        # Get actual bash scripts, sorted alphabetically
        bash_scripts = sorted([os.path.basename(f) for f in glob.glob(os.path.join(bash_dir, "*.sh"))])
        
        if not bash_scripts:
            continue
            
        # Build the new table
        new_table_lines = ["<table>\n", "<tr><th>Step</th><th>Script</th><th>Description</th></tr>\n"]
        for script in bash_scripts:
            ps_script = script.replace(".sh", ".ps1")
            desc = format_description(script)
            new_table_lines.append(f"<tr><td>🐧</td><td><code>scripts/bash/{script}</code></td><td>Execute {desc}</td></tr>\n")
            new_table_lines.append(f"<tr><td>🖥️</td><td><code>scripts/powershell/{ps_script}</code></td><td>Execute {desc}</td></tr>\n")
        new_table_lines.append("</table>")
        new_table_str = "".join(new_table_lines)
        
        with open(readme_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Replace the old table with the new table
        # We find the table that immediately follows "### Run Commands"
        pattern = re.compile(r'(### Run Commands.*?)(<table>.*?</table>)', re.DOTALL)
        
        def replacer(match):
            return match.group(1) + new_table_str
            
        new_content = pattern.sub(replacer, content)
        
        if new_content != content:
            with open(readme_path, "w", encoding="utf-8", newline="\n") as f:
                f.write(new_content)
            print(f"Updated scripts table in {readme_path}")
        else:
            print(f"No changes needed or table not found in {readme_path}")

if __name__ == "__main__":
    update_readme_run_commands()
