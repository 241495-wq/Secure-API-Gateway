# Quick Testing Reference Guide

## 🚀 Quick Start Commands

### Windows (PowerShell)
```powershell
# Run the PowerShell test suite
.\tests\run_tests.ps1
```

### macOS/Linux (Bash)
```bash
# Run the Bash test suite
bash tests/run_tests.sh
```

---

## 📋 Test Categories at a Glance

### Category 1: Authentication & JWT (Port 4000)
| Test | Command | Expected | Status |
|------|---------|----------|--------|
| Admin Login | `POST /api/login` username=admin | Get JWT token | ✅ |
| User Login | `POST /api/login` username=user | Get JWT token | ✅ |
| Missing Token | Any `GET /api/*` without auth | 401 Unauthorized | ✅ |
| Invalid Token | Any request with bad token | 403 Forbidden | ✅ |

### Category 2: Input Validation (Port 4000)
| Attack Type | Payload | Result | Status |
|-------------|---------|--------|--------|
| SQL Injection | `OR 1=1` | Blocked 400 | ✅ |
| SQL Injection | `DROP TABLE` | Blocked 400 | ✅ |
| SQL Injection | `UNION SELECT` | Blocked 400 | ✅ |
| XSS | `<script>` | Blocked 400 | ✅ |
| XSS | `onerror=` | Blocked 400 | ✅ |
| XSS | `javascript:` | Blocked 400 | ✅ |

### Category 3: Authorization & RBAC (Port 4000)
| Test | User | Action | Result | Status |
|------|------|--------|--------|--------|
| Delete User | admin | DELETE /api/users/1 | Success 200 | ✅ |
| Delete User | user | DELETE /api/users/1 | Blocked 403 | ✅ |
| Delete User | none | DELETE /api/users/1 | Blocked 401 | ✅ |

### Category 4: Rate Limiting (Port 4000)
| Test | Details | Expected |
|------|---------|----------|
| 5 Requests/min | Send 5 POST /api/login | All succeed |
| 6th Request | Send 6th request | Blocked 429 |
| Wait 60s | Then send new request | Success 200 |

### Category 5: Insecure Backend (Port 3000) - VULNERABILITIES
| Test | Endpoint | Issue | Result |
|------|----------|-------|--------|
| Get Users | `GET /users` | No auth | Returns all users + passwords ❌ |
| Login | `POST /login` | No password check | Anyone becomes any user ❌ |
| Delete User | `DELETE /users/:id` | No auth | Anyone can delete ❌ |

### Category 6: Security Dashboard (Port 5000)
| Endpoint | Purpose | Response |
|----------|---------|----------|
| `GET /health` | Health check | Status OK |
| `GET /logs` | View all logs | Array of log objects |
| `GET /summary` | Security summary | Analytics & DREAD scores |

---

## 🎯 Minimal Test Sequence (5 minutes)

If you're in a hurry, run these tests in order:

```bash
# 1. Test Gateway Authentication (30 seconds)
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin"}'

# 2. Test SQL Injection Prevention (30 seconds)
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin OR 1=1"}'

# 3. Test XSS Prevention (30 seconds)
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"<script>alert(1)</script>"}'

# 4. Test Insecure Backend Vulnerability (30 seconds)
curl http://localhost:3000/users

# 5. Test Dashboard (30 seconds)
curl http://localhost:5000/summary | jq '.'
```

---

## 🔐 Security Testing Checklist

### API Gateway (Port 4000)
- [ ] Login generates valid JWT token
- [ ] Token has admin/user roles
- [ ] SQL injection attempts are blocked
- [ ] XSS attempts are blocked
- [ ] Rate limiting works (5/min)
- [ ] Admin can delete users
- [ ] Regular users cannot delete
- [ ] Requests without token are rejected
- [ ] Invalid tokens are rejected

### Insecure Backend (Port 3000) - INTENTIONAL VULNERABILITIES
- [ ] No authentication required
- [ ] All users + passwords are exposed
- [ ] Login works without password
- [ ] Any user can be deleted
- [ ] No input validation

### Security Dashboard (Port 5000)
- [ ] Health check responds
- [ ] Logs are collected from both systems
- [ ] Summary shows security metrics
- [ ] Blocked attacks appear in logs
- [ ] DREAD scores calculated

---

## 💡 Example Test Flows

### Flow 1: Demonstrate Security ✅
```bash
# 1. Get admin token
TOKEN=$(curl -s -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin"}' | jq -r '.token')

# 2. Try SQL injection on login
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin OR 1=1"}'
# Result: Blocked ✅

# 3. Delete user with admin token
curl -X DELETE http://localhost:4000/api/users/1 \
  -H "Authorization: Bearer $TOKEN"
# Result: Success ✅

# 4. Check dashboard
curl http://localhost:5000/summary | jq '.'
# See: blocked attacks counted
```

### Flow 2: Demonstrate Vulnerability ❌
```bash
# 1. Get all users (no auth)
curl http://localhost:3000/users
# Result: All users + passwords visible ❌

# 2. Login without password
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin"}'
# Result: Login successful without password ❌

# 3. Delete user (no auth)
curl -X DELETE http://localhost:3000/users/1
# Result: User deleted, no auth needed ❌
```

### Flow 3: Compare Both Systems
```bash
# Test same action on both systems

# Secure Gateway
echo "=== SECURE GATEWAY ==="
curl http://localhost:4000/api/users -H "Content-Type: application/json"
# Result: 401 Unauthorized (as expected)

# Insecure Backend  
echo "=== INSECURE BACKEND ==="
curl http://localhost:3000/users
# Result: Returns all users + passwords (vulnerability)
```

---

## 📊 Dashboard Interpretation

When you run tests, check the dashboard to see what was logged:

```bash
curl http://localhost:5000/summary | jq '.'
```

Look for:
- **total**: Total number of requests logged
- **blocked**: Number of blocked/malicious requests
- **highRisk**: Requests with DREAD score ≥ 8
- **averageDREAD**: Average security risk score
- **topUsers**: Most active users
- **topEndpoints**: Most accessed endpoints
- **stride**: Security threat categories detected

---

## 🛠️ Debugging Tips

### If tests don't work:

1. **Check servers are running**
   ```bash
   # All three should show "running"
   curl http://localhost:4000/api/login -X POST -d '{}' -H "Content-Type: application/json"
   curl http://localhost:3000/
   curl http://localhost:5000/health
   ```

2. **Check network connectivity**
   ```bash
   # Should respond
   netstat -an | findstr LISTEN  # Windows
   lsof -i -P -n | grep LISTEN   # macOS/Linux
   ```

3. **View gateway logs**
   ```bash
   cat api-gateway/logs.txt
   ```

4. **Check for rate limiting issues**
   - Wait 60 seconds and try again
   - Rate limit: 5 requests per minute

---

## 🎓 Learning Outcomes

After running these tests, you'll understand:

✅ How **authentication** protects endpoints
✅ How **JWT tokens** work in role-based access control
✅ How **input validation** prevents SQL injection
✅ How **input validation** prevents XSS attacks
✅ How **rate limiting** prevents brute force
✅ Why the **insecure backend** is vulnerable
✅ How a **security dashboard** monitors threats
✅ The difference between **secure and insecure** implementations

---

## 📚 Additional Resources

- See `TEST_SCENARIOS.md` for detailed test descriptions
- See `run_tests.ps1` for PowerShell automation
- See `run_tests.sh` for Bash automation

