# Register admin user on Render backend with correct v2: prefix
Write-Host "Registering admin user on Render backend..." -ForegroundColor Yellow

$backendUrl = "https://clean-flutter-app.onrender.com"
$email = "env.hygiene@gmail.com"
$password = "password"
# The backend expects passwordRecordV2 to start with 'v2:'
$passwordRecordV2 = "v2:password"

# Health check first
Write-Host "Checking backend health..." -ForegroundColor Cyan
try {
    $health = Invoke-RestMethod -Uri "$backendUrl/health" -Method GET -TimeoutSec 30
    Write-Host "Backend is healthy: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "Backend health check failed: $_" -ForegroundColor Red
    exit 1
}

# Register the admin user
Write-Host "Registering admin user..." -ForegroundColor Cyan

$headers = @{
    "Content-Type" = "application/json"
}

$registerBody = @{
    email = $email
    passwordRecordV2 = $passwordRecordV2
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "$backendUrl/auth/register" -Method POST -Headers $headers -Body $registerBody -TimeoutSec 30
    Write-Host "Registration response: $($registerResponse | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Registration error: $_" -ForegroundColor Red
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "User already exists, attempting login..." -ForegroundColor Yellow
    }
}

# Test login
Write-Host "Testing login..." -ForegroundColor Cyan

$loginBody = @{
    email = $email
    password = $password  # For login, use plain password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$backendUrl/auth/login" -Method POST -Headers $headers -Body $loginBody -TimeoutSec 30
    
    if ($loginResponse.accessToken) {
        Write-Host "Login successful!" -ForegroundColor Green
        Write-Host "Access Token: $($loginResponse.accessToken.Substring(0, 20))..." -ForegroundColor Gray
        
        # Test migration endpoint
        Write-Host "Testing migration endpoint..." -ForegroundColor Cyan
        $authHeaders = @{
            "Authorization" = "Bearer $($loginResponse.accessToken)"
        }
        
        try {
            $migrationStatus = Invoke-RestMethod -Uri "$backendUrl/migrations/status" -Method GET -Headers $authHeaders -TimeoutSec 30
            Write-Host "Migration status: $($migrationStatus | ConvertTo-Json)" -ForegroundColor Green
        } catch {
            Write-Host "Migration endpoint error: $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Login failed: No access token received" -ForegroundColor Red
    }
} catch {
    Write-Host "Login error: $_" -ForegroundColor Red
}

Write-Host "`n====================================" -ForegroundColor Cyan
Write-Host "Credentials for Flutter app:" -ForegroundColor White
Write-Host "Email: $email" -ForegroundColor Green
Write-Host "Password: $password" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Cyan
