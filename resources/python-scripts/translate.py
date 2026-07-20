import os
import re
import glob

def convert_ps_to_sh(ps_content):
    lines = ps_content.split('\n')
    sh_lines = ['#!/bin/bash', '']
    
    for line in lines:
        if line.strip().startswith('Write-Host'):
            # Convert Write-Host
            color_map = {
                'Green': '\\e[32m',
                'Yellow': '\\e[33m',
                'Red': '\\e[31m',
                'Cyan': '\\e[36m',
                'White': '\\e[97m',
                'Gray': '\\e[90m'
            }
            color_match = re.search(r'-ForegroundColor\s+(\w+)', line)
            text_match = re.search(r'Write-Host\s+(".*?")', line)
            if not text_match:
                text_match = re.search(r'Write-Host\s+(\'.*?\')', line)
                
            text = text_match.group(1) if text_match else '""'
            
            if color_match and color_match.group(1) in color_map:
                color_code = color_map[color_match.group(1)]
                text = text.strip('"\'')
                # Add quotes back safely
                new_line = f'echo -e "{color_code}{text}\\e[0m"'
            else:
                text = text.strip('"\'')
                new_line = f'echo "{text}"'
            
            # replace formatting in text
            new_line = new_line.replace('`n', '\\n')
            sh_lines.append(new_line)
            continue
            
        # Convert Start-Sleep
        if 'Start-Sleep -Seconds' in line:
            new_line = re.sub(r'Start-Sleep\s+-Seconds\s+(\d+)', r'sleep \1', line)
            sh_lines.append(new_line)
            continue
            
        # Convert Get-Date
        if 'Get-Date -Format' in line:
            new_line = re.sub(r'Get-Date -Format\s+[\'"](.*?)[\'"]', r'date +"%T"', line) # Simplification for time formatting
            sh_lines.append(new_line)
            continue
            
        # Line continuations
        line = line.replace('`', '\\')
        
        # $null
        line = line.replace('2>$null', '2>/dev/null')
        line = line.replace('>$null', '>/dev/null')
        
        # Array access like ($INSTANCE_IDS -split '\s+')[0]
        if "-split '\\s+'" in line:
            line = line.replace("-split '\\s+'", "")
            line = line.replace(")[0]", "| awk '{print $1}')")
            line = line.replace("($", "$(")
            
        # Variable assignments: $VAR = aws ... -> VAR=$(aws ...)
        assign_match = re.match(r'^(\s*)\$(\w+)\s*=\s*(.*)', line)
        if assign_match:
            indent, var_name, rhs = assign_match.groups()
            rhs = rhs.strip()
            
            # If it's a command substitution
            if rhs.startswith('aws ') or rhs.startswith('Invoke-WebRequest'):
                if rhs.startswith('Invoke-WebRequest'):
                    rhs = rhs.replace('Invoke-WebRequest -Uri', 'curl -s')
                    rhs = rhs.replace('-UseBasicParsing', '')
                    rhs = re.sub(r'\)\.Content\.Trim\(\)', '', rhs)
                    rhs = re.sub(r'\.Content\.Trim\(\)', '', rhs)
                    
                new_line = f'{indent}{var_name}=$({rhs}'
                
                # Check if it was a multi-line command with line continuation
                if new_line.endswith('\\'):
                    pass # The closing bracket ) needs to go at the very end of the statement
                else:
                    new_line += ')'
                sh_lines.append(new_line)
                continue
            else:
                new_line = f'{indent}{var_name}={rhs}'
                sh_lines.append(new_line)
                continue
        
        # Catch closing parenthesis for multiline assignments
        if line.strip() == '' and len(sh_lines) > 0 and sh_lines[-1].endswith('\\'):
            pass
            
        # Close bash command substitution if needed
        # We need a robust way to close command substitution for multi-line.
        # This script does a basic first pass. We will manually fix complex ones.
            
        sh_lines.append(line)
        
    # Second pass for multiline command substitutions
    final_lines = []
    in_cmd_sub = False
    for line in sh_lines:
        if re.search(r'^\s*\w+=\$\(', line) and line.endswith('\\'):
            in_cmd_sub = True
            final_lines.append(line)
        elif in_cmd_sub:
            if not line.endswith('\\') and line.strip() != '':
                final_lines.append(line + ')')
                in_cmd_sub = False
            else:
                final_lines.append(line)
        else:
            final_lines.append(line)
            
    # Third pass to fix ConvertFrom-Json -> jq
    out_lines = []
    for line in final_lines:
        if 'ConvertFrom-Json' in line:
            line = line.replace('| ConvertFrom-Json', '| jq .')
        if '$asg.Instances.Count' in line:
            line = line.replace('$asg.Instances.Count', '$(echo $asg | jq ".Instances | length")')
        if '$asg.Desired' in line:
            line = line.replace('$asg.Desired', '$(echo $asg | jq -r ".Desired")')
        out_lines.append(line)

    return '\n'.join(out_lines)

def main():
    root_dir = r"e:\AWS Hands-on Projects"
    search_pattern = os.path.join(root_dir, "project-*", "scripts", "*.ps1")
    
    ps_files = glob.glob(search_pattern)
    print(f"Found {len(ps_files)} PowerShell scripts.")
    
    for ps_path in ps_files:
        project_dir = os.path.dirname(os.path.dirname(ps_path))
        bash_dir = os.path.join(project_dir, 'bash-scripts')
        
        if not os.path.exists(bash_dir):
            os.makedirs(bash_dir)
            print(f"Created directory: {bash_dir}")
            
        filename = os.path.basename(ps_path)
        sh_filename = filename.replace('.ps1', '.sh')
        sh_path = os.path.join(bash_dir, sh_filename)
        
        with open(ps_path, 'r', encoding='utf-8') as f:
            ps_content = f.read()
            
        sh_content = convert_ps_to_sh(ps_content)
        
        with open(sh_path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(sh_content)
            
        print(f"Converted {filename} -> {sh_filename}")

if __name__ == "__main__":
    main()
