# API Endpoints Reference

Base URL: `https://{API_ID}.execute-api.us-east-1.amazonaws.com/prod`

---

## POST /users — Create User

Creates a new user record with a generated UUID.

**Request**
```
POST /users
Content-Type: application/json
```
```json
{
  "name":  "Vinay Kumar",
  "email": "vinay@example.com",
  "role":  "admin"
}
```

**Required fields**: `name`, `email`
**Optional fields**: `role` (defaults to `"user"` if omitted)

**Response 201 — Created**
```json
{
  "message": "User created successfully",
  "user": {
    "userId":    "550e8400-e29b-41d4-a716-446655440000",
    "name":      "Vinay Kumar",
    "email":     "vinay@example.com",
    "role":      "admin",
    "createdAt": "2025-06-01T10:30:00.123456",
    "updatedAt": "2025-06-01T10:30:00.123456"
  }
}
```

**Response 400 — Bad Request**
```json
{ "error": "Missing required fields: name and email" }
```

**PowerShell test**
```powershell
Invoke-RestMethod -Uri "$API_URL/users" -Method POST `
  -ContentType "application/json" `
  -Body '{"name":"Vinay Kumar","email":"vinay@example.com","role":"admin"}'
```

---

## GET /users — List All Users

Returns all users from the DynamoDB table via Scan.

**Request**
```
GET /users
```

**Response 200 — OK**
```json
{
  "message": "Found 2 users",
  "count": 2,
  "users": [
    {
      "userId":    "550e8400-...",
      "name":      "Vinay Kumar",
      "email":     "vinay@example.com",
      "role":      "admin",
      "createdAt": "2025-06-01T10:30:00.123456",
      "updatedAt": "2025-06-01T10:30:00.123456"
    },
    {
      "userId":    "7c9e6679-...",
      "name":      "AWS Engineer",
      "email":     "aws@example.com",
      "role":      "developer",
      "createdAt": "2025-06-01T10:31:00.456789",
      "updatedAt": "2025-06-01T10:31:00.456789"
    }
  ]
}
```

**Note on DynamoDB Scan**: Scan reads every item in the table. For large tables (>1MB) it paginates automatically. This is acceptable for small datasets; production systems use Query with indexes or paginated Scan with `ExclusiveStartKey`.

**PowerShell test**
```powershell
Invoke-RestMethod -Uri "$API_URL/users" -Method GET
```

---

## GET /users/{userId} — Get Single User

Returns one user by their UUID partition key.

**Request**
```
GET /users/550e8400-e29b-41d4-a716-446655440000
```

**Response 200 — OK**
```json
{
  "user": {
    "userId":    "550e8400-e29b-41d4-a716-446655440000",
    "name":      "Vinay Kumar",
    "email":     "vinay@example.com",
    "role":      "admin",
    "createdAt": "2025-06-01T10:30:00.123456",
    "updatedAt": "2025-06-01T10:30:00.123456"
  }
}
```

**Response 404 — Not Found**
```json
{ "error": "User 550e8400-... not found" }
```

**PowerShell test**
```powershell
Invoke-RestMethod -Uri "$API_URL/users/$USER_ID" -Method GET
```

---

## PUT /users/{userId} — Update User

Updates one or more attributes of an existing user. Only `name`, `email`, and `role` are modifiable. `userId`, `createdAt` are immutable. `updatedAt` is always updated automatically.

**Request**
```
PUT /users/550e8400-e29b-41d4-a716-446655440000
Content-Type: application/json
```
```json
{
  "role": "superadmin",
  "name": "Vinay Kumar - Updated"
}
```

**Response 200 — OK**
```json
{
  "message": "User updated successfully",
  "user": {
    "userId":    "550e8400-e29b-41d4-a716-446655440000",
    "name":      "Vinay Kumar - Updated",
    "email":     "vinay@example.com",
    "role":      "superadmin",
    "createdAt": "2025-06-01T10:30:00.123456",
    "updatedAt": "2025-06-01T10:45:00.789012"
  }
}
```

**Response 404 — Not Found**
```json
{ "error": "User 550e8400-... not found" }
```

**Note on partial updates**: The update expression is built dynamically from whatever fields are present in the request body. Sending only `{"role":"superadmin"}` updates only `role` and `updatedAt` — all other attributes are untouched. This is native DynamoDB `UpdateItem` behaviour.

**PowerShell test**
```powershell
Invoke-RestMethod -Uri "$API_URL/users/$USER_ID" -Method PUT `
  -ContentType "application/json" `
  -Body '{"role":"superadmin","name":"Vinay Kumar - Updated"}'
```

---

## DELETE /users/{userId} — Delete User

Permanently removes a user from DynamoDB.

**Request**
```
DELETE /users/550e8400-e29b-41d4-a716-446655440000
```

**Response 200 — OK**
```json
{ "message": "User 550e8400-... deleted successfully" }
```

**Response 404 — Not Found**
```json
{ "error": "User 550e8400-... not found" }
```

**Note**: This implementation checks for existence before deleting to return a meaningful 404. DynamoDB's `delete_item` is idempotent by default (no error on non-existent key) — the existence check is done explicitly via `get_item`.

**PowerShell test**
```powershell
Invoke-RestMethod -Uri "$API_URL/users/$USER_ID" -Method DELETE
```

---

## Error Responses

All errors return JSON with an `error` field.

| Status | Meaning | When |
|---|---|---|
| 400 | Bad Request | Missing required fields in POST body |
| 404 | Not Found | `userId` does not exist in DynamoDB |
| 500 | Internal Server Error | Unhandled exception (DynamoDB down, permission error) |

**CORS**: All responses include `Access-Control-Allow-Origin: *`. This allows the API to be called directly from browser JavaScript without a server-side proxy. The `OPTIONS` method returns 200 for preflight requests.

---

## Test Sequence (Complete)

```powershell
# 1. Create user 1
$u1 = Invoke-RestMethod -Uri "$API_URL/users" -Method POST -ContentType "application/json" `
  -Body '{"name":"Vinay Kumar","email":"vinay@example.com","role":"admin"}'
$ID1 = $u1.user.userId

# 2. Create user 2
$u2 = Invoke-RestMethod -Uri "$API_URL/users" -Method POST -ContentType "application/json" `
  -Body '{"name":"AWS Engineer","email":"aws@example.com","role":"developer"}'
$ID2 = $u2.user.userId

# 3. List all (expect 2)
Invoke-RestMethod -Uri "$API_URL/users" -Method GET

# 4. Get user 1
Invoke-RestMethod -Uri "$API_URL/users/$ID1" -Method GET

# 5. Update user 1
Invoke-RestMethod -Uri "$API_URL/users/$ID1" -Method PUT -ContentType "application/json" `
  -Body '{"role":"superadmin"}'

# 6. Test 404
try { Invoke-RestMethod -Uri "$API_URL/users/bad-id" -Method GET } catch { "404 OK" }

# 7. Delete user 1
Invoke-RestMethod -Uri "$API_URL/users/$ID1" -Method DELETE

# 8. Verify deletion (expect 1)
Invoke-RestMethod -Uri "$API_URL/users" -Method GET
```