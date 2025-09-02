Write-Host "Running Security Service Tests..." -ForegroundColor Green
Write-Host ""

$tests = @(
    "test/services/security_orchestration_service_test.dart",
    "test/services/performance_monitoring_service_test.dart", 
    "test/services/emerging_threats_service_test.dart"
)

$passed = 0
$failed = 0

foreach ($test in $tests) {
    Write-Host "Testing: $test" -ForegroundColor Yellow
    flutter test $test 2>&1 | Out-String | Write-Host
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ PASSED" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "✗ FAILED" -ForegroundColor Red
        $failed++
    }
    Write-Host ""
}

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Test Results Summary:" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host "================================" -ForegroundColor Cyan
