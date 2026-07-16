# Testing Procedures

## Test Methods Available

Three ways to test the API:

1. **PowerShell `Invoke-RestMethod`** — built into Windows, no extra tools
2. **AWS CLI Lambda invoke** — test Lambda in isolation before API Gateway
3. **curl** — cross-platform, useful from EC2 or Git Bash
4. **Postman** — GUI tool, good for manual exploration

---

## Method 1: Direct Lambda Test (Before API Gateway)

Tests Lambda logic without going through API Gateway. Useful for isolating issues.

```powershell
# Test create user
$PAYLOAD = '{"body":"{\"name\":\"Vinay Kumar\",\"email\":\"vinay@example.com\",\"role\":\"admin\"}","httpMethod":"POST","path":"/users","pathParameters":null}'

aws lambda invoke `
  --function-name users-api `
  --payload $PAYLOAD `
  --cli-binary-format raw-in-base64-out `
  response.json

Get-Content response.json | ConvertFrom-Json | ConvertTo-Json -Depth 10

# Test list users
$LIST = '{"httpMethod":"GET","path":"/users","pathParameters":null}'

aws lambda invoke `
  --function-name users-api `
  --payload $LIST `
  --cli-binary-format raw-in-base64-out `
  response-list.json

Get-Content response-list.json | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

---

## Method 2: PowerShell Invoke-RestMethod (Full API Test)

```powershell
$API_URL = "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod"

# ── CREATE ─────────────────────────────────────────────────────────────
Write-Host "TEST 1: POST /users" -ForegroundColor Cyan
$r1 = Invoke-RestMethod -Uri "$API_URL/users" -Method POST `
  -ContentType "application/json" `
  -Body '{"name":"Vinay Kumar","email":"vinay@example.com","role":"admin"}'

Write-Host "Status: 201 expected"
Write-Host "User ID: $($r1.user.userId)"
$ID1 = $r1.user.userId

# ── LIST ───────────────────────────────────────────────────────────────
Write-Host "TEST 2: GET /users" -ForegroundColor Cyan
$r2 = Invoke-RestMethod -Uri "$API_URL/users" -Method GET
Write-Host "Count: $($r2.count) (expect 1+)"

# ── GET ONE ────────────────────────────────────────────────────────────
Write-Host "TEST 3: GET /users/{id}" -ForegroundColor Cyan
$r3 = Invoke-RestMethod -Uri "$API_URL/users/$ID1" -Method GET
Write-Host "Name: $($r3.user.name)"

# ── UPDATE ─────────────────────────────────────────────────────────────
Write-Host "TEST 4: PUT /users/{id}" -ForegroundColor Cyan
$r4 = Invoke-RestMethod -Uri "$API_URL/users/$ID1" -Method PUT `
  -ContentType "application/json" `
  -Body '{"role":"superadmin","name":"Vinay Kumar - Updated"}'
Write-Host "New role: $($r4.user.role)"

# ── 404 TEST ───────────────────────────────────────────────────────────
Write-Host "TEST 5: GET non-existent user (expect 404)" -ForegroundColor Cyan
try {
    Invoke-RestMethod -Uri "$API_URL/users/does-not-exist-12345" -Method GET
} catch {
    Write-Host "404 received correctly: $($_.Exception.Response.StatusCode)"
}

# ── DELETE ─────────────────────────────────────────────────────────────
Write-Host "TEST 6: DELETE /users/{id}" -ForegroundColor Cyan
$r6 = Invoke-RestMethod -Uri "$API_URL/users/$ID1" -Method DELETE
Write-Host "Message: $($r6.message)"

# ── VERIFY DELETION ────────────────────────────────────────────────────
Write-Host "TEST 7: GET /users (verify deletion)" -ForegroundColor Cyan
$r7 = Invoke-RestMethod -Uri "$API_URL/users" -Method GET
Write-Host "Count after delete: $($r7.count)"

