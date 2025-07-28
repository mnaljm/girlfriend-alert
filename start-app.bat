@echo off
echo ================================================
echo       Starting Girlfriend Alert App
echo ================================================
echo.

REM Add Node.js to PATH
set PATH=%PATH%;C:\Program Files\nodejs

echo Starting server...
start /B node server.js

echo.
echo ================================================
echo ✅ App is starting!
echo ================================================
echo.
echo The app is available at: http://localhost:5000
echo.
echo To stop the server, close this window or press Ctrl+C
echo.
echo Instructions:
echo 1. Open http://localhost:5000 on your PC
echo 2. Open the same URL on your girlfriend's phone
echo 3. Both of you log in with your names
echo 4. Start sending alerts!
echo.
pause

REM Wait for server to start
timeout /t 3 /nobreak >nul

REM Open the app in default browser
start http://localhost:5000

REM Keep the window open
echo Server is running... Press any key to stop.
pause >nul

REM Kill the server process
taskkill /f /im node.exe >nul 2>&1
