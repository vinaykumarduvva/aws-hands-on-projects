import os
import glob
import re

ROOT_DIR = r"e:\AWS Hands-on Projects"

def fix_images():
    for num in range(1, 13):
        # Find project dir
        proj_dirs = glob.glob(os.path.join(ROOT_DIR, f"project-{num:02d}-*"))
        if not proj_dirs:
            continue
        proj_dir = proj_dirs[0]
        arch_dir = os.path.join(proj_dir, "architecture")
        
        # Find all svgs
        svgs = glob.glob(os.path.join(arch_dir, "*.svg"))
        if not svgs:
            continue
            
        # Determine the correct SVG
        correct_svg = None
        other_svgs = [s for s in svgs if os.path.basename(s) != "architecture.svg"]
        if other_svgs:
            correct_svg = other_svgs[0]
            # Optionally remove the generated architecture.svg
            gen_svg = os.path.join(arch_dir, "architecture.svg")
            if os.path.exists(gen_svg) and os.path.exists(correct_svg):
                os.remove(gen_svg)
        else:
            correct_svg = svgs[0]
            
        svg_basename = os.path.basename(correct_svg)
        
        readme_path = os.path.join(proj_dir, "README.md")
        if os.path.exists(readme_path):
            with open(readme_path, "r", encoding="utf-8") as f:
                content = f.read()
                
            # Replace the image src in the README
            # E.g., src="./architecture/architecture.svg" -> src="./architecture/my-svg.svg"
            content = re.sub(r'src="\./architecture/[^"]+\.svg"', f'src="./architecture/{svg_basename}"', content)
            
            with open(readme_path, "w", encoding="utf-8", newline="\n") as f:
                f.write(content)
            print(f"Fixed {readme_path} to use {svg_basename}")

if __name__ == "__main__":
    fix_images()
