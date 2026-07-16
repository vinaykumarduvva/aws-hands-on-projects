# appspec.yml Explained

`appspec.yml` is the CodeDeploy deployment manifest. It tells the CodeDeploy agent on EC2 exactly:
- Which files to copy and where to put them
- What permissions to set on those files
- Which scripts to run at each deployment lifecycle stage

Without `appspec.yml`, CodeDeploy does not know what to do and the deployment fails immediately.

---

## 📂 File Location

```text
my-web-app/
├── index.html
├── buildspec.yml
├── appspec.yml        ← CodeDeploy reads this
└── scripts/
    ├── before_install.sh
    ├── after_install.sh
    ├── start_application.sh
    └── validate_service.sh
```

> [!WARNING]
> `appspec.yml` must be in the ROOT of the deployment artifact. Our `buildspec.yml` copies it to `dist/` which becomes the root of the `BuildOutput` ZIP.

---

## 📝 Full appspec.yml with Annotations

```yaml
# AppSpec format version — always 0.0 for EC2/on-premises
version: 0.0

# Target operating system
# linux = Amazon Linux, Ubuntu, RHEL, etc.
# windows = Windows Server
os: linux

# ── FILES SECTION ─────────────────────────────────────────────────
# Defines which files to copy from artifact to EC2
# CodeDeploy extracts the ZIP and copies these files
files:
  - source: /index.html
    # source: path in the artifact ZIP (relative to artifact root)
    # /index.html = the file at the root of BuildOutput.zip

    destination: /var/www/html/
    # destination: absolute path on the EC2 instance
    # /var/www/html/ = Apache's default web root

  - source: /build-info.txt
    destination: /var/www/html/
    # Deploys build metadata alongside the app
    # Accessible at http://EC2_IP/build-info.txt

# ── PERMISSIONS SECTION ───────────────────────────────────────────
# Sets file ownership and permissions after copy
# If omitted, files are owned by root with original permissions
permissions:
  - object: /var/www/html/
    # object: the path to apply permissions to

    pattern: "**"
    # pattern: which files to apply to
    # ** = all files recursively
    # *.html = only HTML files

    owner: apache
    # File owner (user) — apache is the httpd user on Amazon Linux

    group: apache
    # File group — apache group on Amazon Linux

    mode: 644
    # Unix permission bits:
    # 6 = rw- (owner: read+write)
    # 4 = r-- (group: read only)
    # 4 = r-- (others: read only)
    # Apache needs read permission to serve files

    type:
      - file
      # Apply this permission only to files (not directories)
      # Use "directory" for directory permissions

# ── HOOKS SECTION ─────────────────────────────────────────────────
# Lifecycle event hooks — scripts that run at specific points
# Each hook runs as a separate shell process on EC2
hooks:

  # ── BEFORE INSTALL ──────────────────────────────────────────────
  # Runs BEFORE CodeDeploy copies files from artifact
  # Use for: Stop old app, clean old files, install dependencies
  BeforeInstall:
    - location: scripts/before_install.sh
      # location: path to script INSIDE the deployment artifact
      # (not an absolute path on EC2)

      timeout: 60
      # How many seconds before CodeDeploy kills the script
      # Default: 3600 (1 hour) — always set explicitly

      runas: root
      # Which user runs this script
      # root = full system privileges (needed for yum, systemctl)

  # ── AFTER INSTALL ───────────────────────────────────────────────
  # Runs AFTER files are copied to EC2
  # Use for: Set permissions, configure app, create symlinks
  AfterInstall:
    - location: scripts/after_install.sh
      timeout: 60
      runas: root

  # ── APPLICATION START ────────────────────────────────────────────
  # Runs after AfterInstall
  # Use for: Start web server, start application process
  ApplicationStart:
    - location: scripts/start_application.sh
      timeout: 60
      runas: root

  # ── VALIDATE SERVICE ─────────────────────────────────────────────
  # Runs last — validates the deployment succeeded
  # Use for: Health checks, smoke tests
  # If this fails → deployment FAILS → auto-rollback can trigger
  ValidateService:
    - location: scripts/validate_service.sh
      timeout: 60
      runas: root
```

---

## 🔄 The 7 Lifecycle Event Hooks (Full List)

CodeDeploy supports 7 lifecycle hooks for EC2 deployments. We used 4. Here is the complete list in execution order:

```text
ApplicationStop
      ↓
DownloadBundle         ← CodeDeploy downloads artifact from S3
      ↓
BeforeInstall          ← We use this
      ↓
Install                ← CodeDeploy copies files (appspec files: section)
      ↓
AfterInstall           ← We use this
      ↓
ApplicationStart       ← We use this
      ↓
ValidateService        ← We use this
```

### Hooks we did NOT use

