# Girlfriend Alert - PowerShell Startup Script
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "       Starting Girlfriend Alert App" -ForegroundColor Cyan  
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Add Node.js to PATH
$env:PATH += ";C:\Program Files\nodejs"

Write-Host "Starting server..." -ForegroundColor Yellow

# Start server as background job
$job = Start-Job -ScriptBlock { 
    Set-Location "c:\Users\Jakob\Documents\GitHub\girlfriend-alert"
    $env:PATH += ";C:\Program Files\nodejs"
    node server.js 
}

# Wait a moment for server to start
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "✅ App is running!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The app is available at: " -NoNewline -ForegroundColor White
Write-Host "http://localhost:5000" -ForegroundColor Yellow
Write-Host ""
Write-Host "Instructions:" -ForegroundColor Cyan
Write-Host "1. Open http://localhost:5000 on your PC" -ForegroundColor White
Write-Host "2. Open the same URL on your girlfriend's phone" -ForegroundColor White
Write-Host "3. Both of you log in with your names" -ForegroundColor White
Write-Host "4. Start sending alerts!" -ForegroundColor White
Write-Host ""
Write-Host "For phone access on same WiFi:" -ForegroundColor Cyan
Write-Host "Find your PC's IP with: ipconfig" -ForegroundColor White
Write-Host "Then use: http://YOUR-IP:5000" -ForegroundColor White
Write-Host ""

# Open in browser
Start-Process "http://localhost:5000"

Write-Host "Server is running... Press any key to stop." -ForegroundColor Yellow
Read-Host ""

# Stop the background job
Stop-Job $job
Remove-Job $job

Write-Host "Server stopped." -ForegroundColor Red
