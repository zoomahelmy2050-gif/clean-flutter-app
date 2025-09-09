# Simple registration test for admin user
$email = "env.hygiene@gmail.com"
$password = "password"

# Generate v2 password record components
$salt = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16)
$saltB64 = [Convert]::ToBase64String($salt)
$iterations = 10000

# Create PBKDF2 key
$pbkdf2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($password, $salt, $iterations)
$key = $pbkdf2.GetBytes(32)

# Create HMAC verifier
$hmac = New-Object System.Security.Cryptography.HMACSHA256($salt)
$verifier = $hmac.ComputeHash($key)
$verifierB64 = [Convert]::ToBase64String($verifier)

# Build password record
$passwordRecordV2 = "v2" + ":" + $saltB64 + ":" + $iterations.ToString() + ":" + $verifierB64

Write-Host "Password Record Generated:" -ForegroundColor Green
Write-Host $passwordRecordV2.Substring(0, 50) + "..." -ForegroundColor Cyan

# Register user
$headers = @{ "Content-Type" = "application/json" }
$body = @{
    email = $email
    passwordRecordV2 = $passwordRecordV2
} | ConvertTo-Json

Write-Host "`nRegistering user..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/auth/register" -Method POST -Headers $headers -Body $body
    Write-Host "✅ Registration successful!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json) -ForegroundColor Cyan
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 409) {
        Write-Host "⚠️ User already exists" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Registration failed with status $statusCode" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Test login
Write-Host "`nTesting login..." -ForegroundColor Yellow
$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/auth/login" -Method POST -Headers $headers -Body $loginBody
    Write-Host "✅ Login successful!" -ForegroundColor Green
    if ($loginResponse.accessToken) {
        Write-Host "Token received: $($loginResponse.accessToken.Substring(0, 30))..." -ForegroundColor Cyan
    } else {
        Write-Host "Response:" -ForegroundColor Yellow
        Write-Host ($loginResponse | ConvertTo-Json) -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Login failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