| Hook | When it runs | Typical use |
| --- | --- | --- |
| ApplicationStop | Before download | Gracefully stop running application |
| DownloadBundle | While downloading | Cannot use custom scripts here |
| Install | While copying files | Cannot use custom scripts here |

---

## 📜 Deployment Hook Scripts Explained

### before_install.sh

```bash
#!/bin/bash
set -e
# set -e = exit immediately if any command fails
# Essential for deployment scripts — prevents partial deployments

echo "=== BeforeInstall Hook ==="

# Stop Apache gracefully (2>/dev/null = hide error if not running)
# || true = don't fail if Apache isn't running yet
systemctl stop httpd 2>/dev/null || true

# Install Apache if not present
# -y = yes to all prompts (non-interactive)
yum install -y httpd 2>/dev/null || true

# Remove old deployed files
# This ensures clean deployment — no old files left over
rm -f /var/www/html/index.html
rm -f /var/www/html/build-info.txt

echo "BeforeInstall complete"
```

### after_install.sh

```bash
#!/bin/bash
set -e
echo "=== AfterInstall Hook ==="

# Set Apache as owner of web files
# Apache process runs as 'apache' user and needs to read files
chown -R apache:apache /var/www/html/

# Set correct file permissions
# 644 = owner read+write, group read, others read
chmod 644 /var/www/html/index.html 2>/dev/null || true
chmod 644 /var/www/html/build-info.txt 2>/dev/null || true

# Log build info for debugging
if [ -f /var/www/html/build-info.txt ]; then
  echo "Build info:"
  cat /var/www/html/build-info.txt
fi

echo "AfterInstall complete"
```

### start_application.sh

```bash
#!/bin/bash
set -e
echo "=== ApplicationStart Hook ==="

# Start Apache web server
systemctl start httpd

# Enable Apache to start automatically on EC2 reboot
systemctl enable httpd

# Log status to build logs
echo "Apache status:"
systemctl status httpd --no-pager
# --no-pager outputs all status without requiring key press

echo "ApplicationStart complete"
```

### validate_service.sh

```bash
#!/bin/bash
set -e
echo "=== ValidateService Hook ==="

# Give Apache a moment to fully start
sleep 3

# Check Apache is running
# systemctl is-active returns 0 if active, non-zero otherwise
systemctl is-active httpd || exit 1
# || exit 1 = if not active, fail the deployment

# Make HTTP request to localhost and check response code
# curl flags:
#   -s = silent (no progress bar)
#   -o /dev/null = discard response body
#   -w "%{http_code}" = print only the HTTP status code
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)

if [ "$RESPONSE" = "200" ]; then
  echo "Validation passed — HTTP 200 received"
  # exit 0 = success (implicit)
else
  echo "Validation FAILED — HTTP $RESPONSE received"
  exit 1  # non-zero exit = ValidateService FAILED = deployment FAILED
fi

echo "ValidateService complete — deployment successful!"
```

---

## ❌ What Happens When a Hook Fails

```text
ValidateService returns exit code 1
              │
              ▼
CodeDeploy marks hook: FAILED
              │
              ▼
Deployment status: FAILED
              │
              ▼ (if auto-rollback enabled)
CodeDeploy re-deploys last successful revision
              │
              ▼
Previous version restored on EC2
              │
              ▼
Pipeline stage: Deploy → FAILED (red)
```

---

## ✅ appspec.yml Validation Checklist

Before pushing, verify:

```bash
# 1. appspec.yml is in repo root
ls appspec.yml

# 2. YAML is valid syntax (no tabs, correct indentation)
python -c "import yaml; yaml.safe_load(open('appspec.yml'))"

# 3. All referenced scripts exist
ls scripts/before_install.sh
ls scripts/after_install.sh
ls scripts/start_application.sh
ls scripts/validate_service.sh

# 4. Scripts have correct line endings (Linux LF, not Windows CRLF)
file scripts/before_install.sh
# Should show: ASCII text (not ASCII text, with CRLF line terminators)

# Fix Windows line endings if needed:
sed -i 's/\r//' scripts/*.sh
```

---

## 🚨 Common appspec.yml Errors

| Error                              | Cause                              | Fix                                                             |
| ---------------------------------- | ---------------------------------- | --------------------------------------------------------------- |
| `AppSpec file not found`           | appspec.yml not at artifact root   | Verify buildspec copies it to dist/                             |
| `Script failed with exit code 1`   | Hook script error                  | SSH to EC2, check `/opt/codedeploy-agent/deployment-root/` logs |
| `Script failed with exit code 127` | Script not found or not executable | Check location path and script exists in artifact               |
| `Permission denied`                | Wrong runas user                   | Change `runas: root` for system operations                      |
| `Timeout`                          | Script took longer than `timeout`  | Increase timeout value or optimize script                       |
| `YAML parse error`                 | Tab characters or bad indentation  | Use spaces only, validate with `python -c "import yaml..."`     |
