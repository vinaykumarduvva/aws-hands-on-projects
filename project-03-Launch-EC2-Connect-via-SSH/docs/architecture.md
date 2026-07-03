# Architecture

## Architecture

```
Your Windows PC
      │
      ├── PuTTY SSH (port 22, your IP only) ────────┐
      │                                              │
      └── SSM Session Manager (HTTPS, no open port) ┤
                                                     ▼
                                      ┌──────────────────────────┐
                                      │   EC2 Instance           │
                                      │   Amazon Linux 2023      │
                                      │   t2.micro (1vCPU, 1GB)  │
                                      │   us-east-1              │
                                      │                          │
                                      │   Security Group         │
                                      │   ├── Port 22 → My IP    │
                                      │   └── Port 80 → 0.0.0.0  │
                                      │                          │
                                      │   Apache Web Server      │
                                      │   /var/www/html/         │
                                      └──────────────────────────┘
                                                     │
                                                     ▼
                                          Browser → http://PUBLIC_IP
```

---