# Troubleshooting Manual

## Troubleshooting

| Problem | Likely Cause | Fix |
|---|---|---|
| PuTTY — Connection refused | Instance not ready or port 22 blocked | Wait for 2/2 status checks; verify SG has port 22 rule |
| PuTTY — Connection timed out | Wrong IP or SG not attached | Check public IP in console; confirm ec2-web-sg is attached |
| PuTTY — No supported auth methods | Wrong key file | Re-browse to correct `.ppk` file in PuTTY Auth settings |
| Browser — Apache page not loading | Port 80 missing or Apache not started | Check SG inbound rules; SSH in and run `sudo systemctl start httpd` |
| SSM Connect button greyed out | Role not attached or agent not ready | Wait 5 min after attaching role |
| Public IP changed | Expected — dynamic IP on every start | Note new IP from console after each start; use Elastic IP to fix |

---