Write-Host "" 
Write-Host "=== ALL TESTS COMPLETE ===" -ForegroundColor Green
```

---

## Method 3: curl

```bash
API_URL="https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod"

# Create user
curl -X POST "$API_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"name":"Vinay Kumar","email":"vinay@example.com","role":"admin"}' \
  | python3 -m json.tool

# List users
curl -X GET "$API_URL/users" | python3 -m json.tool

# Get single user (replace with actual ID)
USER_ID="550e8400-e29b-41d4-a716-446655440000"
curl -X GET "$API_URL/users/$USER_ID" | python3 -m json.tool

# Update user
curl -X PUT "$API_URL/users/$USER_ID" \
  -H "Content-Type: application/json" \
  -d '{"role":"superadmin"}' \
  | python3 -m json.tool

# Delete user
curl -X DELETE "$API_URL/users/$USER_ID" | python3 -m json.tool
```

---

## Method 4: Postman

1. Open Postman → New Collection → "Project 8 — Serverless API"
2. Set collection variable: `base_url = https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod`
3. Add requests:

| Request | Method | URL | Body |
|---|---|---|---|
| Create User | POST | `{{base_url}}/users` | `{"name":"...", "email":"..."}` |
| List Users | GET | `{{base_url}}/users` | — |
| Get User | GET | `{{base_url}}/users/{{userId}}` | — |
| Update User | PUT | `{{base_url}}/users/{{userId}}` | `{"role":"admin"}` |
| Delete User | DELETE | `{{base_url}}/users/{{userId}}` | — |

4. After creating a user, copy the `userId` from the response and set it as the `userId` collection variable.

---

## Expected Test Results

| Test | Method | Endpoint | Expected Status | Key Assertion |
|---|---|---|---|---|
| Create user | POST | /users | 201 | `user.userId` is a UUID |
| Create with missing fields | POST | /users | 400 | `error` contains "Missing required fields" |
| List users | GET | /users | 200 | `count` matches DynamoDB item count |
| Get existing user | GET | /users/{id} | 200 | `user.userId` matches requested ID |
| Get non-existent user | GET | /users/bad-id | 404 | `error` contains "not found" |
| Update user | PUT | /users/{id} | 200 | `user.updatedAt` is newer than `user.createdAt` |
| Update non-existent | PUT | /users/bad-id | 404 | `error` contains "not found" |
| Delete user | DELETE | /users/{id} | 200 | `message` contains "deleted successfully" |
| Delete already deleted | DELETE | /users/{id} | 404 | `error` contains "not found" |

---

## Verifying in DynamoDB Console

After running tests:

```powershell
# CLI scan — see all remaining items
aws dynamodb scan `
  --table-name users `
  --query "Items[*].{ID:userId.S,Name:name.S,Email:email.S,Role:role.S,Updated:updatedAt.S}" `
  --output table
```

Console: `DynamoDB → Tables → users → Explore table items`

---

## Reading CloudWatch Logs

After API calls, Lambda writes logs:

```powershell
# Get latest log stream
$STREAM = aws logs describe-log-streams `
  --log-group-name "/aws/lambda/users-api" `
  --order-by LastEventTime --descending --max-items 1 `
  --query "logStreams[0].logStreamName" --output text

# Read the log
aws logs get-log-events `
  --log-group-name "/aws/lambda/users-api" `
  --log-stream-name $STREAM `
  --query "events[*].message" --output text
```

Each invocation produces:
```
START RequestId: xxx Version: $LATEST
Event: {"httpMethod": "POST", "path": "/users", ...}
END RequestId: xxx
REPORT RequestId: xxx  Duration: 45.23 ms  Billed Duration: 46 ms  Memory Size: 128 MB  Max Memory Used: 52 MB
```

The `Event:` line is from `print(f"Event: {json.dumps(event)}")` in the handler. This is useful for debugging — you see exactly what API Gateway sent.


