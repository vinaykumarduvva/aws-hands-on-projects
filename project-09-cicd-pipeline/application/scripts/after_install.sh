#!/bin/bash
set -e
echo "=== AfterInstall Hook ==="
echo "Setting file permissions..."
chown -R apache:apache /var/www/html/
chmod 644 /var/www/html/index.html 2>/dev/null || true
chmod 644 /var/www/html/build-info.txt 2>/dev/null || true

# Display build info
if [ -f /var/www/html/build-info.txt ]; then
  echo "Build info:"
  cat /var/www/html/build-info.txt
fi

echo "AfterInstall complete"
