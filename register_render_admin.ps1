# Register admin user on Render backend
Write-Host "Registering admin user on Render backend..." -ForegroundColor Yellow

$backendUrl = "https://clean-flutter-app.onrender.com"

# First check if backend is healthy
Write-Host "Checking backend health..." -ForegroundColor Cyan
try {
    $health = Invoke-RestMethod -Uri "$backendUrl/health" -Method GET -TimeoutSec 30
    Write-Host "Backend is healthy!" -ForegroundColor Green
} catch {
    Write-Host "Backend is not responding. Waiting for it to wake up..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    try {
        $health = Invoke-RestMethod -Uri "$backendUrl/health" -Method GET -TimeoutSec 60
        Write-Host "Backend is now healthy!" -ForegroundColor Green
    } catch {
        Write-Host "Backend is still not responding. Please check Render dashboard." -ForegroundColor Red
        exit 1
    }
}

# Register admin user
Write-Host "`nRegistering admin user..." -ForegroundColor Cyan
$registerBody = @{
    email = "env.hygiene@gmail.com"
    passwordRecordV2 = "password"
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "$backendUrl/auth/register" -Method POST -Body $registerBody -ContentType "application/json" -TimeoutSec 30
    
    if ($registerResponse) {
        Write-Host "Admin user registered successfully!" -ForegroundColor Green
        
        # Now test login
        Write-Host "`nTesting login..." -ForegroundColor Cyan
        $loginBody = @{
            email = "env.hygiene@gmail.com"
            password = "password"
        } | ConvertTo-Json
        
        $loginResponse = Invoke-RestMethod -Uri "$backendUrl/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -TimeoutSec 30
        
        if ($loginResponse.accessToken) {
            Write-Host "Login successful! Token received." -ForegroundColor Green
            Write-Host "Access Token (first 20 chars): $($loginResponse.accessToken.Substring(0, [Math]::Min(20, $loginResponse.accessToken.Length)))..." -ForegroundColor Gray
            
            # Test migration endpoint
            Write-Host "`nTesting migration endpoint..." -ForegroundColor Cyan
            $headers = @{
                "Authorization" = "Bearer $($loginResponse.accessToken)"
            }
            
            try {
                $migrationStatus = Invoke-RestMethod -Uri "$backendUrl/migrations/status" -Method GET -Headers $headers -TimeoutSec 30
                Write-Host "Migration status endpoint working!" -ForegroundColor Green
                Write-Host "Database connected: $($migrationStatus.databaseConnected)" -ForegroundColor White
                
                if ($migrationStatus.migrations) {
                    Write-Host "Migrations found: $($migrationStatus.migrations.Count)" -ForegroundColor White
                }
            } catch {
                Write-Host "Migration endpoint error: $_" -ForegroundColor Yellow
            }
            
            Write-Host "`n✅ Admin user is registered and can authenticate!" -ForegroundColor Green
            Write-Host "You can now use the Flutter app with these credentials:" -ForegroundColor White
            Write-Host "Email: env.hygiene@gmail.com" -ForegroundColor Cyan
            Write-Host "Password: password" -ForegroundColor Cyan
        } else {
            Write-Host "Login test failed - no access token received" -ForegroundColor Red
        }
    }
} catch {
    $errorMessage = $_.Exception.Message
    
    # Check if user already exists
    if ($errorMessage -like "*already exists*" -or $errorMessage -like "*duplicate*") {
        Write-Host "Admin user already exists. Testing login..." -ForegroundColor Yellow
        
        # Try to login
        $loginBody = @{
            email = "env.hygiene@gmail.com"
            password = "password"
        } | ConvertTo-Json
        
        try {
            $loginResponse = Invoke-RestMethod -Uri "$backendUrl/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -TimeoutSec 30
            
            if ($loginResponse.accessToken) {
                Write-Host "Login successful with existing user!" -ForegroundColor Green
                Write-Host "`n✅ Admin user exists and can authenticate!" -ForegroundColor Green
                Write-Host "You can use the Flutter app with these credentials:" -ForegroundColor White
                Write-Host "Email: env.hygiene@gmail.com" -ForegroundColor Cyan
                Write-Host "Password: password" -ForegroundColor Cyan
            } else {
                Write-Host "Login failed - credentials may be incorrect" -ForegroundColor Red
                Write-Host "Error: $_" -ForegroundColor Red
            }
        } catch {
            Write-Host "Login failed with existing user" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
            Write-Host "`nThe user exists but the password might be different." -ForegroundColor Yellow
            Write-Host "You may need to check the database directly on Render." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Registration failed:" -ForegroundColor Red
        Write-Host $errorMessage -ForegroundColor Red
    }
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
