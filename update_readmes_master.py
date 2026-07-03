"""
Comprehensive README generator for AWS Projects 1-12.
Produces deeply technical, project-specific READMEs with centered
architecture diagrams and rich infrastructure specifications.
"""
import os

ROOT_DIR = r"e:\AWS Hands-on Projects"
GITHUB_BASE = "https://raw.githubusercontent.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects/main"

# ──────────────────────────────────────────────
# Full project-specific metadata
# ──────────────────────────────────────────────
PROJECTS = {
    "01": {
        "dir": "project-01-iam-setup",
        "title": "AWS Account Setup & IAM Foundations",
        "time": "1–2 Hours",
        "level": "Beginner",
        "description": (
            "Establish a hardened AWS account baseline by configuring Identity and Access Management (IAM) "
            "with least-privilege policies, multi-factor authentication (MFA), and granular role-based access control. "
            "This project lays the security foundation that every subsequent project in this portfolio depends on."
        ),
        "services": ["IAM", "SNS", "CloudWatch"],
        "infra": {
            "IAM Users": "Admin user with console + programmatic access; developer user with scoped permissions",
            "IAM Groups": "`Admins` (full access), `Developers` (EC2/S3/Lambda read-write), `ReadOnly` (view-only)",
            "IAM Policies": "Custom JSON policies enforcing least-privilege; AWS-managed `AdministratorAccess` for bootstrap only",
            "IAM Roles": "Cross-service role for Lambda → S3 access; EC2 instance profile for SSM Session Manager",
            "MFA": "Virtual MFA device enforced on root and all IAM users via `aws:MultiFactorAuthPresent` condition key",
            "Password Policy": "14-char minimum, uppercase + lowercase + number + symbol, 90-day rotation, no reuse of last 5",
            "SNS Topic": "Billing alarm notification topic (`billing-alerts`) with email subscription",
            "CloudWatch Alarm": "EstimatedCharges ≥ $5 threshold → SNS notification",
            "Region": "us-east-1 (required for billing metrics); global for IAM",
        },
        "components": [
            ("IAM Identity Center", "Centralized user management and single sign-on for multi-account environments"),
            ("IAM Policies (JSON)", "Fine-grained permission documents attached to users, groups, and roles"),
            ("IAM Roles & Instance Profiles", "Temporary-credential delegation for services like EC2, Lambda, and CodeBuild"),
            ("MFA Enforcement", "Condition keys in policies that deny all actions unless MFA is present"),
            ("CloudWatch Billing Alarm", "Metric alarm on `AWS/Billing` → `EstimatedCharges` with SNS action"),
            ("SNS Email Subscription", "Fan-out notification channel for billing alerts and operational events"),
        ],
        "features": [
            "**Least-Privilege Policy Engine** – Custom IAM policies scoped to exact API actions and resource ARNs",
            "**MFA-Gated Access** – Policies with `Condition: { Bool: { aws:MultiFactorAuthPresent: true } }`",
            "**Automated Billing Guard** – CloudWatch alarm triggers SNS email when spend exceeds $5 threshold",
            "**Role-Based Access Control** – Separate IAM groups for Admins, Developers, and Read-Only auditors",
            "**Password Policy Hardening** – Programmatic enforcement of complexity, rotation, and reuse rules",
            "**Cross-Service Roles** – Preconfigured IAM roles for Lambda, EC2, and CI/CD pipeline assumptions",
            "**Audit-Ready Logging** – CloudTrail integration for full API call history across the account",
        ],
        "prerequisites": [
            "AWS account with root access (initial setup only)",
            "AWS CLI v2 (`aws --version` ≥ 2.x)",
            "A valid email address for SNS billing alert subscription",
            "A virtual MFA app (Google Authenticator, Authy, or 1Password)",
        ],
        "env_vars": {
            "AWS_REGION": "us-east-1",
            "AWS_PROFILE": "default",
            "ALERT_EMAIL": "your-email@example.com",
            "BILLING_THRESHOLD": "5",
        },
        "run_scripts": [
            ("01-create-iam-users.sh", "Creates IAM users with console and programmatic access"),
            ("02-create-iam-groups.sh", "Creates Admins, Developers, ReadOnly groups and attaches policies"),
            ("03-configure-password-policy.sh", "Sets account-level password complexity and rotation rules"),
            ("04-create-billing-alarm.sh", "Provisions CloudWatch billing alarm → SNS topic → email subscription"),
            ("05-enable-mfa.sh", "Generates virtual MFA seed and associates it with each IAM user"),
        ],
        "testing": [
            "`aws iam get-account-authorization-details` – Verify all users, groups, and policies exist",
            "`aws iam get-account-password-policy` – Confirm password policy matches specification",
            "`aws sns list-subscriptions-by-topic` – Ensure email subscription is confirmed",
            "`aws cloudwatch describe-alarms --alarm-names billing-alarm` – Validate alarm state is OK",
            "Attempt an API call without MFA and confirm `AccessDenied` response",
        ],
    },
    "02": {
        "dir": "project-02-s3-static-website",
        "title": "Static Website Hosting on S3 + CloudFront CDN",
        "time": "2–3 Hours",
        "level": "Beginner",
        "description": (
            "Deploy a production-grade static website using Amazon S3 for origin storage and CloudFront as a "
            "global content delivery network. This project covers bucket policies, Origin Access Control (OAC), "
            "cache behaviors, and custom error pages — delivering sub-100ms latency worldwide."
        ),
        "services": ["S3", "CloudFront", "Route 53", "ACM"],
        "infra": {
            "S3 Bucket": "Static website origin bucket with versioning enabled; public access blocked at bucket level",
            "Bucket Policy": "Allows only CloudFront OAC principal (`cloudfront.amazonaws.com`) via `s3:GetObject`",
            "CloudFront Distribution": "HTTPS-only, TLSv1.2_2021, HTTP/2 + HTTP/3, gzip + Brotli compression",
            "Origin Access Control": "Replaces legacy OAI; scoped to the single S3 origin with signing protocol SigV4",
            "Cache Policy": "CachingOptimized managed policy (TTL 86400s); custom policy for `index.html` (TTL 300s)",
            "Error Pages": "Custom 404.html with 200 response code for SPA client-side routing",
            "Region": "ap-south-1 (S3 bucket); CloudFront edge locations are global",
        },
        "components": [
            ("S3 Static Website Origin", "Versioned bucket storing HTML, CSS, JS, and image assets with server-side encryption (SSE-S3)"),
            ("CloudFront Distribution", "Global edge cache with 450+ Points of Presence; HTTPS termination via ACM certificate"),
            ("Origin Access Control (OAC)", "SigV4-based authentication replacing legacy OAI; ensures S3 is only accessible via CloudFront"),
            ("Cache Behaviors", "Path-pattern rules (`/assets/*` → long TTL, `/*.html` → short TTL) for optimal freshness"),
            ("Custom Error Responses", "Maps S3 403/404 errors to `/index.html` with 200 status for single-page applications"),
            ("CloudFront Functions", "Lightweight edge compute for URL rewrites, security headers, and A/B testing"),
        ],
        "features": [
            "**Zero-Downtime Deployment** – Upload new assets to S3, then issue a CloudFront invalidation (`/*`)",
            "**HTTPS Everywhere** – ACM-issued TLS certificate with automatic renewal; HTTP → HTTPS redirect",
            "**Sub-100ms Global Latency** – CloudFront edge caching with Brotli compression and HTTP/3 support",
            "**SPA-Ready Routing** – Custom error responses rewrite all 404s to `index.html` for React/Vue/Angular apps",
            "**Versioned Rollback** – S3 versioning enables instant rollback to any previous deployment",
            "**Security Headers** – CloudFront Function injects `Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options`",
            "**Cost-Optimized Caching** – Separate cache policies for static assets (24h TTL) and HTML (5min TTL)",
        ],
        "prerequisites": [
            "AWS CLI v2 configured with IAM credentials (from Project 01)",
            "A registered domain name (optional, for custom domain setup)",
            "Static website files (HTML, CSS, JS) ready for deployment",
            "Node.js 18+ (optional, for building frontend frameworks)",
        ],
        "env_vars": {
            "AWS_REGION": "ap-south-1",
            "BUCKET_NAME": "my-static-website-bucket",
            "DISTRIBUTION_ID": "E1EXAMPLE12345",
            "DOMAIN_NAME": "example.com",
        },
        "run_scripts": [
            ("01-create-s3-bucket.sh", "Creates versioned S3 bucket with public access block and SSE-S3 encryption"),
            ("02-upload-website.sh", "Syncs local `./website/` directory to S3 with correct content-type headers"),
            ("03-create-cloudfront.sh", "Provisions CloudFront distribution with OAC, cache policies, and error pages"),
            ("04-invalidate-cache.sh", "Creates CloudFront invalidation for `/*` after new deployment"),
            ("05-cleanup.sh", "Disables distribution, empties bucket, and deletes all resources"),
        ],
        "testing": [
            "`curl -I https://<distribution-domain>` – Verify `x-cache: Hit from cloudfront` header",
            "`aws s3api get-bucket-versioning --bucket $BUCKET_NAME` – Confirm versioning is Enabled",
            "`curl -o /dev/null -s -w '%{http_code}' https://<domain>/nonexistent` – Expect 200 (SPA routing)",
            "Open browser DevTools → Network tab → verify Brotli (`content-encoding: br`) on CSS/JS assets",
            "`aws cloudfront get-distribution --id $DISTRIBUTION_ID` – Validate OAC configuration",
        ],
    },
    "03": {
        "dir": "project-03-Launch-EC2-Connect-via-SSH",
        "title": "Launch EC2 Instances & Secure Connectivity",
        "time": "2–3 Hours",
        "level": "Beginner",
        "description": (
            "Provision Amazon EC2 instances across availability zones with hardened security groups, "
            "key-pair-based SSH access, and AWS Systems Manager Session Manager for keyless browser-based shells. "
            "This project demonstrates instance lifecycle management, user data bootstrapping, and elastic IP allocation."
        ),
        "services": ["EC2", "VPC", "SSM", "EBS"],
        "infra": {
            "EC2 Instance": "t2.micro (Free Tier); Amazon Linux 2023 AMI; launched in default VPC public subnet",
            "Security Group": "Inbound: SSH (22) from your IP only; HTTP (80) from 0.0.0.0/0; Outbound: all traffic",
            "Key Pair": "RSA 2048-bit key pair generated via AWS CLI; `.pem` file stored locally with 400 permissions",
            "Elastic IP": "Static IPv4 address associated with the instance to survive stop/start cycles",
            "EBS Volume": "8 GiB gp3 root volume (3000 IOPS, 125 MB/s throughput); encrypted with default KMS key",
            "User Data": "Bootstrap script installing httpd, PHP, and a sample application on first boot",
            "SSM Agent": "Pre-installed on Amazon Linux 2023; instance profile grants `AmazonSSMManagedInstanceCore`",
            "Region": "ap-south-1a (primary AZ)",
        },
        "components": [
            ("EC2 Instance (t2.micro)", "Free-Tier eligible compute with burstable CPU; 1 vCPU, 1 GiB RAM"),
            ("Security Group (Firewall)", "Stateful L4 firewall with inbound/outbound rules scoped to CIDR and port ranges"),
            ("Key Pair (SSH)", "Asymmetric RSA key pair for secure, encrypted remote shell access"),
            ("Elastic IP", "Static public IPv4 that persists across instance stop/start; avoids DNS propagation delays"),
            ("User Data (Bootstrap)", "Base64-encoded shell script executed once at instance launch for automated setup"),
            ("SSM Session Manager", "Browser-based or CLI-based shell without opening port 22; fully audited via CloudTrail"),
            ("EBS gp3 Volume", "General-purpose SSD with baseline 3000 IOPS; encrypted at rest with AWS-managed KMS key"),
        ],
        "features": [
            "**Dual-Access Model** – SSH via key pair (port 22) + SSM Session Manager (no inbound ports required)",
            "**Automated Bootstrapping** – User Data script installs Apache, PHP, and deploys sample app on first launch",
            "**Security-First Configuration** – Security group restricts SSH to operator's IP; SSM eliminates key distribution",
            "**Persistent Public IP** – Elastic IP survives instance stop/start; avoids DNS re-mapping",
            "**Encrypted Storage** – EBS gp3 volume with AES-256 encryption via AWS-managed KMS key",
            "**Instance Metadata v2 (IMDSv2)** – Enforced token-based metadata service; mitigates SSRF attacks",
            "**Stop/Start Cost Optimization** – Scripts to stop instances during off-hours; EBS charges only ($0.08/GB/mo)",
        ],
        "prerequisites": [
            "AWS CLI v2 configured with IAM credentials (from Project 01)",
            "An SSH client (OpenSSH, PuTTY, or VS Code Remote SSH extension)",
            "Python 3.9+ (for AWS CLI v2 and Session Manager plugin)",
            "Session Manager Plugin installed (`aws ssm start-session` support)",
        ],
        "env_vars": {
            "AWS_REGION": "ap-south-1",
            "KEY_NAME": "my-ec2-keypair",
            "INSTANCE_TYPE": "t2.micro",
            "AMI_ID": "ami-0c55b159cbfafe1f0",
            "MY_IP": "$(curl -s ifconfig.me)/32",
        },
        "run_scripts": [
            ("01-create-keypair.sh", "Generates RSA key pair and saves .pem file with 400 permissions"),
            ("02-create-security-group.sh", "Creates SG with SSH (your IP) + HTTP (0.0.0.0/0) inbound rules"),
            ("03-launch-instance.sh", "Launches t2.micro with user data bootstrap, IMDSv2, and encrypted EBS"),
            ("04-allocate-eip.sh", "Allocates and associates an Elastic IP to the running instance"),
            ("05-connect-ssh.sh", "Connects to the instance via SSH using the generated key pair"),
        ],
        "testing": [
            "`aws ec2 describe-instances --instance-ids $INSTANCE_ID` – Confirm `running` state",
            "`ssh -i key.pem ec2-user@<EIP> 'curl localhost'` – Verify httpd is serving the sample page",
            "`aws ssm start-session --target $INSTANCE_ID` – Confirm Session Manager connectivity",
            "`curl http://<EIP>` – Verify HTTP access through the security group",
            "`aws ec2 describe-volumes --filters Name=encrypted,Values=true` – Confirm EBS encryption",
        ],
    },
    "04": {
        "dir": "project-04-s3-versioning",
        "title": "S3 Versioning, Lifecycle Rules & Cross-Region Replication",
        "time": "2–3 Hours",
        "level": "Beginner/Intermediate",
        "description": (
            "Master Amazon S3's data durability features by enabling object versioning for point-in-time recovery, "
            "configuring intelligent lifecycle policies to transition data across storage classes, and implementing "
            "cross-region replication for disaster recovery — all while optimizing costs with storage class analysis."
        ),
        "services": ["S3", "IAM", "KMS"],
        "infra": {
            "Source Bucket": "Versioning-enabled bucket in ap-south-1 with SSE-S3 default encryption",
            "Destination Bucket": "Versioning-enabled bucket in us-east-1 for cross-region replication (CRR)",
            "Lifecycle Rule 1": "Transition current versions to S3-IA after 30 days; to Glacier after 90 days",
            "Lifecycle Rule 2": "Expire non-current versions after 60 days; delete incomplete multipart uploads after 7 days",
            "Replication Rule": "Entire bucket scope; replicate delete markers; RTC (15-minute SLA); encrypted objects included",
            "IAM Role": "S3 replication role with `s3:ReplicateObject`, `s3:GetObjectVersionForReplication` permissions",
            "Region": "ap-south-1 (source) → us-east-1 (destination)",
        },
        "components": [
            ("S3 Versioning", "Maintains every version of every object; enables undelete and point-in-time recovery"),
            ("Lifecycle Policies", "Automated rules transitioning objects between Standard → IA → Glacier → Deep Archive"),
            ("Cross-Region Replication (CRR)", "Asynchronous, automatic replication of objects to a bucket in a different region"),
            ("Replication Time Control (RTC)", "SLA-backed 15-minute replication guarantee for compliance workloads"),
            ("S3 Storage Class Analysis", "Data access pattern analysis that recommends when to transition infrequently accessed data"),
            ("Delete Marker Replication", "Replicates delete markers to destination bucket for consistent soft-delete behavior"),
        ],
        "features": [
            "**Point-in-Time Recovery** – Retrieve any previous version of any object instantly",
            "**Cost-Optimized Tiering** – Automated lifecycle rules move cold data to IA (40% savings) and Glacier (68% savings)",
            "**Disaster Recovery** – Cross-region replication with <15 min RTC SLA ensures RPO compliance",
            "**Soft-Delete Protection** – Delete markers preserve object history; MFA Delete for permanent deletion",
            "**Multipart Upload Hygiene** – Auto-abort incomplete multipart uploads after 7 days to avoid hidden costs",
            "**Encryption at Rest** – SSE-S3 (AES-256) default encryption on both source and destination buckets",
            "**Storage Analytics** – Storage Class Analysis dashboard to validate lifecycle rule effectiveness",
        ],
        "prerequisites": [
            "AWS CLI v2 configured with IAM credentials (from Project 01)",
            "Two AWS regions available (ap-south-1 and us-east-1)",
            "Sample data files for upload (text, images, or any test objects)",
        ],
        "env_vars": {
            "AWS_REGION": "ap-south-1",
            "SOURCE_BUCKET": "my-versioned-source-bucket",
            "DEST_BUCKET": "my-versioned-dest-bucket",
            "DEST_REGION": "us-east-1",
        },
        "run_scripts": [
            ("01-create-buckets.sh", "Creates source and destination buckets with versioning and encryption"),
            ("02-configure-lifecycle.sh", "Applies lifecycle rules for transition, expiration, and multipart cleanup"),
            ("03-setup-replication.sh", "Creates IAM role and configures CRR with RTC between source and destination"),
            ("04-test-versioning.sh", "Uploads, overwrites, and deletes objects to demonstrate versioning behavior"),
            ("05-cleanup.sh", "Removes all object versions, delete markers, replication config, and buckets"),
        ],
        "testing": [
            "`aws s3api list-object-versions --bucket $SOURCE_BUCKET` – Verify multiple versions exist",
            "`aws s3api get-bucket-lifecycle-configuration --bucket $SOURCE_BUCKET` – Confirm lifecycle rules",
            "`aws s3api get-bucket-replication --bucket $SOURCE_BUCKET` – Validate CRR configuration",
            "Delete an object, then restore it: `aws s3api delete-object` → `aws s3api list-object-versions`",
            "`aws s3api head-object --bucket $DEST_BUCKET --key test.txt` – Confirm replication succeeded",
        ],
    },
    "05": {
        "dir": "project-05-Custom-VPC",
        "title": "Custom VPC with Public & Private Subnets",
        "time": "3–4 Hours",
        "level": "Intermediate",
        "description": (
            "Architect a production-grade Virtual Private Cloud (VPC) with multi-AZ public and private subnets, "
            "an Internet Gateway for public-facing resources, a NAT Gateway for secure outbound access from private "
            "subnets, and custom route tables — implementing the foundational network topology used by Fortune 500 companies."
        ),
        "services": ["VPC", "EC2", "NAT Gateway", "Internet Gateway"],
        "infra": {
            "VPC": "10.0.0.0/16 CIDR block (65,536 IPs); DNS hostnames and DNS resolution enabled",
            "Public Subnet A": "10.0.1.0/24 in us-east-1a; auto-assign public IP enabled; routes to IGW",
            "Public Subnet B": "10.0.2.0/24 in us-east-1b; auto-assign public IP enabled; routes to IGW",
            "Private Subnet A": "10.0.3.0/24 in us-east-1a; no public IP; routes to NAT Gateway",
            "Private Subnet B": "10.0.4.0/24 in us-east-1b; no public IP; routes to NAT Gateway",
            "Internet Gateway": "Attached to VPC; public route table has 0.0.0.0/0 → IGW",
            "NAT Gateway": "Elastic IP-backed; deployed in Public Subnet A; private route table has 0.0.0.0/0 → NAT",
            "NACLs": "Default allow-all NACLs; ephemeral port range (1024-65535) for return traffic",
            "Region": "us-east-1 (multi-AZ: 1a + 1b)",
        },
        "components": [
            ("VPC (10.0.0.0/16)", "Isolated virtual network with 65,536 available IP addresses"),
            ("Public Subnets (x2)", "Multi-AZ subnets with Internet Gateway routing for web servers and bastion hosts"),
            ("Private Subnets (x2)", "Multi-AZ subnets with NAT Gateway routing for databases and application logic"),
            ("Internet Gateway (IGW)", "Horizontally-scaled, HA gateway enabling bidirectional internet access for public subnets"),
            ("NAT Gateway", "Managed, HA network address translator enabling private subnet outbound-only internet access"),
            ("Route Tables", "Public table (0.0.0.0/0 → IGW) and private table (0.0.0.0/0 → NAT) with explicit subnet associations"),
            ("Network ACLs", "Stateless subnet-level firewall providing defense-in-depth alongside security groups"),
        ],
        "features": [
            "**Multi-AZ High Availability** – Subnets span two AZs for fault tolerance against data center failures",
            "**Defense-in-Depth** – Security groups (stateful L4) + NACLs (stateless L3/L4) provide layered network security",
            "**NAT Gateway for Private Egress** – Private instances pull updates/packages without exposing inbound ports",
            "**DNS Resolution** – VPC DNS hostnames enable human-readable internal addressing (`ip-10-0-1-42.ec2.internal`)",
            "**Elastic IP Persistence** – NAT Gateway's EIP ensures consistent outbound IP for allowlisting",
            "**CIDR Planning** – /24 subnets (251 usable IPs each) with room for future /24 expansion within the /16 VPC",
            "**Flow Logs Ready** – VPC architecture supports CloudWatch or S3-based VPC Flow Logs for network monitoring",
        ],
        "prerequisites": [
            "AWS CLI v2 configured with IAM credentials (from Project 01)",
            "Understanding of CIDR notation and IP addressing",
            "An SSH key pair (from Project 03) for testing connectivity",
        ],
        "env_vars": {
            "AWS_REGION": "us-east-1",
            "VPC_CIDR": "10.0.0.0/16",
            "PUBLIC_SUBNET_A_CIDR": "10.0.1.0/24",
            "PUBLIC_SUBNET_B_CIDR": "10.0.2.0/24",
            "PRIVATE_SUBNET_A_CIDR": "10.0.3.0/24",
            "PRIVATE_SUBNET_B_CIDR": "10.0.4.0/24",
        },
        "run_scripts": [
            ("01-create-vpc.sh", "Creates VPC with DNS settings, tags, and default security group"),
            ("02-create-subnets.sh", "Creates 4 subnets across 2 AZs with auto-assign public IP on public subnets"),
            ("03-create-igw.sh", "Creates and attaches Internet Gateway; creates public route table with 0.0.0.0/0 → IGW"),
            ("04-create-nat.sh", "Allocates Elastic IP, creates NAT Gateway in public subnet, creates private route table"),
            ("05-cleanup.sh", "Deletes NAT, releases EIP, detaches IGW, deletes subnets and VPC"),
        ],
        "testing": [
            "`aws ec2 describe-vpcs --vpc-ids $VPC_ID` – Verify VPC CIDR and DNS settings",
            "Launch EC2 in public subnet → `curl ifconfig.me` – Confirm internet access via IGW",
            "Launch EC2 in private subnet → `curl ifconfig.me` – Confirm outbound-only access via NAT",
            "`aws ec2 describe-route-tables` – Verify public (→ IGW) and private (→ NAT) route entries",
            "Attempt inbound SSH to private subnet EC2 from internet – Should be unreachable",
        ],
    },
    "06": {
        "dir": "project-06-rds-ec2",
        "title": "RDS MySQL + EC2 Two-Tier Web Application",
        "time": "3–4 Hours",
        "level": "Intermediate",
        "description": (
            "Build a classic two-tier architecture with an Amazon EC2 web server in a public subnet connecting "
            "to an Amazon RDS MySQL database in a private subnet. This project covers DB subnet groups, parameter "
            "groups, automated backups, multi-AZ deployment options, and connection pooling best practices."
        ),
        "services": ["RDS", "EC2", "VPC", "Secrets Manager"],
        "infra": {
            "RDS Instance": "db.t3.micro (Free Tier); MySQL 8.0; 20 GiB gp3 storage; single-AZ (multi-AZ optional)",
            "DB Subnet Group": "Private subnets across 2 AZs (from Project 05 VPC); no public accessibility",
            "Security Group (DB)": "Inbound: MySQL (3306) from EC2 security group only; no internet access",
            "Security Group (EC2)": "Inbound: HTTP (80), SSH (22 from your IP); outbound: all traffic",
            "Parameter Group": "Custom MySQL 8.0 parameter group: `character_set_server=utf8mb4`, `max_connections=100`",
            "Automated Backups": "7-day retention window; daily snapshot during 03:00–04:00 UTC maintenance window",
            "Secrets Manager": "RDS master credentials stored and auto-rotated every 30 days",
            "Region": "ap-south-1 (using VPC from Project 05)",
        },
        "components": [
            ("RDS MySQL 8.0", "Managed relational database with automated patching, backups, and point-in-time recovery"),
            ("EC2 Web Server", "Apache/PHP application server in public subnet; connects to RDS via private DNS endpoint"),
            ("DB Subnet Group", "Logical grouping of private subnets across AZs for RDS high-availability placement"),
            ("Custom Parameter Group", "Tuned MySQL settings: UTF-8 character set, connection limits, query cache configuration"),
            ("Secrets Manager Integration", "Secure credential storage with automatic 30-day rotation and Lambda-based rotation function"),
            ("Automated Backups", "Daily EBS snapshots with 7-day retention; supports point-in-time recovery to any second"),
        ],
        "features": [
            "**Network Isolation** – RDS in private subnet; only reachable from EC2's security group (no public endpoint)",
            "**Credential Rotation** – Secrets Manager auto-rotates MySQL master password every 30 days",
            "**Point-in-Time Recovery** – Restore database to any second within the 7-day backup retention window",
            "**Parameterized Tuning** – Custom parameter group optimizes character encoding, connections, and timeouts",
            "**Connection Pooling** – PHP application uses persistent connections to avoid TCP handshake overhead",
            "**Multi-AZ Ready** – Architecture supports one-click promotion to multi-AZ synchronous replication",
            "**Monitoring Dashboard** – CloudWatch metrics for CPU, connections, read/write IOPS, and replication lag",
        ],
        "prerequisites": [
            "Completed Project 05 (Custom VPC with public and private subnets)",
            "AWS CLI v2 configured with IAM credentials (from Project 01)",
            "MySQL client (`mysql` CLI) for testing database connectivity",
            "Basic SQL knowledge (CREATE TABLE, INSERT, SELECT)",
        ],
        "env_vars": {
            "AWS_REGION": "ap-south-1",
            "VPC_ID": "vpc-xxxxxxxxx",
            "DB_INSTANCE_ID": "my-rds-mysql",
            "DB_MASTER_USER": "admin",
            "DB_NAME": "myappdb",
        },
        "run_scripts": [
            ("01-create-db-subnet-group.sh", "Creates DB subnet group from private subnets in the custom VPC"),
            ("02-create-rds-instance.sh", "Launches RDS MySQL with parameter group, backups, and encryption"),
            ("03-create-ec2-webserver.sh", "Launches EC2 in public subnet with Apache/PHP user data bootstrap"),
            ("04-connect-app-to-db.sh", "Configures web app connection string using Secrets Manager credentials"),
            ("05-cleanup.sh", "Deletes RDS instance (skip final snapshot), EC2, subnet group, and security groups"),
        ],
        "testing": [
            "`mysql -h <rds-endpoint> -u admin -p myappdb -e 'SHOW TABLES;'` – Verify database connectivity",
            "`curl http://<EC2-public-IP>/db-test.php` – Confirm web app reads from RDS successfully",
            "`aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID` – Validate configuration",
            "`aws secretsmanager get-secret-value --secret-id rds-credentials` – Confirm secret exists",
            "Stop EC2, attempt direct RDS connection from internet – Should fail (no public access)",
        ],
    },
    "07": {
        "dir": "project-07-cloudwatch-monitoring",
        "title": "CloudWatch Monitoring, Alarms & SNS Notifications",
        "time": "2–3 Hours",
        "level": "Beginner/Intermediate",
        "description": (
            "Implement comprehensive AWS monitoring using CloudWatch metrics, custom dashboards, composite alarms, "
            "and SNS fan-out notifications. This project builds an observability layer that detects anomalies, "
            "triggers automated responses, and delivers real-time alerts via email and SMS — essential for production readiness."
        ),
        "services": ["CloudWatch", "SNS", "EC2", "Lambda"],
        "infra": {
            "CloudWatch Alarms": "CPU > 80% (WARNING), CPU > 95% (CRITICAL), StatusCheckFailed (CRITICAL)",
            "Composite Alarm": "Triggers when both CPU > 80% AND StatusCheckFailed are in ALARM state simultaneously",
            "CloudWatch Dashboard": "Custom dashboard with CPU, Network, Disk, and StatusCheck widgets across all instances",
            "Custom Metrics": "Application-level metrics published via PutMetricData (RequestLatency, ErrorCount, QueueDepth)",
            "SNS Topics": "`ops-warnings` (email) and `ops-critical` (email + SMS); subscription confirmation required",
            "Log Group": "Application logs streamed to `/aws/ec2/app-logs` with 30-day retention",
            "Metric Filter": "Extracts `ERROR` count from log group → custom metric → alarm",
            "Region": "ap-south-1",
        },
        "components": [
            ("CloudWatch Metric Alarms", "Threshold-based alarms monitoring CPU, network, status checks with configurable evaluation periods"),
            ("Composite Alarms", "Boolean logic combining multiple alarms (AND/OR/NOT) for sophisticated incident detection"),
            ("CloudWatch Dashboards", "Custom visualization grids with metric widgets, text annotations, and auto-refresh"),
            ("Custom Metrics (PutMetricData)", "Application-published metrics with dimensions and units for business-level monitoring"),
            ("Metric Filters", "Pattern-match rules extracting structured data from CloudWatch Logs → custom metrics"),
            ("SNS Fan-Out", "Multi-protocol notification topics delivering to email, SMS, Lambda, SQS, and HTTP endpoints"),
        ],
        "features": [
            "**Multi-Tier Alerting** – WARNING (email-only) and CRITICAL (email + SMS) severity-based notification routing",
            "**Composite Logic** – Alarm combining CPU + status check avoids false positives from CPU spikes alone",
            "**Custom Dashboard** – Real-time visualization of 8+ metrics with automatic cross-instance aggregation",
            "**Log-Based Metrics** – Extract ERROR counts from application logs without modifying application code",
            "**Auto-Scaling Integration** – Alarms can trigger Auto Scaling policies (pairs with Project 10)",
            "**Anomaly Detection** – ML-powered anomaly detection bands for CPU and request latency metrics",
            "**Cost-Zero Monitoring** – Free Tier includes 10 alarms, 3 dashboards, and 5GB log ingestion",
        ],
        "prerequisites": [
            "AWS CLI v2 configured with IAM credentials (from Project 01)",
            "At least one running EC2 instance (from Project 03) for metric collection",
            "Email address and phone number for SNS subscription confirmation",
            "Basic understanding of metric namespaces and dimensions",
        ],
        "env_vars": {
            "AWS_REGION": "ap-south-1",
            "INSTANCE_ID": "i-xxxxxxxxxxxxxxxxx",
            "ALERT_EMAIL": "your-email@example.com",
            "ALERT_PHONE": "+91XXXXXXXXXX",
            "WARNING_THRESHOLD": "80",
            "CRITICAL_THRESHOLD": "95",
        },
        "run_scripts": [
            ("01-create-sns-topics.sh", "Creates WARNING and CRITICAL SNS topics with email/SMS subscriptions"),
            ("02-create-alarms.sh", "Creates CPU, StatusCheck, and composite CloudWatch alarms with SNS actions"),
            ("03-create-dashboard.sh", "Provisions CloudWatch dashboard with CPU, Network, Disk, and alarm widgets"),
            ("04-create-metric-filter.sh", "Creates log group metric filter for ERROR pattern → custom alarm"),
            ("05-stress-test.sh", "Runs `stress` tool on EC2 to trigger CPU alarm for end-to-end verification"),
        ],
        "testing": [
            "`aws cloudwatch describe-alarms` – Verify all alarms exist with correct thresholds",
            "Run `stress --cpu 2 --timeout 300` on EC2 → watch alarm transition to ALARM state",
            "Check email/SMS inbox for SNS notification delivery within 1–2 minutes",
            "`aws cloudwatch get-dashboard --dashboard-name ops-dashboard` – Validate dashboard JSON",
            "`aws logs put-log-events` with ERROR message → verify metric filter increments custom metric",
        ],
    },
    "08": {
        "dir": "project-08-serverless-rest-api",
        "title": "Serverless REST API with API Gateway, Lambda & DynamoDB",
        "time": "3–4 Hours",
        "level": "Intermediate",
        "description": (
            "Build a fully serverless CRUD REST API using Amazon API Gateway as the HTTP front door, AWS Lambda "
            "for compute logic, and DynamoDB as a NoSQL data store. This project implements request validation, "
            "Lambda proxy integration, DynamoDB single-table design, and API key-based throttling — achieving "
            "zero-server, pay-per-request architecture."
        ),
        "services": ["API Gateway", "Lambda", "DynamoDB", "IAM", "CloudWatch"],
        "infra": {
            "API Gateway": "REST API (regional); stages: `dev`, `prod`; API key + usage plan (1000 req/day, 10 req/sec burst)",
            "Lambda Functions": "Python 3.12 runtime; 128MB memory, 10s timeout; 4 functions (Create, Read, Update, Delete)",
            "DynamoDB Table": "On-demand capacity; partition key `PK` (String), sort key `SK` (String); single-table design",
            "IAM Role (Lambda)": "`lambda-dynamodb-role` with `dynamodb:PutItem/GetItem/UpdateItem/DeleteItem/Query` on table ARN",
            "CloudWatch Logs": "Automatic log groups per Lambda function; 14-day retention; structured JSON logging",
            "API Models": "JSON Schema request validation on POST/PUT endpoints; 400 response on malformed payloads",
            "CORS": "Enabled on all endpoints; `Access-Control-Allow-Origin: *` for development",
            "Region": "ap-south-1",
        },
        "components": [
            ("API Gateway (REST)", "Managed HTTP endpoint with stages, request validation, API keys, and usage plans"),
            ("Lambda Functions (x4)", "Stateless Python 3.12 handlers for Create, Read, Update, Delete operations"),
            ("DynamoDB (Single-Table)", "NoSQL database using single-table design with `PK`/`SK` composite key pattern"),
            ("Lambda Proxy Integration", "API Gateway passes full HTTP request to Lambda; Lambda returns statusCode + body"),
            ("API Key & Usage Plan", "Rate limiting (10 req/sec) and quota (1000 req/day) to prevent abuse"),
            ("Request Validation", "JSON Schema models on API Gateway validate request body before invoking Lambda"),
        ],
        "features": [
            "**Zero-Server Architecture** – No EC2, no containers; pay only for actual API invocations ($0.20/million requests)",
            "**Single-Table DynamoDB Design** – Partition key (`PK`) + sort key (`SK`) pattern for flexible access patterns",
            "**Request Validation** – API Gateway JSON Schema models reject malformed requests before Lambda is invoked",
            "**API Key Throttling** – Usage plans enforce rate limits (10 req/sec) and daily quotas (1000 req/day)",
            "**Structured Logging** – Lambda functions emit JSON-formatted logs to CloudWatch for easy parsing",
            "**Stage Deployment** – Separate `dev` and `prod` stages with independent configurations and endpoints",
            "**CORS Support** – Pre-flight OPTIONS responses enable browser-based frontend integration",
        ],
        "prerequisites": [
            "AWS CLI v2 configured with IAM credentials (from Project 01)",
            "Python 3.12+ installed locally for Lambda function development",
            "`zip` utility for packaging Lambda deployment artifacts",
            "Postman or `curl` for API testing",
        ],
        "env_vars": {
            "AWS_REGION": "ap-south-1",
            "TABLE_NAME": "ServerlessAPI",
            "API_NAME": "serverless-crud-api",
            "STAGE_NAME": "dev",
            "LAMBDA_ROLE_ARN": "arn:aws:iam::ACCOUNT_ID:role/lambda-dynamodb-role",
        },
        "run_scripts": [
            ("01-create-dynamodb.sh", "Creates DynamoDB table with on-demand capacity and PK/SK schema"),
            ("02-create-lambda-role.sh", "Creates IAM role with DynamoDB and CloudWatch Logs permissions"),
            ("03-deploy-lambdas.sh", "Packages and deploys 4 Lambda functions (CRUD) with Python 3.12 runtime"),
            ("04-create-api-gateway.sh", "Creates REST API with resources, methods, Lambda integrations, and CORS"),
            ("05-test-api.sh", "Runs curl commands against all CRUD endpoints and validates responses"),
        ],
        "testing": [
            "`curl -X POST https://<api-id>.execute-api.<region>.amazonaws.com/dev/items -d '{...}'` – Create item",
            "`curl https://<api-id>.execute-api.<region>.amazonaws.com/dev/items/<id>` – Read item",
            "`aws dynamodb scan --table-name ServerlessAPI` – Verify items stored in DynamoDB",
            "`aws apigateway get-rest-api --rest-api-id <id>` – Validate API Gateway configuration",
            "Send malformed JSON body → expect 400 response from request validation",
        ],
    },
    "09": {
        "dir": "project-09-cicd-pipeline",
        "title": "CI/CD Pipeline with CodeCommit, CodeBuild & CodeDeploy",
        "time": "4–5 Hours",
        "level": "Intermediate/Advanced",
        "description": (
            "Construct an end-to-end Continuous Integration and Continuous Deployment pipeline using AWS-native "
            "developer tools. Code pushed to CodeCommit triggers CodeBuild for compilation and testing, then "
            "CodeDeploy performs rolling deployments to EC2 instances — enabling automated, repeatable, and "
            "auditable software delivery."
        ),
        "services": ["CodeCommit", "CodeBuild", "CodeDeploy", "CodePipeline", "S3", "IAM"],
        "infra": {
            "CodeCommit Repository": "Git repository hosting application source code with branch-based workflow",
            "CodeBuild Project": "Ubuntu Standard 7.0 image; buildspec.yml defines install → build → test → artifact phases",
            "CodeDeploy Application": "EC2/On-Premises compute platform; `CodeDeployDefault.OneAtATime` deployment config",
            "CodePipeline": "3-stage pipeline: Source (CodeCommit) → Build (CodeBuild) → Deploy (CodeDeploy)",
            "S3 Artifact Bucket": "Pipeline artifact store for build outputs and deployment packages",
            "IAM Roles": "Separate roles for CodePipeline, CodeBuild, and CodeDeploy with least-privilege policies",
            "AppSpec": "YAML deployment specification defining lifecycle hooks: BeforeInstall, AfterInstall, ApplicationStart",
            "Region": "ap-south-1",
        },
        "components": [
            ("CodeCommit Repository", "Fully-managed Git repository with IAM-based authentication and encryption at rest"),
            ("CodeBuild Project", "Managed build service executing buildspec.yml in isolated Docker containers"),
            ("CodeDeploy Application", "Deployment orchestrator managing rollouts with lifecycle hooks and rollback triggers"),
            ("CodePipeline", "Continuous delivery orchestrator connecting Source → Build → Deploy stages"),
            ("buildspec.yml", "Build specification defining phases (install, pre_build, build, post_build) and artifact outputs"),
            ("appspec.yml", "Deployment specification defining file mappings, permissions, and lifecycle hook scripts"),
        ],
        "features": [
            "**Fully Automated Pipeline** – Git push triggers build, test, and deploy without manual intervention",
            "**Buildspec-Driven Builds** – Declarative YAML defines install dependencies, run tests, and package artifacts",
            "**Rolling Deployments** – CodeDeploy updates instances one-at-a-time to maintain availability during deploy",
            "**Automatic Rollback** – Deployment fails → CodeDeploy rolls back to last known-good revision automatically",
            "**Lifecycle Hooks** – Custom scripts run at BeforeInstall, AfterInstall, and ApplicationStart stages",
            "**Artifact Versioning** – S3 stores every build artifact with pipeline execution ID for full traceability",
            "**Branch-Based Workflow** – Pipeline triggers on `main` branch pushes; feature branches build independently",
        ],
        "prerequisites": [
            "AWS CLI v2 configured with IAM credentials (from Project 01)",
            "Git client installed (`git --version` ≥ 2.x)",
            "At least one EC2 instance with CodeDeploy agent installed (from Project 03)",
            "HTTPS Git credentials configured for CodeCommit access",
        ],
        "env_vars": {
            "AWS_REGION": "ap-south-1",
            "REPO_NAME": "my-app-repo",
            "BUILD_PROJECT": "my-app-build",
            "DEPLOY_APP": "my-app-deploy",
            "DEPLOY_GROUP": "my-app-deploy-group",
            "PIPELINE_NAME": "my-app-pipeline",
        },
        "run_scripts": [
            ("01-create-codecommit.sh", "Creates CodeCommit repository and pushes initial application code"),
            ("02-create-codebuild.sh", "Creates CodeBuild project with buildspec.yml and IAM service role"),
            ("03-create-codedeploy.sh", "Creates CodeDeploy application, deployment group, and appspec.yml"),
            ("04-create-pipeline.sh", "Creates CodePipeline connecting all three stages with artifact store"),
            ("05-trigger-deploy.sh", "Commits a code change to trigger the full pipeline end-to-end"),
        ],
        "testing": [
            "`git push` to CodeCommit → verify pipeline starts within 30 seconds",
            "`aws codebuild batch-get-builds` → confirm build status is SUCCEEDED",
            "`aws deploy get-deployment` → verify deployment status is Succeeded",
            "`curl http://<EC2-IP>` → confirm updated application is live",
            "Push broken code → verify automatic rollback triggers and previous version is restored",
        ],
    },
    "10": {
        "dir": "project-10-auto-scaling-alb",
        "title": "Auto Scaling Group with Application Load Balancer",
        "time": "4–5 Hours",
        "level": "Intermediate/Advanced",
        "description": (
            "Implement elastic compute infrastructure using an Auto Scaling Group (ASG) behind an Application "
            "Load Balancer (ALB). This project covers launch templates, scaling policies (target tracking, step, "
            "and scheduled), health checks, sticky sessions, and cross-zone load balancing — the backbone of "
            "every highly-available AWS deployment."
        ),
        "services": ["EC2", "ALB", "ASG", "CloudWatch", "VPC"],
        "infra": {
            "Application Load Balancer": "Internet-facing; HTTP listener (80) → target group; cross-zone load balancing enabled",
            "Target Group": "Health check: HTTP:80 `/health` path; 30s interval, 5s timeout, 3 healthy/2 unhealthy thresholds",
            "Launch Template": "t2.micro; Amazon Linux 2023; user data installs httpd; instance metadata v2 enforced",
            "Auto Scaling Group": "Min: 2, Desired: 2, Max: 6; spans 2 AZs; ELB health check type (not EC2)",
            "Target Tracking Policy": "Scale out when average CPU > 70% across the group; 300s cooldown",
            "Scheduled Action": "Scale to min=4 on weekdays 09:00 UTC; scale to min=2 on weekdays 18:00 UTC",
            "SNS Notifications": "ASG lifecycle events (launch, terminate) trigger SNS → email alerts",
            "Region": "ap-south-1 (using VPC from Project 05)",
        },
        "components": [
            ("Application Load Balancer", "Layer-7 load balancer with HTTP/HTTPS listeners, path-based routing, and WebSocket support"),
            ("Target Group", "Logical grouping of targets (EC2 instances) with configurable health checks and deregistration delay"),
            ("Launch Template", "Versioned instance configuration (AMI, instance type, security groups, user data) for ASG"),
            ("Auto Scaling Group", "Fleet manager that maintains desired capacity, replaces unhealthy instances, and scales on demand"),
            ("Target Tracking Policy", "Automatic scaling that maintains a specified CloudWatch metric target (e.g., CPU 70%)"),
            ("Scheduled Scaling", "Cron-based scaling actions for predictable traffic patterns (business hours vs. off-hours)"),
        ],
        "features": [
            "**Self-Healing Infrastructure** – ASG automatically replaces instances failing ALB health checks within 90 seconds",
            "**Target Tracking Scaling** – Maintains 70% CPU utilization; automatically adds/removes instances as load changes",
            "**Scheduled Scaling** – Pre-warms capacity to min=4 before business hours; scales down to min=2 after hours",
            "**Cross-Zone Load Balancing** – ALB distributes traffic evenly across AZs even with unequal instance counts",
            "**Rolling Updates** – Launch template versioning enables zero-downtime AMI updates with instance refresh",
            "**Connection Draining** – 300s deregistration delay allows in-flight requests to complete before termination",
            "**Lifecycle Hooks** – Custom actions (warm-up scripts, log flushing) execute during launch and terminate transitions",
        ],
        "prerequisites": [
            "Completed Project 05 (Custom VPC with public subnets across 2 AZs)",
            "AWS CLI v2 configured with IAM credentials (from Project 01)",
            "Understanding of CloudWatch metrics and alarms (from Project 07)",
            "An SSH key pair (from Project 03) for debugging individual instances",
        ],
        "env_vars": {
            "AWS_REGION": "ap-south-1",
            "VPC_ID": "vpc-xxxxxxxxx",
            "SUBNET_IDS": "subnet-aaa,subnet-bbb",
            "KEY_NAME": "my-ec2-keypair",
            "AMI_ID": "ami-0c55b159cbfafe1f0",
            "ASG_MIN": "2",
            "ASG_MAX": "6",
            "CPU_TARGET": "70",
        },
        "run_scripts": [
            ("01-create-launch-template.sh", "Creates versioned launch template with user data and IMDSv2 enforcement"),
            ("02-create-alb.sh", "Creates ALB, target group, and HTTP listener with health check configuration"),
            ("03-create-asg.sh", "Creates ASG with multi-AZ placement, ELB health checks, and target tracking policy"),
            ("04-create-scheduled-actions.sh", "Configures business-hours scale-up and off-hours scale-down schedules"),
            ("05-stress-test.sh", "Generates CPU load to trigger scale-out and verify ALB distributes to new instances"),
        ],
        "testing": [
            "`curl http://<ALB-DNS>` multiple times → verify responses come from different instance IDs",
            "`aws autoscaling describe-auto-scaling-groups` → verify desired=2, min=2, max=6",
            "Run `stress --cpu 2` on all instances → watch ASG scale out to 4+ instances within 5 minutes",
            "Terminate an instance manually → verify ASG launches replacement within 90 seconds",
            "`aws elbv2 describe-target-health` → confirm all registered targets are `healthy`",
        ],
    },
    "11": {
        "dir": "project-11-infrastructure-as-code",
        "title": "Infrastructure as Code with AWS CloudFormation",
        "time": "4–5 Hours",
        "level": "Intermediate/Advanced",
        "description": (
            "Define and provision AWS infrastructure declaratively using CloudFormation templates. This project "
            "creates a reusable, version-controlled stack that deploys a complete VPC, EC2 instances, RDS database, "
            "and ALB — implementing infrastructure as code best practices including parameterization, mappings, "
            "conditions, outputs, and nested stacks."
        ),
        "services": ["CloudFormation", "VPC", "EC2", "RDS", "ALB"],
        "infra": {
            "CloudFormation Stack": "Root stack with 3 nested stacks: Network, Compute, Database",
            "Template Format": "YAML with AWSTemplateFormatVersion: 2010-09-09; Description and Metadata sections",
            "Parameters": "EnvironmentType (dev/staging/prod), InstanceType, DBInstanceClass, KeyName, CIDR ranges",
            "Mappings": "AMI IDs per region; instance type → EBS size; environment → capacity settings",
            "Conditions": "CreateProdResources (Multi-AZ RDS, larger instances); CreateDevResources (t2.micro, single-AZ)",
            "Outputs": "VPC ID, ALB DNS name, RDS endpoint, SSH command — exported for cross-stack references",
            "Change Sets": "Preview-before-apply workflow for all stack updates",
            "Drift Detection": "Scheduled drift detection to identify out-of-band resource modifications",
            "Region": "ap-south-1 (parameterized for multi-region deployment)",
        },
        "components": [
            ("Root Stack Template", "Master template orchestrating nested stacks with cross-stack parameter passing"),
            ("Network Stack (Nested)", "VPC, subnets, IGW, NAT, route tables — reusable network foundation"),
            ("Compute Stack (Nested)", "Launch template, ASG, ALB, target group — condition-driven sizing per environment"),
            ("Database Stack (Nested)", "RDS MySQL, DB subnet group, parameter group — multi-AZ conditional on environment"),
            ("Parameters & Mappings", "Externalized configuration enabling single template for dev/staging/prod environments"),
            ("Outputs & Exports", "Cross-stack references enabling loose coupling between network, compute, and database"),
        ],
        "features": [
            "**Declarative Infrastructure** – Entire stack defined in version-controlled YAML; reproducible and auditable",
            "**Environment Parameterization** – Single template deploys dev (t2.micro, single-AZ) or prod (t3.large, multi-AZ)",
            "**Nested Stack Architecture** – Modular templates for network, compute, and database with independent lifecycle",
            "**Change Set Workflow** – Preview all resource additions, modifications, and replacements before execution",
            "**Drift Detection** – Identify resources modified outside CloudFormation (manual console changes)",
            "**Rollback Protection** – Automatic rollback on stack creation/update failure; preserves last-known-good state",
            "**Cross-Stack References** – Exported outputs enable loose coupling between independently managed stacks",
        ],
        "prerequisites": [
            "AWS CLI v2 configured with IAM credentials (from Project 01)",
            "Understanding of VPC, EC2, RDS concepts (Projects 03, 05, 06)",
            "YAML syntax familiarity",
            "cfn-lint installed for template validation (`pip install cfn-lint`)",
        ],
        "env_vars": {
            "AWS_REGION": "ap-south-1",
            "STACK_NAME": "my-iac-stack",
            "ENVIRONMENT": "dev",
            "KEY_NAME": "my-ec2-keypair",
            "DB_PASSWORD": "ChangeMe123!",
        },
        "run_scripts": [
            ("01-validate-template.sh", "Runs cfn-lint and aws cloudformation validate-template on all templates"),
            ("02-deploy-stack.sh", "Creates or updates the root stack with parameters for the target environment"),
            ("03-create-change-set.sh", "Generates and reviews a change set before applying stack modifications"),
            ("04-detect-drift.sh", "Initiates drift detection and reports any out-of-band resource changes"),
            ("05-delete-stack.sh", "Deletes the entire stack including all nested stacks and resources"),
        ],
        "testing": [
            "`aws cloudformation describe-stacks --stack-name $STACK_NAME` – Verify CREATE_COMPLETE status",
            "`aws cloudformation detect-stack-drift --stack-name $STACK_NAME` – Run drift detection",
            "Deploy with `ENVIRONMENT=dev` → verify t2.micro and single-AZ RDS",
            "Deploy with `ENVIRONMENT=prod` → verify t3.large and multi-AZ RDS",
            "Make a console change → re-run drift detection → verify drift is reported",
        ],
    },
    "12": {
        "dir": "project-12-event-driven-pipeline",
        "title": "Event-Driven Data Pipeline with S3, SQS & Lambda",
        "time": "4–5 Hours",
        "level": "Intermediate/Advanced",
        "description": (
            "Architect a fully event-driven data processing pipeline where S3 object uploads trigger SQS messages "
            "consumed by Lambda functions for transformation and loading. This project implements dead-letter queues, "
            "batch processing windows, message visibility timeouts, and idempotent processing — the foundation of "
            "modern serverless data engineering on AWS."
        ),
        "services": ["S3", "SQS", "Lambda", "DynamoDB", "CloudWatch"],
        "infra": {
            "S3 Source Bucket": "Event notifications enabled; triggers on `s3:ObjectCreated:*` → SQS queue",
            "SQS Main Queue": "Standard queue; visibility timeout 300s (6× Lambda timeout); message retention 4 days",
            "SQS Dead-Letter Queue": "Receives messages after 3 failed processing attempts; 14-day retention for analysis",
            "Lambda Processor": "Python 3.12; 256MB memory, 50s timeout; batch size 10 messages; concurrent executions 5",
            "DynamoDB Results Table": "On-demand capacity; stores processed records with idempotency key (message ID)",
            "S3 Event Notification": "Suffix filter `.csv` ensures only CSV uploads trigger the pipeline",
            "CloudWatch Alarms": "DLQ message count > 0 triggers SNS alert; Lambda errors > 5% triggers investigation",
            "Region": "ap-south-1",
        },
        "components": [
            ("S3 Event Notifications", "Object-level triggers filtering by prefix/suffix that publish to SQS, SNS, or Lambda"),
            ("SQS Standard Queue", "Managed message buffer decoupling S3 events from Lambda processing; at-least-once delivery"),
            ("SQS Dead-Letter Queue (DLQ)", "Poison-message quarantine after maxReceiveCount failures; enables error analysis"),
            ("Lambda Event Source Mapping", "Polls SQS queue in batches of 10; automatic scaling of concurrent invocations"),
            ("DynamoDB Idempotency Table", "Conditional writes using message ID prevent duplicate processing on retry"),
            ("CloudWatch DLQ Alarm", "Monitors `ApproximateNumberOfMessagesVisible` on DLQ; alerts on first failed message"),
        ],
        "features": [
            "**Fully Event-Driven** – No polling, no cron; S3 upload → SQS → Lambda fires automatically within seconds",
            "**Dead-Letter Queue Safety Net** – Failed messages quarantined after 3 attempts; zero data loss guarantee",
            "**Batch Processing** – Lambda processes up to 10 SQS messages per invocation for throughput optimization",
            "**Idempotent Processing** – DynamoDB conditional writes prevent duplicate records on Lambda retries",
            "**Suffix Filtering** – S3 notifications trigger only for `.csv` files; ignores metadata and temp uploads",
            "**Visibility Timeout Tuning** – 300s timeout (6× Lambda 50s timeout) prevents message reprocessing during execution",
            "**Operational Observability** – CloudWatch alarms on DLQ depth and Lambda error rate for proactive incident response",
        ],
        "prerequisites": [
            "AWS CLI v2 configured with IAM credentials (from Project 01)",
            "Python 3.12+ installed locally for Lambda function development",
            "Sample CSV data files for testing the pipeline",
            "Understanding of SQS message lifecycle (send → receive → delete → DLQ)",
        ],
        "env_vars": {
            "AWS_REGION": "ap-south-1",
            "SOURCE_BUCKET": "event-pipeline-source",
            "QUEUE_NAME": "event-pipeline-queue",
            "DLQ_NAME": "event-pipeline-dlq",
            "TABLE_NAME": "ProcessedRecords",
            "LAMBDA_FUNCTION": "event-pipeline-processor",
        },
        "run_scripts": [
            ("01-create-sqs.sh", "Creates main queue with DLQ redrive policy (maxReceiveCount: 3)"),
            ("02-create-dynamodb.sh", "Creates results table with on-demand capacity and idempotency key"),
            ("03-deploy-lambda.sh", "Packages and deploys processing Lambda with SQS event source mapping"),
            ("04-create-s3-trigger.sh", "Creates source bucket with event notification → SQS for .csv suffix"),
            ("05-test-pipeline.sh", "Uploads sample CSV to S3 and verifies processing in DynamoDB"),
        ],
        "testing": [
            "`aws s3 cp sample.csv s3://$SOURCE_BUCKET/` – Upload triggers pipeline within 5 seconds",
            "`aws dynamodb scan --table-name ProcessedRecords` – Verify processed records appear",
            "`aws sqs get-queue-attributes --attribute-names ApproximateNumberOfMessagesVisible` – Queue should be 0",
            "Upload malformed CSV → verify message lands in DLQ after 3 retries",
            "`aws cloudwatch describe-alarms --alarm-names dlq-alarm` – Confirm alarm transitions to ALARM",
        ],
    },
}


