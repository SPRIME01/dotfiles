@echo off
REM Quick SSH Agent setup for Windows
REM Run this from Windows to set up SSH Agent auto-start

echo.
echo ===================================================
echo  Setting up Windows SSH Agent Auto-Start
echo ===================================================
echo.

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell available'" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell not found
    pause
    exit /b 1
)

echo PowerShell detected
echo.

REM Run the PowerShell setup script
echo Running SSH Agent setup...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0setup-ssh-agent-windows.ps1"

echo.
echo ===================================================
echo  Setup complete!
echo ===================================================
echo.
echo Your SSH Agent should now start automatically with Windows.
echo Open a new PowerShell window to test.
echo.
pause
