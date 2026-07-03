# Security Protocols & Compliance

Running virtual machines attached to the public internet is inherently dangerous. Bots scan the entire IPv4 address space continuously, looking for open ports and vulnerable software. This project implements multiple layers of defense to protect the EC2 instance.

---

## 🔐 1. Inbound Network Firewalls (Security Groups)

The primary defense mechanism is the Security Group.
- **Default Deny:** When a Security Group is created, it has zero inbound rules. All traffic is dropped silently at the hypervisor level.
- **Targeted Allow (Port 22):** SSH access is explicitly restricted to a single IP address (your local home/office IP) using CIDR notation (e.g., `192.168.1.100/32`). This means even if a hacker steals your `.pem` key, they cannot connect to the server unless they are physically on your Wi-Fi network.
- **Global Allow (Port 80):** Because this is a web server, HTTP traffic must be allowed from the entire internet (`0.0.0.0/0`). We rely on the Apache Web Server application layer to handle this traffic securely.

---

## 🛡️ 2. Cryptographic Authentication (Key Pairs)

Password authentication is disabled by default on Amazon Linux AMIs.
- We utilize **Asymmetric RSA Cryptography**.
- The public key is stored in AWS and injected into the instance at boot.
- The private key (`.pem`) is stored locally.
- **File Permissions:** On Mac and Linux, the SSH client strictly enforces permissions on the private key file. If the `.pem` file is readable by other users on your local machine (e.g., permissions `644`), the SSH client will refuse to use it and throw an `UNPROTECTED PRIVATE KEY FILE!` error. It must be locked down (e.g., `chmod 400`).

---

## 🚧 3. OS-Level Security & Bootstrapping

- **Package Updates:** The very first line of the User Data script is `yum update -y`. This ensures that before the server even finishes booting, it reaches out to the Amazon Linux repositories and downloads the latest security patches for the kernel and all installed software.
- **Root vs. Standard User:** When you connect via SSH, you log in as `ec2-user`. This is a standard, unprivileged user. To perform administrative tasks (like restarting Apache or viewing logs), you must explicitly elevate your privileges using `sudo` (Superuser Do). This prevents accidental system damage during routine administration.