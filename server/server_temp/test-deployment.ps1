# Railway Deployment Testing Script
param(
    [Parameter(Mandatory=$true)]
    [string]$RailwayUrl
)

Write-Host "Testing Railway Deployment: $RailwayUrl" -ForegroundColor Green
Write-Host "=" * 50

# Test 1: Health Check
Write-Host "`n1. Testing Health Endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$RailwayUrl/health" -Method GET -TimeoutSec 30
    Write-Host "✅ Health check passed" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Depth 2)"
} catch {
    Write-Host "❌ Health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: API Base Route
Write-Host "`n2. Testing API Base Route..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$RailwayUrl/api" -Method GET -TimeoutSec 30
    Write-Host "✅ API base route accessible" -ForegroundColor Green
} catch {
    Write-Host "❌ API base route failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Auth Endpoints
Write-Host "`n3. Testing Auth Endpoints..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$RailwayUrl/api/auth/register" -Method POST -ContentType "application/json" -Body '{"email":"test@example.com","password":"testpass123"}' -TimeoutSec 30
    Write-Host "✅ Auth endpoint accessible" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "✅ Auth endpoint working (expected validation error)" -ForegroundColor Green
    } else {
        Write-Host "❌ Auth endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 4: Database Connection
Write-Host "`n4. Testing Database Connection..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$RailwayUrl/api/health/db" -Method GET -TimeoutSec 30
    Write-Host "✅ Database connection successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Database connection failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n" + "=" * 50
Write-Host "Testing Complete!" -ForegroundColor Green
Write-Host "If all tests passed, your Railway deployment is working correctly." -ForegroundColor Cyan