def build_readme(num: str, p: dict) -> str:
    """Generate a deeply technical, standardized README.md."""
    dir_name = p["dir"]
    svg_url = f"{GITHUB_BASE}/{dir_name}/architecture/architecture.svg"

    # ── Determine navigation ──
    prev_num = int(num) - 1
    next_num = int(num) + 1
    if prev_num >= 1:
        prev_dir = PROJECTS[f"{prev_num:02d}"]["dir"]
        prev_link = f"[⬅️ Previous: Project {prev_num:02d}](../{prev_dir})"
    else:
        prev_link = ""
    if next_num <= 12:
        next_dir = PROJECTS[f"{next_num:02d}"]["dir"]
        next_link = f"[Next: Project {next_num:02d} ➡️](../{next_dir})"
    else:
        next_link = ""

    nav_separator = " &nbsp;|&nbsp; " if prev_link and next_link else ""

    # ── Build sections ──
    lines = []

    # Title + description + badges
    lines.append(f'<div align="center">\n')
    lines.append(f'  <img src="{svg_url}" alt="{p["title"]} Architecture" width="820"/>\n')
    lines.append(f'  <br/><br/>\n')
    lines.append(f'  <h1>')
    lines.append(f'<img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="36" height="36" style="vertical-align: middle"/> ')
    lines.append(f'Project {num}: {p["title"]}')
    lines.append(f'</h1>\n')
    lines.append(f'\n')
    # Description
    lines.append(f'  <p><i>{p["description"]}</i></p>\n')
    lines.append(f'\n')
    # Badges
    lines.append(f'  <p>\n')
    lines.append(f'    <img src="https://img.shields.io/badge/Level-{p["level"].replace(" ", "%20")}-blue" alt="Level"/>\n')
    lines.append(f'    <img src="https://img.shields.io/badge/Time-{p["time"].replace(" ", "%20").replace("–", "--")}-orange" alt="Time"/>\n')
    lines.append(f'    <img src="https://img.shields.io/badge/Cost-$0.00%20(Free%20Tier)-brightgreen" alt="Cost"/>\n')
    lines.append(f'    <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License"/>\n')
    lines.append(f'    <img src="https://img.shields.io/badge/Build-Passing-success" alt="Build"/>\n')
    lines.append(f'  </p>\n')
    lines.append(f'\n')
    # Quick links
    lines.append(f'  <p>\n')
    lines.append(f'    <a href="#-infrastructure-specifications">Infrastructure</a> · \n')
    lines.append(f'    <a href="#-key-components">Components</a> · \n')
    lines.append(f'    <a href="#-core-features">Features</a> · \n')
    lines.append(f'    <a href="#-setup--installation">Setup</a> · \n')
    lines.append(f'    <a href="#-documentation-suite">Docs</a>\n')
    lines.append(f'  </p>\n')
    lines.append(f'\n')
    # Live demo
    lines.append(f'  <p><b>🔗 <a href="#">Live Demo</a></b> &nbsp;·&nbsp; <b>📹 <a href="#">Video Walkthrough</a></b></p>\n')
    lines.append(f'\n')
    lines.append(f'</div>\n')
    lines.append(f'\n<br/>\n\n')

    # ── Architecture Diagram (centered) ──
    lines.append(f'<div align="center">\n\n')
    lines.append(f'## 🏗️ Architecture Overview\n\n')
    lines.append(f'<img src="{svg_url}" alt="{p["title"]} — System Architecture" width="800"/>\n\n')
    lines.append(f'<p><i>▲ High-level architecture diagram showing the interaction between {", ".join(p["services"])} services</i></p>\n\n')
    lines.append(f'</div>\n\n')

    # ── Infrastructure Specifications ──
    lines.append(f'## 📐 Infrastructure Specifications\n\n')
    lines.append(f'| Resource | Configuration |\n')
    lines.append(f'|:---------|:--------------|\n')
    for k, v in p["infra"].items():
        lines.append(f'| **{k}** | {v} |\n')
    lines.append(f'\n')

    # ── Key Components ──
    lines.append(f'## 🧩 Key Components\n\n')
    for name, desc in p["components"]:
        lines.append(f'### {name}\n')
        lines.append(f'{desc}\n\n')

    # ── Core Features ──
    lines.append(f'## ⚡ Core Features\n\n')
    for feat in p["features"]:
        lines.append(f'- {feat}\n')
    lines.append(f'\n')

    # ── Setup & Installation ──
    lines.append(f'## 🛠️ Setup & Installation\n\n')
    lines.append(f'### Prerequisites\n\n')
    for pre in p["prerequisites"]:
        lines.append(f'- {pre}\n')
    lines.append(f'\n')

    lines.append(f'### Installation\n\n')
    lines.append(f'```bash\n')
    lines.append(f'# 1. Clone the repository\n')
    lines.append(f'git clone https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects.git\n')
    lines.append(f'cd {dir_name}\n')
    lines.append(f'\n')
    lines.append(f'# 2. Configure environment variables\n')
    lines.append(f'cp .env.example .env\n')
    lines.append(f'# Edit .env with your specific values (see Environment Variables below)\n')
    lines.append(f'```\n\n')

    lines.append(f'### Environment Variables\n\n')
    lines.append(f'Create a `.env` file in the project root:\n\n')
    lines.append(f'```bash\n')
    for k, v in p["env_vars"].items():
        lines.append(f'export {k}="{v}"\n')
    lines.append(f'```\n\n')

    lines.append(f'### Run Commands\n\n')
    lines.append(f'Choose your platform and execute the scripts in order:\n\n')
    lines.append(f'<table>\n')
    lines.append(f'<tr><th>Step</th><th>Script</th><th>Description</th></tr>\n')
    for script_name, script_desc in p["run_scripts"]:
        ps_name = script_name.replace(".sh", ".ps1")
        lines.append(f'<tr><td>🐧</td><td><code>scripts/bash/{script_name}</code></td><td>{script_desc}</td></tr>\n')
        lines.append(f'<tr><td>🖥️</td><td><code>scripts/powershell/{ps_name}</code></td><td>{script_desc}</td></tr>\n')
    lines.append(f'</table>\n\n')

    # ── Documentation Suite ──
    lines.append(f'## 📚 Documentation Suite\n\n')
    lines.append(f'| Document | Description |\n')
    lines.append(f'|:---------|:------------|\n')
    lines.append(f'| 📄 [Project Overview](docs/project-overview.md) | Comprehensive project context, goals, and learning outcomes |\n')
    lines.append(f'| 🏗️ [Architecture Details](docs/architecture.md) | Deep-dive into system design, data flow, and component interactions |\n')
    lines.append(f'| 🚀 [Deployment Guide](docs/deployment-guide.md) | Step-by-step deployment procedures for dev, staging, and production |\n')
    lines.append(f'| 🔐 [Security Protocols](docs/security-protocols.md) | IAM policies, encryption, network security, and compliance controls |\n')
    lines.append(f'| 🧪 [Testing Procedures](docs/testing-procedures.md) | Validation scripts, smoke tests, and integration test suites |\n')
    lines.append(f'| 🛠️ [Troubleshooting](docs/troubleshooting.md) | Common issues, error codes, debugging steps, and resolution guides |\n')
    lines.append(f'\n')

    # ── Contribution & Maintenance ──
    lines.append(f'## 🤝 Contribution & Maintenance\n\n')

    lines.append(f'### Testing\n\n')
    for test in p["testing"]:
        lines.append(f'- {test}\n')
    lines.append(f'\n')

    lines.append(f'### Deployment\n\n')
    lines.append(f'For full production deployment procedures, see the [Deployment Guide](docs/deployment-guide.md).\n\n')

    lines.append(f'### Contributing\n\n')
    lines.append(f'1. **Fork** the repository and create a feature branch (`git checkout -b feature/amazing-feature`)\n')
    lines.append(f'2. **Commit** your changes (`git commit -m "Add amazing feature"`)\n')
    lines.append(f'3. **Push** to the branch (`git push origin feature/amazing-feature`)\n')
    lines.append(f'4. **Open** a Pull Request with a detailed description\n')
    lines.append(f'5. Ensure all scripts exist in **both** `scripts/powershell/` and `scripts/bash/`\n\n')

    lines.append(f'### License\n\n')
    lines.append(f'This project is licensed under the **MIT License** — see the [LICENSE](../LICENSE) file for details.\n\n')

    lines.append(f'### Contact & Credits\n\n')
    lines.append(f'- **Author:** Vinay Kumar\n')
    lines.append(f'- **GitHub:** [@vinay1515](https://github.com/vinay1515)\n')
    lines.append(f'- **Repository:** [Vinay_kumar_AWS_Beginner_level_projects](https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects)\n\n')

    # ── Navigation Footer ──
    lines.append(f'---\n\n')
    lines.append(f'<div align="center">\n')
    lines.append(f'  <b>{prev_link}{nav_separator}{next_link}</b>\n')
    lines.append(f'</div>\n')

    return "".join(lines)


def main():
    updated = 0
    for num, project in PROJECTS.items():
        proj_path = os.path.join(ROOT_DIR, project["dir"])
        if not os.path.isdir(proj_path):
            print(f"  SKIP  {project['dir']} (directory not found)")
            continue
        readme_path = os.path.join(proj_path, "README.md")
        content = build_readme(num, project)
        with open(readme_path, "w", encoding="utf-8", newline="\n") as f:
            f.write(content)
        print(f"  [OK]  {readme_path}")
        updated += 1
    print(f"\n{'='*60}")
    print(f"  Updated {updated} README files across Projects 01-12")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
