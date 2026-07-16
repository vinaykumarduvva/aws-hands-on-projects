#!/bin/bash
set -e
echo "=== ValidateService Hook ==="
echo "Waiting for Apache to be ready..."
sleep 3

echo "Checking Apache is running..."
systemctl is-active httpd || exit 1

echo "Checking web page is accessible..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
if [ "$RESPONSE" = "200" ]; then
  echo "Validation passed — HTTP 200 received"
else
  echo "Validation FAILED — HTTP $RESPONSE received"
  exit 1
fi

echo "ValidateService complete — deployment successful!"
