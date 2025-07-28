Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    Girlfriend Alert App Setup (Fixed)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Add Node.js to PATH for this session
$nodePath = "C:\Program Files\nodejs"
if (Test-Path $nodePath) {
    $env:PATH = "$nodePath;$env:PATH"
    Write-Host "✅ Added Node.js to PATH for this session" -ForegroundColor Green
} else {
    Write-Host "❌ Node.js not found in expected location" -ForegroundColor Red
    Write-Host "Looking for Node.js in other common locations..." -ForegroundColor Yellow
    
    $commonPaths = @(
        "C:\Program Files (x86)\nodejs",
        "$env:APPDATA\npm",
        "$env:LOCALAPPDATA\Programs\nodejs"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path "$path\node.exe") {
            $env:PATH = "$path;$env:PATH"
            Write-Host "✅ Found and added Node.js from: $path" -ForegroundColor Green
            break
        }
    }
}

# Test Node.js and npm
Write-Host ""
Write-Host "Testing Node.js and npm..." -ForegroundColor Yellow

try {
    $nodeVersion = & node --version
    Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js still not working" -ForegroundColor Red
}

try {
    $npmVersion = & npm --version
    Write-Host "✅ npm: v$npmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ npm still not working" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please restart PowerShell as Administrator and try again" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
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
$vapidOutput = & npx web-push generate-vapid-keys
$vapidOutput | Out-File -FilePath "vapid-keys.txt" -Encoding UTF8

# Also display the keys so user can copy them easily
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "🔑 Your VAPID Keys:" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host $vapidOutput -ForegroundColor White
Write-Host ""
Write-Host "Keys saved to: vapid-keys.txt" -ForegroundColor Yellow

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Copy the VAPID keys above to your .env file" -ForegroundColor White
Write-Host "2. Run: npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "The app will be available at:" -ForegroundColor Cyan
Write-Host "  Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "  Backend:  http://localhost:5000" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to continue"
