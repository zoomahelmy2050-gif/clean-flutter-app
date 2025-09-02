# Register admin account on backend (using Security Center credentials)
$url = "https://clean-flutter-app.onrender.com/auth/register"
$body = @{
    email = "env.hygiene@gmail.com"
    passwordRecordV2 = "v2:password"  # Backend expects this format
} | ConvertTo-Json

Write-Host "Registering admin account on backend..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
    Write-Host "✅ Admin account created successfully!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Registration failed: $_" -ForegroundColor Red
    Write-Host "Note: Account may already exist, which is fine." -ForegroundColor Yellow
}

Write-Host "`nTesting login..." -ForegroundColor Yellow
$loginUrl = "https://clean-flutter-app.onrender.com/auth/login"
$loginBody = @{
    email = "env.hygiene@gmail.com"
    password = "password"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri $loginUrl -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host "Token: $($loginResponse.access_token.Substring(0, 20))..." -ForegroundColor Cyan
    
    # Test migrations endpoint with token
    Write-Host "`nTesting /migrations/status with token..." -ForegroundColor Yellow
    $headers = @{
        "Authorization" = "Bearer $($loginResponse.access_token)"
    }
    $statusResponse = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/migrations/status" -Headers $headers
    Write-Host "✅ Migration status retrieved!" -ForegroundColor Green
    Write-Host "Database Connected: $($statusResponse.databaseConnected)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Login failed: $_" -ForegroundColor Red
}
