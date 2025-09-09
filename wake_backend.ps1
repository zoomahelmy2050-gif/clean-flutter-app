# Wake up Render backend
Write-Host "Waking up Render backend..." -ForegroundColor Yellow
Write-Host "This may take 30-60 seconds if the server is sleeping..." -ForegroundColor Gray

$backendUrl = "https://clean-flutter-app.onrender.com"

try {
    # First, try health endpoint
    Write-Host "`nPinging health endpoint..." -ForegroundColor Cyan
    $healthResponse = Invoke-RestMethod -Uri "$backendUrl/health" -Method GET -TimeoutSec 60
    Write-Host "Health check successful!" -ForegroundColor Green
    
    # Try to login
    Write-Host "`nTesting login..." -ForegroundColor Cyan
    $body = @{
        email = "env.hygiene@gmail.com"
        password = "password"
    } | ConvertTo-Json
    
    $loginResponse = Invoke-RestMethod -Uri "$backendUrl/auth/login" -Method POST -Body $body -ContentType "application/json" -TimeoutSec 30
    
    if ($loginResponse.accessToken) {
        Write-Host "Login successful! Token received." -ForegroundColor Green
        
        # Test migration status
        Write-Host "`nTesting migration status..." -ForegroundColor Cyan
        $headers = @{
            "Authorization" = "Bearer $($loginResponse.accessToken)"
        }
        
        $migrationResponse = Invoke-RestMethod -Uri "$backendUrl/migrations/status" -Method GET -Headers $headers -TimeoutSec 30
        Write-Host "Migration status retrieved!" -ForegroundColor Green
        Write-Host "Database connected: $($migrationResponse.databaseConnected)" -ForegroundColor White
    }
    
    Write-Host "`n✅ Backend is now awake and responding!" -ForegroundColor Green
    Write-Host "You can now use the Flutter app." -ForegroundColor White
}
catch {
    Write-Host "`n❌ Error connecting to backend:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`nPlease check the Render dashboard: https://dashboard.render.com" -ForegroundColor Yellow
}
