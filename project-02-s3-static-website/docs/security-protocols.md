# Security Protocols & Compliance

Hosting a public website on AWS requires intentionally opening specific security boundaries while ensuring the rest of the account remains completely locked down. This project demonstrates how to safely expose assets without compromising security.

---

## 🔐 1. Block Public Access (BPA) Mechanics

In 2018, AWS introduced "S3 Block Public Access" in response to numerous high-profile enterprise data leaks. By default, all new S3 buckets have BPA turned **ON**.
- BPA acts as a master override switch. Even if a bucket policy or Object ACL explicitly grants public access, if BPA is ON, the request is denied.
- To host a public website, you must turn BPA **OFF** for that specific bucket.
- **Enterprise Best Practice:** In production, AWS accounts often have BPA turned ON at the *Account Level* via AWS Organizations. In those scenarios, you cannot host a static website directly from S3 to the public internet; you must use an Amazon CloudFront distribution (CDN) with Origin Access Control (OAC) to bypass the restriction securely.

---

## 🛡️ 2. The Bucket Policy (Resource-Based IAM)

When BPA is off, the bucket is still private by default. We must use a **Bucket Policy** (a JSON document attached directly to the S3 resource) to grant access.

```json
{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
}
```

### Deconstructing the Policy:
- `"Principal": "*"`: This is the most dangerous line in AWS. It means "Any anonymous user on the internet."
- `"Action": "s3:GetObject"`: This is the critical safety control. We are ONLY allowing users to *read* objects. We are explicitly NOT allowing `s3:PutObject` (uploading files) or `s3:DeleteObject`. 
- `"Resource": ".../*"`: We specify `/*` at the end of the ARN to apply this rule to every object inside the bucket, rather than the bucket itself.

---

## 🚧 3. Cross-Site Scripting (XSS) and CORS

Because you are hosting raw HTML/JS on S3, you are still vulnerable to client-side attacks like Cross-Site Scripting (XSS) if you include user input forms. Furthermore, if your S3 website attempts to call an external API (e.g., an API Gateway endpoint), you may run into Cross-Origin Resource Sharing (CORS) blocks in the browser. 

While not configured in this beginner lab, production S3 websites often require custom CORS configurations applied via the S3 console to allow the frontend to communicate with backend APIs safely.