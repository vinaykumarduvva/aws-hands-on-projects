#!/bin/bash
# =============================================================================
# Project 7 — Script 06: Generate CPU Load
# Run this INSIDE the EC2 instance via SSH to trigger the CPU alarm
# =============================================================================
# SSH command: ssh -i aws-ec2-keypair.pem ec2-user@YOUR_PUBLIC_IP
# Then run: bash 06-generate-cpu-load.sh
# =============================================================================

echo "=== Project 7 — CPU Load Generator ==="
echo ""
echo "Purpose: Push CPU above 70% for 2 consecutive 5-minute periods"
echo "This triggers the EC2-CPU-High CloudWatch alarm."
echo ""
echo "The alarm requires 2 x 5-minute periods above 70% = 10 minutes minimum."
echo "We run stress for 12 minutes to guarantee two full evaluation windows."
echo ""

# Install stress if not already present
if ! command -v stress &> /dev/null; then
    echo "Installing stress tool..."
    sudo yum install -y stress -q
    echo "stress installed."
fi

echo "Current CPU usage (before stress):"
top -bn1 | grep "Cpu(s)" | awk '{print "  " $0}'
echo ""

echo "Starting CPU stress — 1 core for 720 seconds (12 minutes)..."
echo "Watch: CloudWatch -> Alarms -> EC2-CPU-High (updates every 5 min)"
echo ""
echo "To monitor progress from a second SSH session:"
echo "  watch -n 5 'top -bn1 | grep Cpu'"
echo ""
echo "Expected alarm timeline:"
echo "  0:00  — stress starts, CPU hits ~100%"
echo "  5:00  — first evaluation period completes (breach #1)"
echo "  10:00 — second evaluation period completes (breach #2) -> ALARM fires"
echo "  10:00 — SNS email sent to your inbox"
echo "  12:00 — stress stops, CPU returns to baseline"
echo "  17:00 — alarm transitions OK -> SNS recovery email sent"
echo ""

# Run stress for 720 seconds (12 minutes)
sudo stress --cpu 1 --timeout 720 &
STRESS_PID=$!

echo "Stress process started (PID: $STRESS_PID)"
echo ""

# Show live CPU every 60 seconds while stress runs
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    sleep 60
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | tr -d '%us,')
    echo "  Minute $i — CPU utilization: ${CPU}%"
done

echo ""
echo "Stress complete. CPU returning to baseline."
echo ""
echo "Check CloudWatch in 5-10 minutes for alarm state transition."
echo "Check your email for the alarm notification."