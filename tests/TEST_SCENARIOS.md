# API Gateway & Backend Testing Guide

## System Overview
- **API Gateway** (Port 4000): Secure layer with JWT auth, input validation, rate limiting
- **Insecure Backend** (Port 3000): Intentionally vulnerable backend for comparison
- **Security Dashboard** (Port 5000): Monitors and analyzes security events

---

## 1. API GATEWAY TESTS (Port 4000) - SECURE

### 1.1 Authentication Tests

#### ✅ Test 1.1.1: Successful Login
**Expected**: Get JWT token
```bash
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"user"}'
```
**Expected Response**: 
```json
{"message":"Login successful","token":"eyJhbGc..."}
```

#### ✅ Test 1.1.2: Admin Login
**Expected**: Get JWT token with admin role
```bash
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin"}'
```

#### ✅ Test 1.1.3: Missing Credentials
**Expected**: Still returns token (simulated login)
```bash
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

### 1.2 Authorization & Role-Based Access Control

#### ✅ Test 1.2.1: Admin-Only Delete - With Admin Token
**Expected**: Success (only admins can delete)
```bash
# First get admin token
TOKEN=$(curl -s -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin"}' | jq -r '.token')

# Then delete user
curl -X DELETE http://localhost:4000/api/users/2 \
  -H "Authorization: Bearer $TOKEN"
```
**Expected Response**: 
```json
{"message":"User deleted (admin only action allowed)"}
```

#### ❌ Test 1.2.2: Admin-Only Delete - With User Token
**Expected**: Rejected (user has no permission)
```bash
# Get user token
TOKEN=$(curl -s -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"user"}' | jq -r '.token')

# Try to delete
curl -X DELETE http://localhost:4000/api/users/2 \
  -H "Authorization: Bearer $TOKEN"
```
**Expected Response**: 
```json
{"message":"Access denied: insufficient permissions"}
```

#### ❌ Test 1.2.3: Missing Authorization Header
**Expected**: 401 Unauthorized
```bash
curl -X DELETE http://localhost:4000/api/users/2
```
**Expected Response**:
```json
{"message":"No token provided"}
```

#### ❌ Test 1.2.4: Invalid Token
**Expected**: 403 Forbidden
```bash
curl -X DELETE http://localhost:4000/api/users/2 \
  -H "Authorization: Bearer invalid_token_123"
```
**Expected Response**:
```json
{"message":"Invalid or expired token"}
```

#### ❌ Test 1.2.5: Malformed Authorization Header
**Expected**: Error
```bash
curl -X DELETE http://localhost:4000/api/users/2 \
  -H "Authorization: invalid_format"
```

---

### 1.3 Input Validation Tests (Security Against Attacks)

#### ✅ Test 1.3.1: SQL Injection Detection
**Expected**: Request blocked, status 400
```bash
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin OR 1=1--"}'
```
**Expected Response**:
```json
{"message":"Blocked: SQL Injection detected"}
```

#### ✅ Test 1.3.2: SQL Injection with DROP
**Expected**: Blocked
```bash
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin; DROP TABLE users;--"}'
```

#### ✅ Test 1.3.3: SQL Injection with SELECT
**Expected**: Blocked
```bash
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin\" UNION SELECT * FROM passwords--"}'
```

#### ✅ Test 1.3.4: XSS Attack Detection
**Expected**: Request blocked
```bash
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"<script>alert(1)</script>"}'
```
**Expected Response**:
```json
{"message":"Blocked: XSS attack detected"}
```

#### ✅ Test 1.3.5: XSS with Event Handler
**Expected**: Blocked
```bash
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"<img src=x onerror=alert(1)>"}'
```

#### ✅ Test 1.3.6: XSS with JavaScript Protocol
**Expected**: Blocked
```bash
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"<a href=\"javascript:alert(1)\">click</a>"}'
```

#### ✅ Test 1.3.7: URL-Encoded Attack
**Expected**: Blocked (decoded before checking)
```bash
curl -X POST http://localhost:4000/api/login?data=%3Cscript%3E \
  -H "Content-Type: application/json" \
  -d '{"username":"test"}'
```

---

### 1.4 Rate Limiting Tests

#### ✅ Test 1.4.1: Rate Limit Exceeded
**Expected**: After 5 requests per minute, get 429 Too Many Requests
```bash
for i in {1..6}; do
  curl -X POST http://localhost:4000/api/login \
    -H "Content-Type: application/json" \
    -d '{"username":"test"}' 
  echo "Request $i sent"
