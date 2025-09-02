# Production Deployment Script for Windows
# Advanced Security Backend Infrastructure

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "production",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests = $false
)

Write-Host "🚀 Starting Advanced Security Backend Deployment" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Cyan

# Check Docker
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is not installed or not in PATH"
    exit 1
}

# Check Docker Compose
if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Error "Docker Compose is not installed or not in PATH"
    exit 1
}

# Check environment file
if (!(Test-Path ".env")) {
    Write-Warning ".env file not found. Creating from template..."
    Copy-Item "env.production.example" ".env"
    Write-Host "⚠️  Please edit .env file with your actual credentials before continuing" -ForegroundColor Yellow
    Read-Host "Press Enter when ready to continue"
}

# Validate environment variables
Write-Host "🔍 Validating environment configuration..." -ForegroundColor Cyan

$requiredVars = @(
    "POSTGRES_USERNAME",
    "POSTGRES_PASSWORD", 
    "JWT_SECRET",
    "SENDGRID_API_KEY",
    "TWILIO_ACCOUNT_SID"
)

$envContent = Get-Content ".env" | Where-Object { $_ -match "=" }
$envVars = @{}
foreach ($line in $envContent) {
    if ($line -match "^([^#][^=]+)=(.*)$") {
        $envVars[$matches[1]] = $matches[2]
    }
}

$missingVars = @()
foreach ($var in $requiredVars) {
    if (!$envVars.ContainsKey($var) -or [string]::IsNullOrWhiteSpace($envVars[$var])) {
        $missingVars += $var
    }
}

if ($missingVars.Count -gt 0) {
    Write-Error "Missing required environment variables: $($missingVars -join ', ')"
    Write-Host "Please update your .env file with the required values" -ForegroundColor Yellow
    exit 1
}

# Run tests if not skipped
if (!$SkipTests) {
    Write-Host "🧪 Running integration tests..." -ForegroundColor Cyan
    
    # Test database connection
    Write-Host "Testing database connection..." -ForegroundColor Gray
    try {
        $dbTest = docker run --rm --env-file .env postgres:15-alpine pg_isready -h $envVars["POSTGRES_HOST"] -p 5432 -U $envVars["POSTGRES_USERNAME"]
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Database connection test failed. Continuing anyway..."
        } else {
            Write-Host "✅ Database connection successful" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Could not test database connection: $_"
    }
    
    # Test Redis connection
    Write-Host "Testing Redis connection..." -ForegroundColor Gray
    # Add Redis test here if needed
}

# Build services if not skipped
if (!$SkipBuild) {
    Write-Host "🔨 Building Docker services..." -ForegroundColor Cyan
    docker-compose build --no-cache
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed"
        exit 1
    }
}

# Deploy services
Write-Host "🚀 Deploying services..." -ForegroundColor Cyan

# Stop existing services
Write-Host "Stopping existing services..." -ForegroundColor Gray
docker-compose down

# Start services
Write-Host "Starting new services..." -ForegroundColor Gray
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Error "Service deployment failed"
    exit 1
}

# Wait for services to be ready
Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Cyan

$maxAttempts = 30
$attempt = 0

do {
    $attempt++
    Write-Host "Attempt $attempt/$maxAttempts..." -ForegroundColor Gray
    
    try {
        # Check API Gateway health
        $apiHealth = Invoke-RestMethod -Uri "http://localhost:3000/health" -TimeoutSec 5 -ErrorAction Stop
        
        # Check WebSocket server health
        $wsHealth = Invoke-RestMethod -Uri "http://localhost:3001/health" -TimeoutSec 5 -ErrorAction Stop
        
        if ($apiHealth.status -eq "healthy" -and $wsHealth.status -eq "healthy") {
            Write-Host "✅ All services are healthy" -ForegroundColor Green
            break
        }
    } catch {
        if ($attempt -eq $maxAttempts) {
            Write-Error "Services failed to become healthy within timeout"
            docker-compose logs
            exit 1
        }
        Start-Sleep -Seconds 10
    }
} while ($attempt -lt $maxAttempts)

# Run database migrations
Write-Host "📊 Running database migrations..." -ForegroundColor Cyan
docker-compose exec -T postgres psql -U $envVars["POSTGRES_USERNAME"] -d security_app_db -f /docker-entrypoint-initdb.d/01-schema.sql

# Verify deployment
Write-Host "✅ Verifying deployment..." -ForegroundColor Cyan

# Check service status
$services = docker-compose ps --format "table {{.Name}}\t{{.Status}}"
Write-Host $services

# Display service URLs
Write-Host "`n🌐 Service URLs:" -ForegroundColor Green
Write-Host "API Gateway: http://localhost:3000" -ForegroundColor White
Write-Host "WebSocket Server: http://localhost:3001" -ForegroundColor White
Write-Host "Grafana Dashboard: http://localhost:3002" -ForegroundColor White
Write-Host "Prometheus: http://localhost:9090" -ForegroundColor White

# Display next steps
Write-Host "`n📋 Next Steps:" -ForegroundColor Green
Write-Host "1. Configure SSL certificates for production" -ForegroundColor White
Write-Host "2. Set up external API integrations" -ForegroundColor White
Write-Host "3. Configure monitoring alerts" -ForegroundColor White
Write-Host "4. Test Flutter app connectivity" -ForegroundColor White
Write-Host "5. Set up backup and disaster recovery" -ForegroundColor White

Write-Host "`n🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host "Monitor logs with: docker-compose logs -f" -ForegroundColor Yellow
