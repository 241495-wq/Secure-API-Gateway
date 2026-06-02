🔐 Secure API Gateway
A Software Security Design (SSD) project that demonstrates the difference between a secure API gateway and an insecure backend, with a real-time security monitoring dashboard.

📌 Project Overview
This project simulates a real-world security architecture where:

An insecure backend is intentionally vulnerable (for demonstration purposes)
A secure API gateway sits in front of it and enforces authentication, authorization, input validation, and rate limiting
A security dashboard monitors and analyzes all traffic in real time using DREAD and STRIDE threat models


🏗️ Project Structure
api-gateway-project/
│
├── api-gateway/               # Secure API Gateway (Port 4000)
│   ├── middleware/
│   │   ├── auth.js            # JWT authentication
│   │   ├── role.js            # Role-based access control (RBAC)
│   │   ├── validator.js       # Input validation (SQLi, XSS detection)
│   │   └── logger.js          # Request logging
│   ├── server.js              # Main gateway server
│   └── package.json
│
├── insecure-backend/          # Vulnerable Backend (Port 3000)
│   ├── server.js              # Intentionally insecure endpoints
│   └── package.json
│
├── security-dashboard/        # Monitoring Dashboard (Port 5000)
│   ├── public/
│   │   ├── index.html         # Dashboard UI
│   │   ├── app.js             # Frontend logic
│   │   └── styles.css         # Styling
│   ├── analysis.js            # DREAD & STRIDE calculations
│   ├── server.js              # Dashboard API server
│   └── package.json
│
└── tests/
    ├── run_tests.ps1          # PowerShell test suite (Windows)
    ├── run_tests.sh           # Bash test suite (macOS/Linux)
    ├── QUICK_REFERENCE.md     # Quick test commands
    └── TEST_SCENARIOS.md      # Detailed test scenarios

🚀 Getting Started
Prerequisites

Node.js (v16 or higher)
npm (comes with Node.js)

Installation
Open three separate terminals and run each service:
Terminal 1 — Insecure Backend
bashcd insecure-backend
npm install
node server.js
# Runs on http://localhost:3000
Terminal 2 — API Gateway
bashcd api-gateway
npm install
node server.js
# Runs on http://localhost:4000
Terminal 3 — Security Dashboard
bashcd security-dashboard
npm install
node server.js
# Runs on http://localhost:5000
Then open your browser and go to http://localhost:5000 to view the live security dashboard.

🔒 Security Features (API Gateway — Port 4000)
FeatureDescriptionJWT AuthenticationAll protected routes require a valid JSON Web TokenRole-Based Access ControlAdmin-only routes are restricted by roleInput ValidationBlocks SQL Injection (OR 1=1, DROP TABLE, UNION SELECT) and XSS attacks (<script>, onerror=, javascript:)Rate LimitingMaximum 5 requests per minute per clientRequest LoggingAll requests are logged with timestamp, method, IP, and status

❗ Known Vulnerabilities (Insecure Backend — Port 3000)

⚠️ These are intentional for educational/demonstration purposes only.

EndpointVulnerabilityGET /usersNo authentication — exposes all users including passwordsPOST /loginNo password check — anyone can log in as any userDELETE /users/:idNo authorization — any request can delete any user

📊 Security Dashboard (Port 5000)
The dashboard collects logs from both services and provides:

Total requests and blocked attacks count
High-risk request detection (DREAD score ≥ 8)
STRIDE threat classification (Spoofing, Tampering, Repudiation, Info Disclosure, DoS, Elevation)
DREAD risk scoring per request
Top users and top accessed endpoints

Dashboard API Endpoints
EndpointDescriptionGET /healthHealth checkGET /logsAll collected logsGET /summarySecurity analytics and threat summary

🧪 Running Tests
Windows (PowerShell)
powershell.\tests\run_tests.ps1
macOS / Linux (Bash)
bashbash tests/run_tests.sh
Quick Manual Tests
1. Get JWT Token (Login)
bashcurl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin"}'
2. Test SQL Injection Blocking
bashcurl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin OR 1=1"}'
# Expected: 400 Blocked
3. Test XSS Blocking
bashcurl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"<script>alert(1)</script>"}'
# Expected: 400 Blocked
4. Test Insecure Backend (No Auth)
bashcurl http://localhost:3000/users
# Returns: all users with passwords (vulnerability demo)

🎓 Learning Outcomes
This project demonstrates:

✅ How JWT authentication protects API endpoints
✅ How RBAC restricts access by user role
✅ How input validation prevents SQL Injection and XSS
✅ How rate limiting defends against brute force attacks
✅ Why unsecured backends are dangerous
✅ How a security dashboard monitors and scores threats using DREAD/STRIDE


🛠️ Tech Stack

Runtime: Node.js
Framework: Express.js
Auth: JSON Web Tokens (jsonwebtoken)
HTTP Client: Axios
Security: express-rate-limit, custom middleware
Frontend: HTML, CSS, Vanilla JavaScript

