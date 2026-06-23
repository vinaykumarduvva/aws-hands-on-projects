
---

# architecture.md

```markdown
# Architecture Design

## Components

### EC2 Application Server

- Amazon Linux 2023
- Public subnet
- Public IP enabled
- MySQL client installed

### Amazon RDS MySQL

- db.t3.micro
- Private subnet deployment
- Automated backups enabled
- No public accessibility

### Security Groups

EC2 Security Group

- SSH 22 from My IP
- HTTP 80 from Internet

RDS Security Group

- MySQL 3306 from EC2 Security Group only

## Security Design

Internet
→ EC2
→ RDS

Direct Internet
✗ RDS Access Blocked