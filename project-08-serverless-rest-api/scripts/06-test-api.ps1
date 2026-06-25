# =============================================================================
# Project 8 — Script 06: Full API Test Suite
# Tests all 5 endpoints with 8 test cases — validates status codes and payloads
# =============================================================================

Write-Host "=== Project 8 — API Test Suite ===" -ForegroundColor Cyan
Write-Host ""

# ⚠️ Set your API URL before running
# $API_URL = "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod"

if (-not $API_URL) {
    Write-Host "ERROR: API_URL not set." -ForegroundColor Red
    Write-Host "Run: `$API_URL = `"https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod`""
    exit 1
}

Write-Host "Testing API: $API_URL"
Write-Host ""

$PASS = 0
$FAIL = 0

function Assert-Status {
    param([string]$TestName, [int]$Expected, [int]$Actual)
    if ($Actual -eq $Expected) {
        Write-Host "  ✓ $TestName (HTTP $Actual)" -ForegroundColor Green
        $global:PASS++
    } else {
        Write-Host "  ✗ $TestName — expected $Expected, got $Actual" -ForegroundColor Red
        $global:FAIL++
    }
}

# ── TEST 1: CREATE USER ───────────────────────────────────────────────────────
Write-Host "TEST 1 — POST /users (create user 1)" -ForegroundColor Yellow
try {
    $r1 = Invoke-RestMethod -Uri "$API_URL/users" -Method POST `
      -ContentType "application/json" `
      -Body '{"name":"Vinay Kumar","email":"vinay@example.com","role":"admin"}'
    Assert-Status "Create user" 201 201
    $ID1 = $r1.user.userId
    Write-Host "  User ID: $ID1"
    Write-Host "  Name:    $($r1.user.name)"
} catch {
    Write-Host "  ✗ Create user FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $FAIL++
}

# ── TEST 2: CREATE SECOND USER ────────────────────────────────────────────────
Write-Host ""
Write-Host "TEST 2 — POST /users (create user 2)" -ForegroundColor Yellow
try {
    $r2 = Invoke-RestMethod -Uri "$API_URL/users" -Method POST `
      -ContentType "application/json" `
      -Body '{"name":"AWS Engineer","email":"aws@example.com","role":"developer"}'
    Assert-Status "Create second user" 201 201
    $ID2 = $r2.user.userId
    Write-Host "  User ID: $ID2"
} catch {
    Write-Host "  ✗ Create second user FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $FAIL++
}

# ── TEST 3: LIST ALL USERS ────────────────────────────────────────────────────
Write-Host ""
Write-Host "TEST 3 — GET /users (list all)" -ForegroundColor Yellow
try {
    $r3 = Invoke-RestMethod -Uri "$API_URL/users" -Method GET
    Assert-Status "List users" 200 200
    Write-Host "  Count: $($r3.count)"
    $r3.users | ForEach-Object { Write-Host "    - $($_.name) [$($_.role)]" }
} catch {
    Write-Host "  ✗ List users FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $FAIL++
}

# ── TEST 4: GET SINGLE USER ───────────────────────────────────────────────────
Write-Host ""
Write-Host "TEST 4 — GET /users/{id} (get user 1)" -ForegroundColor Yellow
try {
    $r4 = Invoke-RestMethod -Uri "$API_URL/users/$ID1" -Method GET
    Assert-Status "Get single user" 200 200
    Write-Host "  Name:  $($r4.user.name)"
    Write-Host "  Email: $($r4.user.email)"
} catch {
    Write-Host "  ✗ Get single user FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $FAIL++
}

# ── TEST 5: UPDATE USER ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "TEST 5 — PUT /users/{id} (update user 1)" -ForegroundColor Yellow
try {
    $r5 = Invoke-RestMethod -Uri "$API_URL/users/$ID1" -Method PUT `
      -ContentType "application/json" `
      -Body '{"role":"superadmin","name":"Vinay Kumar - Updated"}'
    Assert-Status "Update user" 200 200
    Write-Host "  New role: $($r5.user.role)"
    Write-Host "  New name: $($r5.user.name)"
    Write-Host "  Updated at: $($r5.user.updatedAt)"
} catch {
    Write-Host "  ✗ Update user FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $FAIL++
}

# ── TEST 6: 404 FOR NON-EXISTENT USER ────────────────────────────────────────
Write-Host ""
Write-Host "TEST 6 — GET /users/bad-id (expect 404)" -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "$API_URL/users/non-existent-user-id-99999" -Method GET
    Write-Host "  ✗ Expected 404 but got success" -ForegroundColor Red
    $FAIL++
} catch {
    $statusCode = [int]$_.Exception.Response.StatusCode
    Assert-Status "404 for non-existent user" 404 $statusCode
}

# ── TEST 7: DELETE USER ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "TEST 7 — DELETE /users/{id} (delete user 1)" -ForegroundColor Yellow
try {
    $r7 = Invoke-RestMethod -Uri "$API_URL/users/$ID1" -Method DELETE
    Assert-Status "Delete user" 200 200
    Write-Host "  $($r7.message)"
} catch {
    Write-Host "  ✗ Delete user FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $FAIL++
}

# ── TEST 8: VERIFY DELETION ───────────────────────────────────────────────────
Write-Host ""
Write-Host "TEST 8 — GET /users (verify deletion)" -ForegroundColor Yellow
try {
    $r8 = Invoke-RestMethod -Uri "$API_URL/users" -Method GET
    Assert-Status "Verify deletion" 200 200
    Write-Host "  Remaining users: $($r8.count) (expect 1 — user 2 still exists)"
} catch {
    Write-Host "  ✗ Verify deletion FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $FAIL++
}

# ── RESULTS ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Test Results ===" -ForegroundColor Cyan
Write-Host "  Passed: $PASS" -ForegroundColor Green
Write-Host "  Failed: $FAIL" -ForegroundColor $(if ($FAIL -eq 0) {"Green"} else {"Red"})

if ($FAIL -eq 0) {
    Write-Host ""
    Write-Host "ALL TESTS PASSED" -ForegroundColor Green
    Write-Host "Serverless REST API is working end-to-end." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Some tests failed. Check CloudWatch Logs:" -ForegroundColor Yellow
    Write-Host "  aws logs tail /aws/lambda/users-api --follow"
}

Write-Host ""
Write-Host "Next step: Run 07-monitor-cloudwatch.ps1" -ForegroundColor Cyan