<div align="center">
  <h1><img src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/aws/aws.png" width="36" height="36" style="vertical-align: middle"/> Project 02: Static Website Hosting on S3 + CloudFront CDN</h1>

  <p><i>Deploy a production-grade static website using Amazon S3 for origin storage and CloudFront as a global content delivery network. This project covers bucket policies, Origin Access Control (OAC), cache behaviors, and custom error pages — delivering sub-100ms latency worldwide.</i></p>

  <p>
    <img src="https://img.shields.io/badge/Level-Beginner-blue" alt="Level"/>
    <img src="https://img.shields.io/badge/Time-2--3%20Hours-orange" alt="Time"/>
    <img src="https://img.shields.io/badge/Cost-$0.00%20(Free%20Tier)-brightgreen" alt="Cost"/>
    <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License"/>
    <img src="https://img.shields.io/badge/Build-Passing-success" alt="Build"/>
  </p>

  <p>
    <a href="#-infrastructure-specifications">Infrastructure</a> · 
    <a href="#-key-components">Components</a> · 
    <a href="#-core-features">Features</a> · 
    <a href="#-setup--installation">Setup</a> · 
    <a href="#-documentation-suite">Docs</a>
  </p>

</div>

<br/>

<div align="center">

## 🏗️ Architecture Overview

<img src="./architecture/architectural-diagram.svg" alt="Static Website Hosting on S3 + CloudFront CDN — System Architecture" width="800"/>

<p><i>▲ High-level architecture diagram showing the interaction between S3, CloudFront, Route 53, ACM services</i></p>

</div>

## 📐 Infrastructure Specifications

| Resource | Configuration |
|:---------|:--------------|
| **S3 Bucket** | Static website origin bucket with versioning enabled; public access blocked at bucket level |
| **Bucket Policy** | Allows only CloudFront OAC principal (`cloudfront.amazonaws.com`) via `s3:GetObject` |
| **CloudFront Distribution** | HTTPS-only, TLSv1.2_2021, HTTP/2 + HTTP/3, gzip + Brotli compression |
| **Origin Access Control** | Replaces legacy OAI; scoped to the single S3 origin with signing protocol SigV4 |
| **Cache Policy** | CachingOptimized managed policy (TTL 86400s); custom policy for `index.html` (TTL 300s) |
| **Error Pages** | Custom 404.html with 200 response code for SPA client-side routing |
| **Region** | ap-south-1 (S3 bucket); CloudFront edge locations are global |

## 🧩 Key Components

### S3 Static Website Origin
Versioned bucket storing HTML, CSS, JS, and image assets with server-side encryption (SSE-S3)

### CloudFront Distribution
Global edge cache with 450+ Points of Presence; HTTPS termination via ACM certificate

### Origin Access Control (OAC)
SigV4-based authentication replacing legacy OAI; ensures S3 is only accessible via CloudFront

### Cache Behaviors
Path-pattern rules (`/assets/*` → long TTL, `/*.html` → short TTL) for optimal freshness

### Custom Error Responses
Maps S3 403/404 errors to `/index.html` with 200 status for single-page applications

### CloudFront Functions
Lightweight edge compute for URL rewrites, security headers, and A/B testing

## ⚡ Core Features

- **Zero-Downtime Deployment** – Upload new assets to S3, then issue a CloudFront invalidation (`/*`)
- **HTTPS Everywhere** – ACM-issued TLS certificate with automatic renewal; HTTP → HTTPS redirect
- **Sub-100ms Global Latency** – CloudFront edge caching with Brotli compression and HTTP/3 support
- **SPA-Ready Routing** – Custom error responses rewrite all 404s to `index.html` for React/Vue/Angular apps
- **Versioned Rollback** – S3 versioning enables instant rollback to any previous deployment
- **Security Headers** – CloudFront Function injects `Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options`
- **Cost-Optimized Caching** – Separate cache policies for static assets (24h TTL) and HTML (5min TTL)

## 🛠️ Setup & Installation

### Prerequisites

