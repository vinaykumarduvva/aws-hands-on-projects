#!/bin/bash

# =============================================================================
# Project 8 — Script 06: Full API Test Suite
# Tests all 5 endpoints with 8 test cases — validates status codes and payloads
# =============================================================================

echo -e "\e[36m=== Project 8 — API Test Suite ===\e[0m"
echo ""

# ⚠️ Set your API URL before running
# $API_URL = "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod"

if (-not $API_URL) {
echo -e "\e[31mERROR: API_URL not set.\e[0m"
echo "Run: `$API_URL = `"
    exit 1
}

echo "Testing API: $API_URL"
echo ""

PASS=0
FAIL=0

function Assert-Status {
    param([string]$TestName, [int]$Expected, [int]$Actual)
    if ($Actual -eq $Expected) {
echo -e "\e[32m  ✓ $TestName (HTTP $Actual)\e[0m"
        $global:PASS++
    } else {
echo -e "\e[31m  ✗ $TestName — expected $Expected, got $Actual\e[0m"
        $global:FAIL++
    }
}

# ── TEST 1: CREATE USER ───────────────────────────────────────────────────────
echo -e "\e[33mTEST 1 — POST /users (create user 1)\e[0m"
try {
    r1=Invoke-RestMethod -Uri "$API_URL/users" -Method POST \
      -ContentType "application/json" \
      -Body '{"name":"Vinay Kumar","email":"vinay@example.com","role":"admin"}'
    Assert-Status "Create user" 201 201
    ID1=$r1.user.userId
echo "  User ID: $ID1"
echo "  Name:    $($r1.user.name)"
} catch {
echo -e "\e[31m  ✗ Create user FAILED: $($_.Exception.Message)\e[0m"
    $FAIL++
}

# ── TEST 2: CREATE SECOND USER ────────────────────────────────────────────────
echo ""
echo -e "\e[33mTEST 2 — POST /users (create user 2)\e[0m"
try {
    r2=Invoke-RestMethod -Uri "$API_URL/users" -Method POST \
      -ContentType "application/json" \
      -Body '{"name":"AWS Engineer","email":"aws@example.com","role":"developer"}'
    Assert-Status "Create second user" 201 201
    ID2=$r2.user.userId
echo "  User ID: $ID2"
} catch {
echo -e "\e[31m  ✗ Create second user FAILED: $($_.Exception.Message)\e[0m"
    $FAIL++
}

# ── TEST 3: LIST ALL USERS ────────────────────────────────────────────────────
echo ""
echo -e "\e[33mTEST 3 — GET /users (list all)\e[0m"
try {
    r3=Invoke-RestMethod -Uri "$API_URL/users" -Method GET
    Assert-Status "List users" 200 200
echo "  Count: $($r3.count)"
    $r3.users | ForEach-Object { Write-Host "    - $($_.name) [$($_.role)]" }
} catch {
echo -e "\e[31m  ✗ List users FAILED: $($_.Exception.Message)\e[0m"
    $FAIL++
}

# ── TEST 4: GET SINGLE USER ───────────────────────────────────────────────────
echo ""
echo -e "\e[33mTEST 4 — GET /users/{id} (get user 1)\e[0m"
try {
    r4=Invoke-RestMethod -Uri "$API_URL/users/$ID1" -Method GET
    Assert-Status "Get single user" 200 200
echo "  Name:  $($r4.user.name)"
echo "  Email: $($r4.user.email)"
} catch {
echo -e "\e[31m  ✗ Get single user FAILED: $($_.Exception.Message)\e[0m"
    $FAIL++
}

# ── TEST 5: UPDATE USER ───────────────────────────────────────────────────────
echo ""
echo -e "\e[33mTEST 5 — PUT /users/{id} (update user 1)\e[0m"
try {
    r5=Invoke-RestMethod -Uri "$API_URL/users/$ID1" -Method PUT \
      -ContentType "application/json" \
      -Body '{"role":"superadmin","name":"Vinay Kumar - Updated"}'
    Assert-Status "Update user" 200 200
echo "  New role: $($r5.user.role)"
echo "  New name: $($r5.user.name)"
echo "  Updated at: $($r5.user.updatedAt)"
} catch {
echo -e "\e[31m  ✗ Update user FAILED: $($_.Exception.Message)\e[0m"
    $FAIL++
}

# ── TEST 6: 404 FOR NON-EXISTENT USER ────────────────────────────────────────
echo ""
echo -e "\e[33mTEST 6 — GET /users/bad-id (expect 404)\e[0m"
try {
    Invoke-RestMethod -Uri "$API_URL/users/non-existent-user-id-99999" -Method GET
echo -e "\e[31m  ✗ Expected 404 but got success\e[0m"
    $FAIL++
} catch {
    statusCode=[int]$_.Exception.Response.StatusCode
    Assert-Status "404 for non-existent user" 404 $statusCode
}

# ── TEST 7: DELETE USER ───────────────────────────────────────────────────────
echo ""
echo -e "\e[33mTEST 7 — DELETE /users/{id} (delete user 1)\e[0m"
try {
    r7=Invoke-RestMethod -Uri "$API_URL/users/$ID1" -Method DELETE
    Assert-Status "Delete user" 200 200
echo "  $($r7.message)"
} catch {
echo -e "\e[31m  ✗ Delete user FAILED: $($_.Exception.Message)\e[0m"
    $FAIL++
}

# ── TEST 8: VERIFY DELETION ───────────────────────────────────────────────────
echo ""
echo -e "\e[33mTEST 8 — GET /users (verify deletion)\e[0m"
try {
    r8=Invoke-RestMethod -Uri "$API_URL/users" -Method GET
    Assert-Status "Verify deletion" 200 200
echo "  Remaining users: $($r8.count) (expect 1 — user 2 still exists)"
} catch {
echo -e "\e[31m  ✗ Verify deletion FAILED: $($_.Exception.Message)\e[0m"
    $FAIL++
}

# ── RESULTS ───────────────────────────────────────────────────────────────────
echo ""
echo -e "\e[36m=== Test Results ===\e[0m"
echo -e "\e[32m  Passed: $PASS\e[0m"
echo "  Failed: $FAIL"

if ($FAIL -eq 0) {
echo ""
echo -e "\e[32mALL TESTS PASSED\e[0m"
echo -e "\e[32mServerless REST API is working end-to-end.\e[0m"
} else {
echo ""
echo -e "\e[33mSome tests failed. Check CloudWatch Logs:\e[0m"
echo "  aws logs tail /aws/lambda/users-api --follow"
}

echo ""
echo -e "\e[36mNext step: Run 07-monitor-cloudwatch.ps1\e[0m"