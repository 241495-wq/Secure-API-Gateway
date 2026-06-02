#!/usr/bin/env pwsh
# API Gateway & Backend Testing Script
# Run in PowerShell to test all security scenarios

Write-Host "=== API Gateway & Backend Testing Suite ===" -ForegroundColor Green
Write-Host ""

# Helper function for API calls
function Make-Request {
    param(
        [string]$Method,
        [string]$Uri,
        [object]$Body,
        [string]$Token
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if ($Token) {
        $headers["Authorization"] = "Bearer $Token"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers -Body $Body -ErrorAction Stop
        return $response
    } catch {
        return $_.Exception.Response
    }
}

Write-Host ">>> STEP 1: API GATEWAY AUTHENTICATION" -ForegroundColor Cyan
Write-Host ""

Write-Host "1.1 Admin Login Test" -ForegroundColor Yellow
$adminLogin = Make-Request -Method "POST" -Uri "http://localhost:4000/api/login" -Body '{"username":"admin"}'
if ($adminLogin.token) {
    Write-Host "✅ Admin token received: $($adminLogin.token.Substring(0, 20))..." -ForegroundColor Green
    $adminToken = $adminLogin.token
} else {
    Write-Host "❌ Failed to get admin token" -ForegroundColor Red
}
Write-Host ""

Write-Host "1.2 Regular User Login Test" -ForegroundColor Yellow
$userLogin = Make-Request -Method "POST" -Uri "http://localhost:4000/api/login" -Body '{"username":"user"}'
if ($userLogin.token) {
    Write-Host "✅ User token received" -ForegroundColor Green
    $userToken = $userLogin.token
} else {
    Write-Host "❌ Failed to get user token" -ForegroundColor Red
}
Write-Host ""

Write-Host ">>> STEP 2: INPUT VALIDATION TESTS" -ForegroundColor Cyan
Write-Host ""

Write-Host "2.1 SQL Injection Test (OR 1=1)" -ForegroundColor Yellow
$sqlTest = Make-Request -Method "POST" -Uri "http://localhost:4000/api/login" -Body '{"username":"admin OR 1=1"}'
if ($sqlTest.message -match "Blocked|SQL") {
    Write-Host "✅ SQL Injection BLOCKED: $($sqlTest.message)" -ForegroundColor Green
} else {
    Write-Host "❌ SQL Injection NOT blocked" -ForegroundColor Red
}
Write-Host ""

Write-Host "2.2 SQL Injection Test (DROP TABLE)" -ForegroundColor Yellow
$sqlTest2 = Make-Request -Method "POST" -Uri "http://localhost:4000/api/login" -Body '{"username":"admin; DROP TABLE users;"}'
if ($sqlTest2.message -match "Blocked|SQL") {
    Write-Host "✅ SQL Injection BLOCKED" -ForegroundColor Green
} else {
    Write-Host "❌ SQL Injection NOT blocked" -ForegroundColor Red
}
Write-Host ""

Write-Host "2.3 XSS Injection Test (Script tag)" -ForegroundColor Yellow
$xssTest = Make-Request -Method "POST" -Uri "http://localhost:4000/api/login" -Body '{"username":"<script>alert(1)</script>"}'
if ($xssTest.message -match "Blocked|XSS") {
    Write-Host "✅ XSS Attack BLOCKED: $($xssTest.message)" -ForegroundColor Green
} else {
    Write-Host "❌ XSS Attack NOT blocked" -ForegroundColor Red
}
Write-Host ""

Write-Host "2.4 XSS Injection Test (onerror)" -ForegroundColor Yellow
$xssTest2 = Make-Request -Method "POST" -Uri "http://localhost:4000/api/login" -Body '{"username":"<img src=x onerror=alert(1)>"}'
if ($xssTest2.message -match "Blocked|XSS") {
    Write-Host "✅ XSS Attack BLOCKED" -ForegroundColor Green
} else {
    Write-Host "❌ XSS Attack NOT blocked" -ForegroundColor Red
}
Write-Host ""

Write-Host ">>> STEP 3: AUTHORIZATION TESTS" -ForegroundColor Cyan
Write-Host ""

Write-Host "3.1 Admin Delete (Should succeed)" -ForegroundColor Yellow
try {
    $deleteAdmin = Invoke-RestMethod -Uri "http://localhost:4000/api/users/1" -Method "DELETE" -Headers @{"Authorization" = "Bearer $adminToken"; "Content-Type" = "application/json"} -ErrorAction Stop
    Write-Host "✅ Admin can delete: $($deleteAdmin.message)" -ForegroundColor Green
} catch {
    Write-Host "Response: $($_)" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "3.2 User Delete (Should fail)" -ForegroundColor Yellow
try {
    $deleteUser = Invoke-RestMethod -Uri "http://localhost:4000/api/users/1" -Method "DELETE" -Headers @{"Authorization" = "Bearer $userToken"; "Content-Type" = "application/json"} -ErrorAction Stop
    Write-Host "❌ User should NOT be able to delete" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 403) {
        Write-Host "✅ User delete BLOCKED (403 Forbidden)" -ForegroundColor Green
    } else {
        Write-Host "Response Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Yellow
    }
}
Write-Host ""

Write-Host "3.3 No Token Test (Should fail)" -ForegroundColor Yellow
try {
    $noToken = Invoke-RestMethod -Uri "http://localhost:4000/api/users/1" -Method "DELETE" -Headers @{"Content-Type" = "application/json"} -ErrorAction Stop
    Write-Host "❌ Request without token should fail" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 401) {
        Write-Host "✅ Request BLOCKED (401 Unauthorized)" -ForegroundColor Green
    }
}
Write-Host ""