- AWS CLI v2 configured with IAM credentials (from Project 01)
- A registered domain name (optional, for custom domain setup)
- Static website files (HTML, CSS, JS) ready for deployment
- Node.js 18+ (optional, for building frontend frameworks)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects.git
cd project-02-s3-static-website

# 2. Configure environment variables
cp .env.example .env
# Edit .env with your specific values (see Environment Variables below)
```

### Environment Variables

Create a `.env` file in the project root:

```bash
export AWS_REGION="ap-south-1"
export BUCKET_NAME="my-static-website-bucket"
export DISTRIBUTION_ID="E1EXAMPLE12345"
export DOMAIN_NAME="example.com"
```

### Run Commands

Choose your platform and execute the scripts in order:

<table>
<tr><th>Step</th><th>Script</th><th>Description</th></tr>
<tr><td>🐧</td><td><code>scripts/bash/deploy.sh</code></td><td>Execute Deploy</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/deploy.ps1</code></td><td>Execute Deploy</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/invalidate_cache.sh</code></td><td>Execute Invalidate_cache</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/invalidate_cache.ps1</code></td><td>Execute Invalidate_cache</td></tr>
<tr><td>🐧</td><td><code>scripts/bash/cleanup.sh</code></td><td>Execute Cleanup</td></tr>
<tr><td>🖥️</td><td><code>scripts/powershell/cleanup.ps1</code></td><td>Execute Cleanup</td></tr>
</table>

## 📚 Documentation Suite

| Document | Description |
|:---------|:------------|
| 📄 [Project Overview](docs/project-overview.md) | Comprehensive project context, goals, and learning outcomes |
| 🏗️ [Architecture Details](docs/architecture.md) | Deep-dive into system design, data flow, and component interactions |
| 🚀 [Deployment Guide](docs/deployment-guide.md) | Step-by-step deployment procedures for dev, staging, and production |
| 🔐 [Security Protocols](docs/security-protocols.md) | IAM policies, encryption, network security, and compliance controls |
| 🧪 [Testing Procedures](docs/testing-procedures.md) | Validation scripts, smoke tests, and integration test suites |
| 🛠️ [Troubleshooting](docs/troubleshooting.md) | Common issues, error codes, debugging steps, and resolution guides |
| 🧹 [Cleanup Guide](docs/cleanup-guide.md) | Instructions for tearing down AWS resources to avoid charges |

## 🤝 Contribution & Maintenance

### Testing

- `curl -I https://<distribution-domain>` – Verify `x-cache: Hit from cloudfront` header
- `aws s3api get-bucket-versioning --bucket $BUCKET_NAME` – Confirm versioning is Enabled
- `curl -o /dev/null -s -w '%{http_code}' https://<domain>/nonexistent` – Expect 200 (SPA routing)
- Open browser DevTools → Network tab → verify Brotli (`content-encoding: br`) on CSS/JS assets
- `aws cloudfront get-distribution --id $DISTRIBUTION_ID` – Validate OAC configuration

### Deployment

For full production deployment procedures, see the [Deployment Guide](docs/deployment-guide.md).

### Contributing

1. **Fork** the repository and create a feature branch (`git checkout -b feature/amazing-feature`)
2. **Commit** your changes (`git commit -m "Add amazing feature"`)
3. **Push** to the branch (`git push origin feature/amazing-feature`)
4. **Open** a Pull Request with a detailed description
5. Ensure all scripts exist in **both** `scripts/powershell/` and `scripts/bash/`

### License

This project is licensed under the **MIT License** — see the [LICENSE](../project-02-s3-static-website/LICENSE) file for details.

### Contact & Credits

- **Author:** Vinay Kumar
- **GitHub:** [@vinay1515](https://github.com/vinay1515)
- **Repository:** [Vinay_kumar_AWS_Beginner_level_projects](https://github.com/vinay1515/Vinay_kumar_AWS_Beginner_level_projects)

---

<div align="center">
    <b><a href="../project-01-iam-setup">⬅️ Previous: Project 01</a> &nbsp;|&nbsp; <a href="../project-03-Launch-EC2-Connect-via-SSH">Next: Project 03 ➡️</a></b>
</div>