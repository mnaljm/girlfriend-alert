Write-Host "================================================" -ForegroundColor Cyan
Write-Host "        Girlfriend Alert App Setup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Node.js/npm is installed
$nodeInstalled = $false
$npmInstalled = $false

# Check for node command
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "✅ Node.js is installed: $nodeVersion" -ForegroundColor Green
        $nodeInstalled = $true
    }
} catch {
    Write-Host "⚠️  'node' command not found" -ForegroundColor Yellow
}

# Check for npm command
try {
    $npmVersion = npm --version 2>$null
    if ($npmVersion) {
        Write-Host "✅ npm is installed: v$npmVersion" -ForegroundColor Green
        $npmInstalled = $true
    }
} catch {
    Write-Host "❌ npm is not installed!" -ForegroundColor Red
}

# If npm is available but node isn't, we can still proceed
if (-not $npmInstalled) {
    Write-Host "❌ npm is required but not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Node.js first:" -ForegroundColor Yellow
    Write-Host "1. Go to https://nodejs.org" -ForegroundColor White
    Write-Host "2. Download the LTS version for Windows" -ForegroundColor White
    Write-Host "3. Run the installer" -ForegroundColor White
    Write-Host "4. Restart PowerShell and run this script again" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not $nodeInstalled) {
    Write-Host "⚠️  Node.js command not found, but npm is available. Continuing..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Installing backend dependencies..." -ForegroundColor Yellow
npm install

Write-Host ""
Write-Host "Installing frontend dependencies..." -ForegroundColor Yellow
Set-Location client
npm install
Set-Location ..

Write-Host ""
Write-Host "Generating VAPID keys for push notifications..." -ForegroundColor Yellow
npx web-push generate-vapid-keys | Out-File -FilePath "vapid-keys.txt" -Encoding UTF8

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your VAPID keys have been saved to vapid-keys.txt" -ForegroundColor Yellow
Write-Host "Please copy them to your .env file." -ForegroundColor Yellow
Write-Host ""
Write-Host "To start the app:" -ForegroundColor Cyan
Write-Host "  npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "The app will be available at:" -ForegroundColor Cyan
Write-Host "  Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "  Backend:  http://localhost:5000" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to continue"
