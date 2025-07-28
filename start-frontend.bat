@echo off
title Girlfriend Alert App
cls
echo ================================================
echo           💕 Girlfriend Alert App 💕
echo ================================================
echo.

echo ✅ Backend server is already running on port 5000
echo.
echo Starting React frontend...
echo.

cd client
start "Frontend Server" cmd /k "npm start"

echo.
echo ================================================
echo 🎉 App is starting up!
echo ================================================
echo.
echo Frontend will open at: http://localhost:3000
echo Backend is running at: http://localhost:5000
echo.
echo Both servers are now running in separate windows.
echo Close this window when you're done using the app.
echo.

pause