done
```
**Expected**: First 5 succeed, 6th is blocked with message about rate limit

#### ✅ Test 1.4.2: Rate Limit Reset
**Expected**: After 60 seconds, can make requests again
```bash
echo "Wait 61 seconds..."
sleep 61
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test"}'
```
**Expected**: Success

---

## 2. INSECURE BACKEND TESTS (Port 3000) - VULNERABLE

### 2.1 Home Route

#### Test 2.1.1: Access Home Page
```bash
curl http://localhost:3000/
```
**Response**: "INSECURE BACKEND RUNNING"

---

### 2.2 Login Vulnerabilities (NO PASSWORD CHECK)

#### ❌ Test 2.2.1: Login Without Password - Anyone Can Login
**Vulnerability**: No password verification
```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin"}'
```
**Response**: Success - no password required!
```json
{"message":"Login successful (insecure)","user":{"username":"admin","role":"admin"}}
```

#### ❌ Test 2.2.2: Login as Admin Without Password
```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"username":"hacker"}'
```
**Vulnerability**: Becomes admin if username is "admin", even without credentials

---

### 2.3 Data Exposure - No Authentication Required

#### ❌ Test 2.3.1: Get All Users (NO AUTH)
**Vulnerability**: Anyone can see all users with credentials
```bash
curl http://localhost:3000/users
```
**Response**: Full user database exposed
```json
[
  {"id":1,"username":"admin","password":"admin123","role":"admin"},
  {"id":2,"username":"user","password":"user123","role":"user"}
]
```
**Impact**: Passwords are visible in plain text!

#### ❌ Test 2.3.2: Get Users Multiple Times
```bash
for i in {1..3}; do
  curl http://localhost:3000/users
  echo ""
done
```

---

### 2.4 Unauthorized Deletion - No Authorization Checks

#### ❌ Test 2.4.1: Delete User Without Any Auth
**Vulnerability**: Anyone can delete any user, no token needed
```bash
curl -X DELETE http://localhost:3000/users/1
```
**Response**: 
```json
{"message":"User deleted (no security check!)"}
```
**Verify user is deleted**:
```bash
curl http://localhost:3000/users
```

#### ❌ Test 2.4.2: Delete Non-Existent User
```bash
curl -X DELETE http://localhost:3000/users/999
```
**Vulnerability**: No validation on ID

#### ❌ Test 2.4.3: Delete with Script Injection in URL
**Vulnerability**: No input validation
```bash
curl -X DELETE "http://localhost:3000/users/1;DROP TABLE users;--"
```

---

## 3. SECURITY DASHBOARD TESTS (Port 5000)

### 3.1 Health Check

#### Test 3.1.1: Dashboard Health
```bash
curl http://localhost:5000/health
```
**Expected Response**:
```json
{"status":"ok","now":"2024-01-15T10:30:00.000Z"}
```

---

### 3.2 Logs Collection

#### Test 3.2.1: View All Logs
```bash
curl http://localhost:5000/logs
```
**Expected**: Array of logs from API Gateway and Backend

#### Test 3.2.2: View Recent Logs (Reversed Order)
```bash
curl http://localhost:5000/logs | jq 'first(.[]; .)'
```
**Expected**: Most recent logs first

#### Test 3.2.3: Filter High-Risk Logs
```bash
curl http://localhost:5000/logs | jq '.[] | select(.dread >= 8)'
```

---

### 3.3 Security Analysis Summary

#### Test 3.3.1: Get Security Summary
```bash
curl http://localhost:5000/summary
```
**Expected Response includes**:
```json
{
  "total": 25,
  "blocked": 5,
  "highRisk": 3,
  "averageDREAD": 6.2,
  "topUsers": [{"name":"admin","count":10}],
  "topEndpoints": [{"url":"/api/login","count":12}],
  "methods": {"POST":15,"GET":10},
  "statuses": {"200":20,"400":5},
  "stride": {"S":3,"T":2,"R":1,"I":2,"D":1,"E":1},
  "lastUpdate":"2024-01-15T10:35:00.000Z"
}
```

#### Test 3.3.2: Track Attack Prevention
**Run SQL injection test on Gateway, then check dashboard**:
```bash
# 1. Send SQL injection attack to gateway
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin OR 1=1"}'

