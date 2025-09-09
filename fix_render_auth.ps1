# Fix Render Backend Authentication
Write-Host "`n=== Fixing Render Backend Authentication ===" -ForegroundColor Cyan

$backendUrl = "https://clean-flutter-app.onrender.com"
$email = "env.hygiene@gmail.com"
$password = "password"

# Step 1: Wake up backend
Write-Host "`nStep 1: Waking up backend..." -ForegroundColor Yellow
$maxRetries = 3
$retryCount = 0

while ($retryCount -lt $maxRetries) {
    try {
        $health = Invoke-WebRequest -Uri "$backendUrl/health" -Method GET -UseBasicParsing -TimeoutSec 30
        if ($health.StatusCode -eq 200) {
            Write-Host "✅ Backend is awake and healthy!" -ForegroundColor Green
            break
        }
    } catch {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "Attempt $retryCount failed. Retrying in 5 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        } else {
            Write-Host "❌ Backend is not responding after $maxRetries attempts" -ForegroundColor Red
            exit 1
        }
    }
}

# Step 2: Register admin user
Write-Host "`nStep 2: Registering admin user..." -ForegroundColor Yellow
$registerBody = @{
    email = $email
    passwordRecordV2 = $password
} | ConvertTo-Json

$registerHeaders = @{
    "Content-Type" = "application/json"
}

try {
    $registerResponse = Invoke-WebRequest -Uri "$backendUrl/auth/register" `
        -Method POST `
        -Body $registerBody `
        -Headers $registerHeaders `
        -UseBasicParsing `
        -TimeoutSec 30
    
    if ($registerResponse.StatusCode -eq 201 -or $registerResponse.StatusCode -eq 200) {
        Write-Host "✅ Admin user registered successfully!" -ForegroundColor Green
    }
} catch {
    $errorResponse = $_.ErrorDetails.Message
    if ($errorResponse -like "*already exists*" -or $errorResponse -like "*duplicate*" -or $_.Exception.Response.StatusCode -eq 409) {
        Write-Host "⚠️  Admin user already exists (this is OK)" -ForegroundColor Yellow
    } else {
        Write-Host "Registration error: $_" -ForegroundColor Red
    }
}

# Step 3: Test login
Write-Host "`nStep 3: Testing login..." -ForegroundColor Yellow
$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-WebRequest -Uri "$backendUrl/auth/login" `
        -Method POST `
        -Body $loginBody `
        -Headers $registerHeaders `
        -UseBasicParsing `
        -TimeoutSec 30
    
    if ($loginResponse.StatusCode -eq 200) {
        $loginData = $loginResponse.Content | ConvertFrom-Json
        
        if ($loginData.accessToken -or $loginData.access_token) {
            $token = if ($loginData.accessToken) { $loginData.accessToken } else { $loginData.access_token }
            Write-Host "✅ Login successful!" -ForegroundColor Green
            Write-Host "Token received: $(($token).Substring(0, [Math]::Min(30, $token.Length)))..." -ForegroundColor Gray
            
            # Step 4: Test migration endpoint
            Write-Host "`nStep 4: Testing migration endpoint..." -ForegroundColor Yellow
            $migrationHeaders = @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            }
            
            try {
                $migrationResponse = Invoke-WebRequest -Uri "$backendUrl/migrations/status" `
                    -Method GET `
                    -Headers $migrationHeaders `
                    -UseBasicParsing `
                    -TimeoutSec 30
                
                if ($migrationResponse.StatusCode -eq 200) {
                    $migrationData = $migrationResponse.Content | ConvertFrom-Json
                    Write-Host "✅ Migration endpoint working!" -ForegroundColor Green
                    Write-Host "Database connected: $($migrationData.databaseConnected)" -ForegroundColor White
                }
            } catch {
                Write-Host "⚠️  Migration endpoint error (might need setup): $_" -ForegroundColor Yellow
            }
        } else {
            Write-Host "❌ No token in response" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "❌ Login failed: $_" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
}

Write-Host "`n" -NoNewline
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "AUTHENTICATION CREDENTIALS:" -ForegroundColor Green
Write-Host "Email: $email" -ForegroundColor White
Write-Host "Password: $password" -ForegroundColor White
Write-Host "Backend URL: $backendUrl" -ForegroundColor White
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "`n✅ You can now use these credentials in your Flutter app!" -ForegroundColor Green
