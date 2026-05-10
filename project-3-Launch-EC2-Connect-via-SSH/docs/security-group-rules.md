
## Security Group Rules

Group name: `ec2-web-sg`

| Direction | Port | Protocol | Source | Purpose |
|---|---|---|---|---|
| Inbound | 22 | TCP | My IP /32 | SSH via PuTTY |
| Inbound | 80 | TCP | 0.0.0.0/0 | Apache web server |
| Outbound | All | All | 0.0.0.0/0 | Default allow all |

**Key concept — security groups are stateful:**
Only inbound rules are needed. Return traffic for established
connections is automatically allowed without an explicit
outbound rule. This is different from network ACLs (stateless).

---