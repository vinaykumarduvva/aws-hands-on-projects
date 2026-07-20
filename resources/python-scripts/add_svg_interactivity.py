import os
import glob
import re

CSS_INJECT = """
  <style>
    /* Injected Interactive Styles */
    svg {
      --transition-speed: 0.3s;
    }
    rect, circle, polygon {
      transition: transform var(--transition-speed) ease, filter var(--transition-speed) ease, fill var(--transition-speed) ease;
      transform-origin: center;
      transform-box: fill-box;
    }
    rect:hover, circle:hover, polygon:hover {
      filter: drop-shadow(0px 8px 16px rgba(0,0,0,0.25)) brightness(1.05);
      transform: scale(1.02);
      cursor: pointer;
    }
    line, path {
      transition: stroke-width var(--transition-speed) ease, stroke var(--transition-speed) ease, filter var(--transition-speed) ease;
    }
    line:hover, path:hover {
      stroke-width: 3px;
      filter: drop-shadow(0px 2px 4px rgba(0,0,0,0.3));
      cursor: pointer;
    }
    text {
      pointer-events: none;
      transition: fill 0.3s ease;
    }
    @keyframes float {
      0% { transform: translateY(0px); }
      50% { transform: translateY(-4px); }
      100% { transform: translateY(0px); }
    }
    @keyframes pulse {
      0% { filter: drop-shadow(0 0 0 rgba(26,115,232,0.4)); }
      50% { filter: drop-shadow(0 0 12px rgba(26,115,232,0.8)); }
      100% { filter: drop-shadow(0 0 0 rgba(26,115,232,0.4)); }
    }
  </style>
"""

workspace = r"e:\AWS Hands-on Projects"

for i in range(1, 11):
    project_pattern = f"project-{i:02d}-*"
    search_path = os.path.join(workspace, project_pattern, "architecture", "*.svg")
    files = glob.glob(search_path)
    
    for file in files:
        with open(file, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Avoid double injection
        if "/* Injected Interactive Styles */" in content:
            print(f"Skipping {file}, already modified.")
            continue
            
        # Try to find </defs> and inject before it
        if "</defs>" in content:
            content = content.replace("</defs>", f"{CSS_INJECT}\n  </defs>")
        else:
            # Find the closing > of the <svg ...> tag
            match = re.search(r'<svg[^>]*>', content)
            if match:
                svg_tag = match.group(0)
                content = content.replace(svg_tag, f"{svg_tag}\n  <defs>{CSS_INJECT}  </defs>")
            else:
                print(f"Warning: Could not find <svg> tag in {file}")
                continue
                
        with open(file, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Modified {file}")

print("Done.")
