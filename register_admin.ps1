# Register admin account on backend with Security Center credentials
$url = "https://clean-flutter-app.onrender.com/auth/register"
$headers = @{
    "Content-Type" = "application/json"
}
$body = @{
    email = "env.hygiene@gmail.com"
    passwordRecordV2 = "v2:password"
} | ConvertTo-Json

Write-Host "Registering admin account..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
    Write-Host "✅ Registration successful!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json) -ForegroundColor Cyan
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "⚠️ Account already exists (this is fine)" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Registration failed: $_" -ForegroundColor Red
    }
}

# Test login
Write-Host "`nTesting login..." -ForegroundColor Yellow
$loginUrl = "https://clean-flutter-app.onrender.com/auth/login"
$loginBody = @{
    email = "env.hygiene@gmail.com"
    password = "password"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri $loginUrl -Method Post -Headers $headers -Body $loginBody
    Write-Host "✅ Login successful!" -ForegroundColor Green
    
    # Test migration status endpoint
    $token = $loginResponse.access_token
    if ($token) {
        Write-Host "`nTesting /migrations/status..." -ForegroundColor Yellow
        $authHeaders = @{
            "Authorization" = "Bearer $token"
        }
        $statusResponse = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/migrations/status" -Headers $authHeaders
        Write-Host "✅ Migration status retrieved!" -ForegroundColor Green
        Write-Host "Database Connected: $($statusResponse.databaseConnected)" -ForegroundColor Cyan
        Write-Host "Has Pending Migrations: $($statusResponse.hasPendingMigrations)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Login failed: $_" -ForegroundColor Red
}
