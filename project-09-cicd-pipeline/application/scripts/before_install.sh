#!/bin/bash
set -e
echo "=== BeforeInstall Hook ==="
echo "Stopping Apache if running..."
systemctl stop httpd 2>/dev/null || true

echo "Installing Apache if not present..."
yum install -y httpd 2>/dev/null || true

echo "Cleaning old deployment..."
rm -f /var/www/html/index.html
rm -f /var/www/html/build-info.txt

echo "BeforeInstall complete"
