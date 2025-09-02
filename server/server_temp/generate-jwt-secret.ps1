# Generate JWT Secret for Railway Deployment
$bytes = New-Object byte[] 64
[System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($bytes)
$jwtSecret = [System.Convert]::ToBase64String($bytes)

Write-Host "Copy this JWT_SECRET to your Railway environment variables:"
Write-Host "JWT_SECRET=$jwtSecret"
Write-Host ""
Write-Host "This secret is 64 bytes (512 bits) and cryptographically secure."
