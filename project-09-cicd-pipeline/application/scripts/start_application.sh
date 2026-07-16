#!/bin/bash
set -e
echo "=== ApplicationStart Hook ==="
echo "Starting Apache web server..."
systemctl start httpd
systemctl enable httpd

echo "Apache status:"
systemctl status httpd --no-pager

echo "ApplicationStart complete"
