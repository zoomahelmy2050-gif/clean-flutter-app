# Register admin account on backend with properly formatted v2 password
$url = "https://clean-flutter-app.onrender.com/auth/register"
$email = "env.hygiene@gmail.com"
$password = "password"

# Generate proper v2 password record
Write-Host "Generating v2 password record..." -ForegroundColor Cyan
$salt = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16)
$saltB64 = [Convert]::ToBase64String($salt)
$iterations = 10000

# Compute PBKDF2 key
$pbkdf2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($password, $salt, $iterations)
$key = $pbkdf2.GetBytes(32)

# Compute HMAC-SHA256 verifier
$hmac = New-Object System.Security.Cryptography.HMACSHA256($salt)
$verifier = $hmac.ComputeHash($key)
$verifierB64 = [Convert]::ToBase64String($verifier)

# Build v2 record using concatenation to avoid colon parsing issues
$passwordRecordV2 = "v2" + ":" + $saltB64 + ":" + $iterations.ToString() + ":" + $verifierB64
Write-Host "Generated password record" -ForegroundColor Green

$headers = @{
    "Content-Type" = "application/json"
}
$body = @{
    email = $email
    passwordRecordV2 = $passwordRecordV2
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
