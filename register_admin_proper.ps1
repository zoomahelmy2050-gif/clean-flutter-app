# Generate proper v2 password record and register admin
$password = "password"
$email = "env.hygiene@gmail.com"

# Generate salt (32 random bytes)
$salt = New-Object byte[] 32
[System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($salt)
$saltB64 = [Convert]::ToBase64String($salt)

# Set iterations
$iterations = 100000

# Compute PBKDF2 key
Add-Type -AssemblyName System.Security
$passwordBytes = [System.Text.Encoding]::UTF8.GetBytes($password)
$key = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($passwordBytes, $salt, $iterations, [System.Security.Cryptography.HashAlgorithmName]::SHA256).GetBytes(32)

# Compute HMAC verifier
$hmac = [System.Security.Cryptography.HMACSHA256]::new($salt)
$verifier = $hmac.ComputeHash($key)
$verifierB64 = [Convert]::ToBase64String($verifier)

# Create v2 record
$passwordRecordV2 = "v2:$saltB64:$iterations:$verifierB64"

Write-Host "Generated password record: $passwordRecordV2" -ForegroundColor Yellow

# Register admin
try {
    $registerBody = @{
        email = $email
        passwordRecordV2 = $passwordRecordV2
    } | ConvertTo-Json
    
    $registerResponse = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/auth/register" -Method Post -Body $registerBody -ContentType "application/json"
    Write-Host "✅ Registration successful!" -ForegroundColor Green
    Write-Host ($registerResponse | ConvertTo-Json) -ForegroundColor Cyan
    
    # Test login
    $loginBody = @{
        email = $email
        password = $password
    } | ConvertTo-Json
    
    $loginResponse = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host "Token: $($loginResponse.accessToken.Substring(0, 20))..." -ForegroundColor Cyan
    
    # Test migration status
    $headers = @{
        "Authorization" = "Bearer $($loginResponse.accessToken)"
    }
    
    $statusResponse = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/migrations/status" -Headers $headers
    Write-Host "✅ Migration status retrieved!" -ForegroundColor Green
    Write-Host "Database Connected: $($statusResponse.databaseConnected)" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
}
