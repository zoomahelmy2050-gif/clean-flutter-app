# Simple script to fix Render authentication
$url = "https://clean-flutter-app.onrender.com"

Write-Host "Fixing Render Backend Authentication..." -ForegroundColor Cyan

# Fix authentication by registering admin with proper v2 password format

Write-Host "Fixing authentication..." -ForegroundColor Yellow

# The issue: existing user has incompatible password format
# Solution: Register with a different email that uses proper v2 format

$email = "admin@flutter.app"  # Use different email to avoid conflict
$password = "password"

Write-Host "Using email: $email" -ForegroundColor Cyan

# Generate proper v2 password record using Node.js crypto functions
# This matches the backend's exact implementation
$nodeScript = @"
const crypto = require('crypto');
const password = 'password';
const salt = crypto.randomBytes(16);
const iterations = 10000;
const key = crypto.pbkdf2Sync(Buffer.from(password, 'utf8'), salt, iterations, 32, 'sha256');
const verifier = crypto.createHmac('sha256', salt).update(key).digest();
const saltB64 = salt.toString('base64');
const verifierB64 = verifier.toString('base64');
console.log('v2:' + saltB64 + ':' + iterations + ':' + verifierB64);
"@

# Save and run Node.js script
$nodeScript | Out-File -FilePath "temp_password_gen.js" -Encoding UTF8
$passwordRecordV2 = node temp_password_gen.js
Remove-Item "temp_password_gen.js"

Write-Host "Generated v2 password record" -ForegroundColor Green

# Register with correct format
$headers = @{"Content-Type" = "application/json"}
$body = @{
    email = $email
    passwordRecordV2 = $passwordRecordV2
} | ConvertTo-Json

Write-Host "Registering new admin user..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/auth/register" -Method POST -Headers $headers -Body $body
    Write-Host "✅ Registration successful!" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 409) {
        Write-Host "⚠️ User already exists - continuing to test login" -ForegroundColor Yellow
    } else {
        Write-Host "Registration failed: $_" -ForegroundColor Red
        exit 1
    }
}

# Test login
Write-Host "`nTesting login..." -ForegroundColor Cyan
$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "https://clean-flutter-app.onrender.com/auth/login" -Method POST -Headers $headers -Body $loginBody
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host "Token: $($loginResponse.accessToken.Substring(0, 50))..." -ForegroundColor Cyan
    
    Write-Host "`n🎉 AUTHENTICATION FIXED!" -ForegroundColor Green
    Write-Host "Use these credentials in your Flutter app:" -ForegroundColor Yellow
    Write-Host "Email: $email" -ForegroundColor Cyan
    Write-Host "Password: $password" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Login still failing: $_" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
}
