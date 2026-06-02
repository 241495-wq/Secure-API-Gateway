#!/bin/bash
# Bash/Curl Testing Script for API Gateway & Backend

echo "=== API GATEWAY TESTING SUITE ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper function
test_endpoint() {
    local name=$1
    local method=$2
    local url=$3
    local data=$4
    local token=$5
    
    echo -e "${CYAN}Testing: ${name}${NC}"
    
    if [ -z "$token" ]; then
        curl -s -X "$method" "$url" -H "Content-Type: application/json" -d "$data"
    else
        curl -s -X "$method" "$url" -H "Content-Type: application/json" -H "Authorization: Bearer $token" -d "$data"
    fi
    echo ""
}

# ===== PART 1: AUTHENTICATION =====
echo -e "${YELLOW}>>> PART 1: AUTHENTICATION${NC}"
echo ""

echo "1.1 Admin Login"
ADMIN_TOKEN=$(curl -s -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin"}' | jq -r '.token')
echo "Admin Token: ${ADMIN_TOKEN:0:20}..."
echo ""

echo "1.2 User Login"
USER_TOKEN=$(curl -s -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"user"}' | jq -r '.token')
echo "User Token: ${USER_TOKEN:0:20}..."
echo ""

# ===== PART 2: INPUT VALIDATION =====
echo -e "${YELLOW}>>> PART 2: INPUT VALIDATION${NC}"
echo ""

echo "2.1 SQL Injection (OR 1=1)"
curl -s -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin OR 1=1"}' | jq '.'
echo ""

echo "2.2 SQL Injection (DROP TABLE)"
curl -s -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin; DROP TABLE users;--"}' | jq '.'
echo ""

echo "2.3 SQL Injection (UNION SELECT)"
curl -s -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin\" UNION SELECT * FROM users--"}' | jq '.'
echo ""

echo "2.4 XSS Attack (Script tag)"
curl -s -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"<script>alert(1)</script>"}' | jq '.'
echo ""

echo "2.5 XSS Attack (Event handler)"
curl -s -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"<img src=x onerror=alert(1)>"}' | jq '.'
echo ""

echo "2.6 XSS Attack (JavaScript protocol)"
curl -s -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"<a href=\"javascript:alert(1)\">click</a>"}' | jq '.'
echo ""

# ===== PART 3: AUTHORIZATION =====
echo -e "${YELLOW}>>> PART 3: AUTHORIZATION${NC}"
echo ""

echo "3.1 Admin Delete (Should succeed)"
curl -s -X DELETE http://localhost:4000/api/users/1 \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" | jq '.'
echo ""

echo "3.2 User Delete (Should fail with 403)"
curl -s -X DELETE http://localhost:4000/api/users/2 \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" | jq '.'
echo ""

echo "3.3 Delete without token (Should fail with 401)"
curl -s -X DELETE http://localhost:4000/api/users/3 \
  -H "Content-Type: application/json" | jq '.'
echo ""

echo "3.4 Delete with invalid token (Should fail with 403)"
curl -s -X DELETE http://localhost:4000/api/users/4 \
  -H "Authorization: Bearer invalid_token_here" \
  -H "Content-Type: application/json" | jq '.'
echo ""

# ===== PART 4: RATE LIMITING =====
echo -e "${YELLOW}>>> PART 4: RATE LIMITING${NC}"
echo "Sending 7 requests (limit is 5 per minute)"
echo ""

for i in {1..7}; do
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:4000/api/login \
      -H "Content-Type: application/json" \
      -d '{"username":"ratetest"}')
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)
    
    if [ "$HTTP_CODE" = "429" ]; then
        echo -e "${RED}Request $i: RATE LIMITED (429)${NC}"
    else
        echo -e "${GREEN}Request $i: Success ($HTTP_CODE)${NC}"
    fi
done
echo ""

# ===== PART 5: INSECURE BACKEND =====
echo -e "${YELLOW}>>> PART 5: INSECURE BACKEND (VULNERABLE)${NC}"
echo ""

echo "5.1 Get all users (NO AUTH REQUIRED)"
curl -s http://localhost:3000/users | jq '.'
echo ""

echo "5.2 Login without password"
curl -s -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin"}' | jq '.'
echo ""

echo "5.3 Delete user without auth"
curl -s -X DELETE http://localhost:3000/users/1 \
  -H "Content-Type: application/json" | jq '.'
echo ""

# ===== PART 6: DASHBOARD =====
echo -e "${YELLOW}>>> PART 6: SECURITY DASHBOARD${NC}"
echo ""

echo "6.1 Dashboard Health"
curl -s http://localhost:5000/health | jq '.'
echo ""

echo "6.2 Dashboard Summary"
curl -s http://localhost:5000/summary | jq '.'
echo ""

echo "6.3 Recent Logs (last 5)"
curl -s http://localhost:5000/logs | jq '.[0:5]'
echo ""

# ===== COMPARISON =====
echo -e "${YELLOW}>>> SECURITY COMPARISON${NC}"
echo ""
echo -e "${GREEN}✅ API Gateway (SECURE)${NC}"
echo "  - JWT Authentication"
echo "  - Role-Based Access Control"
echo "  - SQL Injection Prevention"
echo "  - XSS Prevention"
echo "  - Rate Limiting"
echo ""
echo -e "${RED}❌ Insecure Backend (VULNERABLE)${NC}"
echo "  - No Password Validation"
echo "  - No Authentication"
echo "  - No Authorization"
echo "  - Exposes Passwords"
echo "  - No Input Validation"
echo ""

echo "=== TESTING COMPLETE ==="
