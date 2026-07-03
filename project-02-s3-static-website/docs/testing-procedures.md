# Testing & Validation Procedures

To ensure your S3 Static Website is configured correctly and securely, follow these validation steps.

---

## 🧪 Scenario 1: Validate Website Accessibility

**Goal:** Prove that the website is accessible via the internet without requiring AWS credentials.

1. Obtain your **Bucket website endpoint URL** from the S3 Console Properties tab (e.g., `http://portfolio-website.s3-website-us-east-1.amazonaws.com`).
2. Open an Incognito/Private browsing window. This ensures your browser isn't using any cached AWS login tokens.
3. Navigate to the URL.
4. **Expected Outcome:** The HTML portfolio page loads perfectly, displaying the text and CSS styles.

---

## 🧪 Scenario 2: Validate the Index Document Routing

**Goal:** Prove that S3 is correctly routing root requests to `index.html`.

1. In your browser, explicitly append `/index.html` to your URL (e.g., `http://...amazonaws.com/index.html`).
2. **Expected Outcome:** The exact same page loads. S3's static hosting engine is correctly masking the `/index.html` path when you visit the root domain.

---

## 🧪 Scenario 3: Validate the Error Document (404)

**Goal:** Prove that S3 handles bad URLs gracefully.

1. In your browser, navigate to a path that does not exist in your bucket (e.g., `http://...amazonaws.com/doesnotexist.html`).
2. **Expected Outcome:**
   - If you uploaded an `error.html` file and configured it in the Static Website properties, you should see that custom error page.
   - If you did not, S3 will return a default `404 Not Found` XML error response. This proves S3 is actively evaluating the request path.

---

## 🧪 Scenario 4: Validate Security Boundaries (Write Protection)

**Goal:** Prove that while the public can read your website, they cannot deface it.

1. Open your terminal.
2. Attempt to write a file anonymously to your bucket using the `curl` command (or simply understand that without AWS credentials, an upload API call will fail).
3. If you have the AWS CLI configured, run:
   ```powershell
   aws s3 rm s3://<YOUR_BUCKET_NAME>/index.html --no-sign-request
   ```
4. **Expected Outcome:** `Access Denied`. The Bucket Policy strictly enforces `s3:GetObject` and rejects `s3:DeleteObject` for anonymous users. Your website is safe from defacement.