Write-Host ">>> STEP 4: RATE LIMITING TESTS" -ForegroundColor Cyan
Write-Host ""
Write-Host "Sending 6 requests in rapid succession (limit is 5/minute)..." -ForegroundColor Yellow

$rateLimitResults = @()
1..6 | ForEach-Object {
    try {
        $resp = Invoke-RestMethod -Uri "http://localhost:4000/api/login" -Method "POST" -Body '{"username":"test"}' -Headers @{"Content-Type" = "application/json"} -ErrorAction Stop
        $rateLimitResults += "Request $($_): SUCCESS"
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 429) {
            $rateLimitResults += "Request $($_): RATE LIMITED (429)"
        } else {
            $rateLimitResults += "Request $($_): ERROR ($statusCode)"
        }
    }
}

$rateLimitResults | ForEach-Object {
    if ($_ -match "LIMITED") {
        Write-Host $_ -ForegroundColor Green
    } else {
        Write-Host $_ -ForegroundColor Yellow
    }
}
Write-Host ""

Write-Host ">>> STEP 5: INSECURE BACKEND COMPARISON" -ForegroundColor Cyan
Write-Host ""

Write-Host "5.1 Insecure Backend - Get All Users (NO AUTH)" -ForegroundColor Yellow
try {
    $insecureUsers = Invoke-RestMethod -Uri "http://localhost:3000/users" -Method "GET" -ErrorAction Stop
    Write-Host "❌ VULNERABLE: All users exposed!" -ForegroundColor Red
    $insecureUsers | ForEach-Object {
        Write-Host "  - Username: $($_.username), Password: $($_.password), Role: $($_.role)" -ForegroundColor Red
    }
} catch {
    Write-Host "Cannot reach insecure backend on port 3000" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "5.2 Insecure Backend - Login (NO PASSWORD CHECK)" -ForegroundColor Yellow
try {
    $insecureLogin = Invoke-RestMethod -Uri "http://localhost:3000/login" -Method "POST" -Body '{"username":"admin"}' -Headers @{"Content-Type" = "application/json"} -ErrorAction Stop
    Write-Host "❌ VULNERABLE: Login without password!" -ForegroundColor Red
    Write-Host "  Response: $($insecureLogin.message)" -ForegroundColor Red
} catch {
    Write-Host "Cannot reach insecure backend" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "5.3 Insecure Backend - Delete (NO AUTH)" -ForegroundColor Yellow
try {
    $insecureDelete = Invoke-RestMethod -Uri "http://localhost:3000/users/2" -Method "DELETE" -Headers @{"Content-Type" = "application/json"} -ErrorAction Stop
    Write-Host "❌ VULNERABLE: User deleted without auth!" -ForegroundColor Red
    Write-Host "  Response: $($insecureDelete.message)" -ForegroundColor Red
} catch {
    Write-Host "Cannot reach insecure backend" -ForegroundColor Yellow
}
Write-Host ""

Write-Host ">>> STEP 6: SECURITY DASHBOARD" -ForegroundColor Cyan
Write-Host ""

Write-Host "6.1 Dashboard Health Check" -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method "GET" -ErrorAction Stop
    Write-Host "✅ Dashboard is running: Status=$($health.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ Dashboard not responding" -ForegroundColor Red
}
Write-Host ""

Write-Host "6.2 View Security Summary" -ForegroundColor Yellow
try {
    $summary = Invoke-RestMethod -Uri "http://localhost:5000/summary" -Method "GET" -ErrorAction Stop
    Write-Host "Dashboard Summary:" -ForegroundColor Green
    Write-Host "  Total Logs: $($summary.total)" -ForegroundColor Yellow
    Write-Host "  Blocked Requests: $($summary.blocked)" -ForegroundColor Yellow
    Write-Host "  High Risk Logs: $($summary.highRisk)" -ForegroundColor Yellow
    Write-Host "  Average DREAD Score: $($summary.averageDREAD)" -ForegroundColor Yellow
} catch {
    Write-Host "Cannot fetch dashboard summary" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "6.3 View Recent Logs" -ForegroundColor Yellow
try {
    $logs = Invoke-RestMethod -Uri "http://localhost:5000/logs" -Method "GET" -ErrorAction Stop
    Write-Host "Total logs in dashboard: $($logs.Count)" -ForegroundColor Green
    if ($logs.Count -gt 0) {
        Write-Host "Last 3 logs:" -ForegroundColor Yellow
        $logs | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - Time: $($_.time), Message: $($_.message), Risk: $($_.risk)" -ForegroundColor Cyan
        }
    }
} catch {
    Write-Host "Cannot fetch logs" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "=== TESTING COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Green
Write-Host "✅ = Secure (Gateway handles it correctly)" -ForegroundColor Green
Write-Host "❌ = Vulnerable (Insecure backend exposes it)" -ForegroundColor Red
Write-Host "🟡 = Check manually" -ForegroundColor Yellow
