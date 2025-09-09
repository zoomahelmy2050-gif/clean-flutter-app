# Simple admin registration with correct v2 format
$email = "env.hygiene@gmail.com"
$password = "password"

Write-Host "Registering admin user with email: $email" -ForegroundColor Yellow

# Use a pre-computed v2 password record for "password"
# This was generated using PBKDF2-SHA256 with 10000 iterations
$passwordRecordV2 = "v2:Xe3EQQJrWh8GgdSH6lmOCg==:10000:3BWoXxNU9qVGY0xK7gYYF/mSZ9g8ycW3Y3cJhYqGDfE="

$headers = @{
    "Content-Type" = "application/json"
}

$body = @{
    email = $email
    passwordRecordV2 = $passwordRecordV2
} | ConvertTo-Json

Write-Host "`nStep 1: Registering user..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/auth/register" -Method POST -Headers $headers -Body $body -ErrorAction Stop
    Write-Host "✅ Registration successful!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json) -ForegroundColor Cyan
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 409) {
        Write-Host "⚠️ User already exists (continuing to login test)" -ForegroundColor Yellow
    } else {
        Write-Host "Registration error: $_" -ForegroundColor Red
        Write-Host "Continuing to test login anyway..." -ForegroundColor Yellow
    }
}

Write-Host "`nStep 2: Testing login..." -ForegroundColor Cyan

$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/auth/login" -Method POST -Headers $headers -Body $loginBody -ErrorAction Stop
    Write-Host "✅ Login successful!" -ForegroundColor Green
    
    if ($loginResponse.accessToken) {
        Write-Host "`nAuthentication token received!" -ForegroundColor Green
        Write-Host "Token (first 50 chars): $($loginResponse.accessToken.Substring(0, [Math]::Min(50, $loginResponse.accessToken.Length)))..." -ForegroundColor Cyan
        
        # Test authenticated endpoint
        Write-Host "`nStep 3: Testing authenticated endpoint..." -ForegroundColor Cyan
        $authHeaders = @{
            "Authorization" = "Bearer $($loginResponse.accessToken)"
        }
        
        try {
            $blobsResponse = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/blobs" -Headers $authHeaders -Method GET -ErrorAction Stop
            Write-Host "✅ Authenticated endpoint works!" -ForegroundColor Green
        } catch {
            Write-Host "Authenticated endpoint test failed: $_" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n=====================================
✅ ADMIN USER READY FOR FLUTTER APP
=====================================
Email: $email
Password: $password
Backend URL: https://clean-flutter-app.onrender.com
=====================================`n" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Login failed: $_" -ForegroundColor Red
    Write-Host "`nTroubleshooting info:" -ForegroundColor Yellow
    Write-Host "- Make sure the backend is running on Render" -ForegroundColor Yellow
    Write-Host "- Check that the user was registered with the correct password format" -ForegroundColor Yellow
    Write-Host "- The password should be: $password" -ForegroundColor Yellow
}
