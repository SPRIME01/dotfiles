<#
.SYNOPSIS
Initialize pyenv-win for Python version management on Windows.

.DESCRIPTION
This function initializes pyenv-win if it's installed, adding it to the PATH
and setting up the necessary environment variables for Python version management.

.EXAMPLE
Initialize-PyEnv
Initializes pyenv-win if available.
#>
function Initialize-PyEnv {
    # Check common pyenv-win installation paths
    $pyenvPaths = @(
        "$env:USERPROFILE\.pyenv\pyenv-win\bin",
        "$env:USERPROFILE\.pyenv\bin",
        "$env:PYENV_ROOT\bin",
        "$env:PYENV\bin"
    )

    foreach ($pyenvPath in $pyenvPaths) {
        if (Test-Path "$pyenvPath\pyenv.ps1") {
            # Add pyenv to PATH if not already there
            $pathSeparator = if ($env:OS -eq "Windows_NT") { ";" } else { ":" }
            if ($env:PATH -notlike "*$pyenvPath*") {
                $env:PATH = "$pyenvPath$pathSeparator$env:PATH"
            }

            # Set PYENV_ROOT if not already set
            if (-not $env:PYENV_ROOT) {
                $env:PYENV_ROOT = Split-Path $pyenvPath -Parent
            }

            # Initialize pyenv-win
            try {
                & "$pyenvPath\pyenv.ps1" init-shell | Invoke-Expression
                $currentVersion = & "$pyenvPath\pyenv.ps1" version-name 2>$null
                if ($currentVersion) {
                    Write-Host "🐍 pyenv-win initialized ($currentVersion)" -ForegroundColor Green
                }
                else {
                    Write-Host "🐍 pyenv-win initialized" -ForegroundColor Green
                }
                return
            }
            catch {
                Write-Warning "Failed to initialize pyenv-win: $_"
            }
        }
    }

    # Check if pyenv.ps1 is in PATH
    $pyenvCommand = Get-Command "pyenv.ps1" -ErrorAction SilentlyContinue
    if ($pyenvCommand) {
        try {
            & "pyenv.ps1" init-shell | Invoke-Expression
            $currentVersion = & "pyenv.ps1" version-name 2>$null
            if ($currentVersion) {
                Write-Host "🐍 pyenv-win initialized ($currentVersion)" -ForegroundColor Green
            }
            else {
                Write-Host "🐍 pyenv-win initialized" -ForegroundColor Green
            }
            return
        }
        catch {
            Write-Warning "Failed to initialize pyenv-win: $_"
        }
    }

    # pyenv-win not found
    Write-Host "⚠️  pyenv-win not found. Install with: git clone https://github.com/pyenv-win/pyenv-win.git %USERPROFILE%\.pyenv" -ForegroundColor Yellow
}
