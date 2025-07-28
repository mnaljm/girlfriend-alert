@echo off
echo ================================================
echo        Girlfriend Alert App Setup
echo ================================================
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed!
    echo.
    echo Please install Node.js first:
    echo 1. Go to https://nodejs.org
    echo 2. Download the LTS version for Windows
    echo 3. Run the installer
    echo 4. Restart this script after installation
    echo.
    pause
    exit /b 1
)

echo ✅ Node.js is installed
node --version

echo.
echo Installing backend dependencies...
npm install

echo.
echo Installing frontend dependencies...
cd client
npm install
cd ..

echo.
echo Generating VAPID keys for push notifications...
npx web-push generate-vapid-keys > vapid-keys.txt

echo.
echo ================================================
echo ✅ Setup complete!
echo ================================================
echo.
echo Your VAPID keys have been saved to vapid-keys.txt
echo Please copy them to your .env file.
echo.
echo To start the app:
echo   npm run dev
echo.
echo The app will be available at:
echo   Frontend: http://localhost:3000
echo   Backend:  http://localhost:5000
echo.
pause
