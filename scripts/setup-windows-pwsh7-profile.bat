@echo off
REM Setup Windows PowerShell 7 Profile
REM This batch file sets up PowerShell 7 to use the dotfiles configuration
REM
REM Run this as Administrator for best results

echo.
echo ==================================================
echo  Setting up Windows PowerShell 7 profile...
echo ==================================================
echo.

REM Check if PowerShell 7 is installed
pwsh -v >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ PowerShell 7 is not installed or not in PATH
    echo 💡 Install PowerShell 7 from: https://github.com/PowerShell/PowerShell/releases
    pause
    exit /b 1
)

echo ✅ PowerShell 7 detected
echo.

REM Run the PowerShell setup script from WSL dotfiles
echo Running setup script...
powershell.exe -ExecutionPolicy Bypass -Command "& {Set-Location '%~dp0'; .\setup-windows-pwsh7-profile.ps1}"

echo.
echo ==================================================
echo  Setup complete!
echo ==================================================
echo.
echo Try running these commands in a new PowerShell 7 window:
echo   pwsh
echo   projects
echo.
pause
