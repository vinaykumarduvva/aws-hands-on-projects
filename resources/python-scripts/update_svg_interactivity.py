import os
import glob
import re

CSS_INJECT = """
  <linearGradient id="bg-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
    <stop offset="0%" stop-color="#f8f9fa" />
    <stop offset="100%" stop-color="#e2e8f0" />
  </linearGradient>
  <style>
    /* Injected Interactive Styles */
    svg {
      --transition-speed: 0.3s;
    }
    rect[fill="#f8f9fa"], rect[width="800"][height="500"], rect[width="860"][height="640"] {
      fill: url(#bg-gradient) !important;
    }
    rect, circle, polygon {
      transition: transform var(--transition-speed) cubic-bezier(0.175, 0.885, 0.32, 1.275), filter var(--transition-speed) ease, fill var(--transition-speed) ease;
      transform-origin: center;
      transform-box: fill-box;
    }
    rect:hover, circle:hover, polygon:hover {
      filter: drop-shadow(0px 8px 24px rgba(26, 115, 232, 0.5)) brightness(1.05);
      transform: scale(1.05);
      cursor: pointer;
    }
    line, path {
      transition: stroke-width var(--transition-speed) ease, stroke var(--transition-speed) ease, filter var(--transition-speed) ease;
    }
    line:hover, path:hover {
      stroke-width: 4px;
      filter: drop-shadow(0px 4px 12px rgba(255, 153, 0, 0.7));
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

# Regex to match the old block: from <style> with /* Injected Interactive Styles */ to </style>
old_style_regex = re.compile(r'<style>\s*/\*\s*Injected Interactive Styles\s*\*/.*?</style>', re.DOTALL)
gradient_regex = re.compile(r'<linearGradient id="bg-gradient".*?</linearGradient>', re.DOTALL)

for i in range(1, 11):
    project_pattern = f"project-{i:02d}-*"
    search_path = os.path.join(workspace, project_pattern, "architecture", "*.svg")
    files = glob.glob(search_path)
    
    for file in files:
        with open(file, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Clean up old injections
        content = old_style_regex.sub('', content)
        content = gradient_regex.sub('', content)
        
        # Inject new block
        if "</defs>" in content:
            content = content.replace("</defs>", f"{CSS_INJECT}\n  </defs>")
        else:
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
