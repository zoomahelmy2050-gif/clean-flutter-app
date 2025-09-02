# Fix Render backend by creating admin user directly via database
Write-Host "Testing Render backend health..." -ForegroundColor Yellow

try {
    # Test if backend is responding at all
    $healthResponse = Invoke-WebRequest -Uri "https://clean-flutter-app.onrender.com" -Method Get -TimeoutSec 10
    Write-Host "✅ Backend is responding (Status: $($healthResponse.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend not responding: $_" -ForegroundColor Red
    exit 1
}

# The 500 error suggests database connection issues
# Let's check if we can create the admin user via a different approach
Write-Host "`nAttempting to register admin user..." -ForegroundColor Yellow

$registerBody = @{
    email = "env.hygiene@gmail.com"
    passwordRecordV2 = "v2:password"
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/auth/register" -Method Post -Body $registerBody -ContentType "application/json" -TimeoutSec 15
    Write-Host "✅ Admin user registered successfully!" -ForegroundColor Green
    Write-Host ($registerResponse | ConvertTo-Json) -ForegroundColor Cyan
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 409) {
        Write-Host "⚠️ Admin user already exists (this is good!)" -ForegroundColor Yellow
    } elseif ($statusCode -eq 500) {
        Write-Host "❌ Database connection error on Render" -ForegroundColor Red
        Write-Host "Check your Render dashboard for:" -ForegroundColor Yellow
        Write-Host "  - DATABASE_URL environment variable" -ForegroundColor Yellow
        Write-Host "  - Database service status" -ForegroundColor Yellow
        Write-Host "  - Application logs" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Registration failed with status $statusCode" -ForegroundColor Red
    }
}

Write-Host "`nTesting login..." -ForegroundColor Yellow
$loginBody = @{
    email = "env.hygiene@gmail.com"
    password = "password"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/auth/login" -Method Post -Body $loginBody -ContentType "application/json" -TimeoutSec 15
    Write-Host "✅ Login successful!" -ForegroundColor Green
    
    $token = $loginResponse.access_token
    if ($token) {
        Write-Host "Token received: $($token.Substring(0, 20))..." -ForegroundColor Cyan
        
        # Test migration endpoint
        Write-Host "`nTesting migration status..." -ForegroundColor Yellow
        $authHeaders = @{
            "Authorization" = "Bearer $token"
        }
        $statusResponse = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/migrations/status" -Headers $authHeaders -TimeoutSec 15
        Write-Host "✅ Migration endpoint working!" -ForegroundColor Green
        Write-Host "Database Connected: $($statusResponse.databaseConnected)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Login failed: $_" -ForegroundColor Red
}
