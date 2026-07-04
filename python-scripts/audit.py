import os

root_dir = r"e:\AWS Hands-on Projects"
projects = [f for f in os.listdir(root_dir) if f.startswith("project-") and os.path.isdir(os.path.join(root_dir, f))]
projects.sort()

print("Project Audit:")
for proj in projects:
    proj_path = os.path.join(root_dir, proj)
    print(f"\n--- {proj} ---")
    dirs = [d for d in os.listdir(proj_path) if os.path.isdir(os.path.join(proj_path, d))]
    files = [f for f in os.listdir(proj_path) if os.path.isfile(os.path.join(proj_path, f))]
    print(f"Dirs: {dirs}")
    if 'screenshots' in dirs:
        print("  -> Has screenshots folder (needs to be images/)")
    if 'images' in dirs:
        print("  -> Has images folder")
    
    arch_dir = None
    if 'architecture' in dirs:
        arch_dir = os.path.join(proj_path, 'architecture')
    elif 'diagrams' in dirs:
        arch_dir = os.path.join(proj_path, 'diagrams')
    
    if arch_dir:
        svgs = [s for s in os.listdir(arch_dir) if s.endswith('.svg')]
        print(f"  -> SVGs found: {len(svgs)} ({svgs})")
    else:
        print("  -> NO architecture/diagrams directory!")
