# Security Protocols

This project implements a multi-layered security strategy, strictly following the **Principle of Least Privilege (PoLP)** and adhering to AWS Well-Architected Framework best practices for network security.

## 🛡️ Defense-in-Depth

We utilize two primary firewalls to protect our VPC:

### 1. Security Groups (Stateful, Instance-Level)
Security Groups act as virtual firewalls for your EC2 instances. They are **stateful**, meaning if you send a request from your instance, the response traffic for that request is automatically allowed to flow in regardless of inbound security group rules.

- **Bastion Security Group**: Allows inbound SSH (Port 22) *only* from your specific public IP address. All other internet traffic is dropped.
- **Private Security Group**: Allows inbound SSH (Port 22) *only* if the traffic originates from the Bastion Security Group. This ensures that even if a private instance were accidentally given a public IP, it would still drop direct internet SSH attempts.

### 2. Network ACLs (Stateless, Subnet-Level)
Network Access Control Lists (NACLs) act as a firewall for associated subnets, controlling both inbound and outbound traffic at the subnet boundary. 
They are **stateless**, meaning responses to allowed inbound traffic are subject to the rules for outbound traffic (and vice versa).
- In this project, we use the Default VPC NACL, which allows all inbound and outbound traffic. We rely on Security Groups for our strict filtering. 
- *Note for Production:* In highly secure environments, you would restrict NACLs to only allow necessary ports, making sure to explicitly open **ephemeral ports** (1024-65535) to allow return traffic to flow back to clients.

## 🏰 The Bastion Host Pattern

A **Bastion Host** (or Jump Box) is a special-purpose server configured to withstand attacks. It is placed in a Public Subnet and is the only instance exposed to the internet for administrative access.

**How it works:**
1. Administrators SSH into the Bastion Host using its Public IP.
2. From inside the Bastion Host terminal, the administrator initiates a second SSH connection to the Private IP of the target backend server.
3. Because the backend server's Security Group explicitly trusts the Bastion Host's Security Group, the connection is allowed.

This completely eliminates the need to put backend databases or application logic servers on the public internet, drastically reducing their attack surface.

## 🔑 Key Management

We use asymmetric RSA 2048-bit key pairs for SSH authentication. 
- To jump from the Bastion to the Private instance, you must either copy your `.pem` key temporarily to the Bastion (fine for testing) or utilize **SSH Agent Forwarding** (`ssh -A`) so your private key never leaves your local machine (required for production).
- We also demonstrate **AWS Systems Manager (SSM) Session Manager** as a modern alternative to SSH, which entirely eliminates the need for key pairs and open inbound ports by tunneling shell access through the SSM agent.