# 2. Check dashboard for blocked logs
curl http://localhost:5000/logs | jq '.[] | select(.message | contains("Blocked"))'
```

---

## 4. COMPARATIVE SECURITY TESTS

### Test 4.1: SQL Injection Comparison

#### 4.1.1 Attack Gateway (PROTECTED)
```bash
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"\" OR \"1\"=\"1"}'
```
**Result**: ✅ BLOCKED - Status 400

#### 4.1.2 Attack Insecure Backend (VULNERABLE)
```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"username":"\" OR \"1\"=\"1"}'
```
**Result**: ❌ ACCEPTED - Returns success

---

### Test 4.2: Authentication Comparison

#### 4.2.1 Gateway Requires Token
```bash
curl http://localhost:4000/api/users
```
**Result**: ✅ 401 Unauthorized - No token provided

#### 4.2.2 Backend Has No Auth
```bash
curl http://localhost:3000/users
```
**Result**: ❌ 200 OK - Returns all users with passwords!

---

### Test 4.3: Authorization Comparison

#### 4.3.1 Gateway Enforces Roles
```bash
TOKEN=$(curl -s -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"user"}' | jq -r '.token')

curl -X DELETE http://localhost:4000/api/users/1 \
  -H "Authorization: Bearer $TOKEN"
```
**Result**: ✅ 403 Forbidden - User cannot delete

#### 4.3.2 Backend Has No Authorization
```bash
curl -X DELETE http://localhost:3000/users/1
```
**Result**: ❌ 200 OK - Anyone can delete users

---

## 5. LOAD & STRESS TESTS

### Test 5.1: Rate Limit Under Load
```bash
for i in {1..10}; do
  curl -s -X POST http://localhost:4000/api/login \
    -H "Content-Type: application/json" \
    -d '{"username":"stress"}'
done
```
**Expected**: 5 succeed, 5 fail with rate limit

### Test 5.2: Multiple Concurrent Requests
```bash
# Using GNU Parallel (install if needed: choco install parallel)
seq 1 20 | parallel "curl -s http://localhost:5000/health"
```

---

## 6. QUICK TEST SCRIPT

Create a file `run_tests.sh`:
```bash
#!/bin/bash

echo "=== API GATEWAY SECURE TESTS ==="
echo "1. Login..."
curl -s -X POST http://localhost:4000/api/login -H "Content-Type: application/json" -d '{"username":"admin"}' | jq '.'

echo -e "\n2. SQL Injection Detection..."
curl -s -X POST http://localhost:4000/api/login -H "Content-Type: application/json" -d '{"username":"admin OR 1=1"}' | jq '.'

echo -e "\n3. Rate Limiting..."
for i in {1..6}; do curl -s -X POST http://localhost:4000/api/login -H "Content-Type: application/json" -d '{"username":"test"}' | jq '.'; done

echo -e "\n=== INSECURE BACKEND VULNERABLE TESTS ==="
echo "4. Get All Users (NO AUTH)..."
curl -s http://localhost:3000/users | jq '.'

echo -e "\n5. Delete User (NO AUTH)..."
curl -s -X DELETE http://localhost:3000/users/1 | jq '.'

echo -e "\n=== DASHBOARD TESTS ==="
echo "6. Dashboard Summary..."
curl -s http://localhost:5000/summary | jq '.'
```

---

## 7. TESTING CHECKLIST

- [ ] API Gateway login works
- [ ] JWT tokens are generated
- [ ] SQL injection attempts are blocked
- [ ] XSS attempts are blocked  
- [ ] Rate limiting works (5 requests/min)
- [ ] Admin-only operations require admin token
- [ ] Regular users cannot delete other users
- [ ] Invalid tokens are rejected
- [ ] Insecure backend accepts unauthenticated requests
- [ ] Insecure backend exposes passwords
- [ ] Insecure backend allows deletion without auth
- [ ] Dashboard collects logs from both systems
- [ ] Dashboard calculates DREAD scores
- [ ] Dashboard shows blocked attacks in logs

---

## 8. SECURITY ISSUES TO DEMONSTRATE

### API Gateway (SECURE)
✅ JWT Authentication
✅ Role-Based Access Control  
✅ SQL Injection Prevention
✅ XSS Prevention
✅ Rate Limiting
✅ Request Logging

### Insecure Backend (VULNERABLE)
❌ No Password Validation
❌ No Authentication
❌ No Authorization
❌ Password Exposure
❌ SQL Injection Vulnerable
❌ No Input Validation
❌ No Rate Limiting

---

## 9. RECOMMENDED TEST ORDER

1. **Start with authentication** - Test login functionality
2. **Test authorization** - Verify role-based access
3. **Test input validation** - Send malicious payloads
4. **Test rate limiting** - Stress the gateway
5. **Compare systems** - Show secure vs vulnerable
6. **Check dashboard** - Verify logging and analysis
