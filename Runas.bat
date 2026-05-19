@echo off
:: ===============================
:: Check for Administrator rights
:: ===============================
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass ^
        -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Running with elevated privileges!
echo.

:: ==================================
:: Place ADMIN commands below
:: ==================================
start cmd
