# dotfiles/PowerShell/.shell_theme_common.ps1
# Version: 1.2 - PowerShell specific common theme and utility functions
# Last Modified: July 2, 2025

# Get the directory of the current script for portable pathing
# This should resolve to "$HOME\dotfiles\PowerShell"
$shellConfigDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# --- Module Imports (PowerShell Specific) ---
Write-Verbose "Importing PowerShell modules..."
try {
    # PSReadLine: Check if already loaded by VS Code or other means
    if (-not (Get-Module -Name PSReadLine -ErrorAction SilentlyContinue)) {
        Import-Module -Name PSReadLine -ErrorAction SilentlyContinue
    }

}
catch {
    Write-Warning "Failed to import one or more PowerShell modules: $_"
}

# --- PSReadLine Configuration (Command Line Experience) ---
# Enhance command-line editing, history, and prediction
try {
    Write-Verbose "Configuring PSReadLine..."
    $canTuneReadLine = $false
    try {
        $canTuneReadLine = -not [Console]::IsOutputRedirected
    } catch {
        $canTuneReadLine = $false
    }

    if ($canTuneReadLine) {
        Set-PSReadLineOption -EditMode Emacs # Your preference
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView # Add if you like list view
        Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
        Set-PSReadLineOption -MaximumHistoryCount 10000

        # Example: Key bindings (customize as needed)
        Set-PSReadLineKeyHandler -Key Ctrl+Spacebar -Function MenuComplete
    }

}
catch {
    Write-Warning "Failed to configure PSReadLine: $_"
}

# --- VS Code Specific Integration (Manual, guarded, idempotent) ---
# Apply only inside VS Code terminals, only once per process, and avoid non-local paths.
if ($env:TERM_PROGRAM -eq 'vscode' -and -not $env:DOTFILES_VSCODE_SHELL_INTEGRATION_LOADED) {
    try {
        Write-Verbose "Applying VS Code shell integration..."

        # Avoid wrappers/functions/aliases (which can recurse); use application commands only.
        $vscodeCli = Get-Command code-insiders, code -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($vscodeCli) {
            $integrationPath = & $vscodeCli.Source --locate-shell-integration-path pwsh 2>$null

            if ($integrationPath -and (Test-Path -LiteralPath $integrationPath)) {
                $isUnc = $integrationPath -like '\\*'
                $isWslNetwork = $integrationPath -match '^(?i)\\\\wsl(?:\.localhost)?\\|^\\\\wsl\\$\\'
                if (-not ($isUnc -or $isWslNetwork)) {
                    . $integrationPath
                    $env:DOTFILES_VSCODE_SHELL_INTEGRATION_LOADED = '1'
                } else {
                    Write-Verbose "Skipping VS Code shell integration from UNC/WSL network path: $integrationPath"
                }
            }
        }
    }
    catch {
        Write-Warning "Failed to apply VS Code shell integration: $_"
    }
}

# --- Hostname-Specific PowerShell Configuration (Optional - if needed for PS) ---
# This is PowerShell syntax, separate from the Bash/Zsh one.
# You might not need this if all your SPECIAL_VAR logic is handled by .shell_common.sh
# and PowerShell can just inherit environment variables.
# If you *do* need PowerShell-specific hostname logic, here it is:
# switch ($env:COMPUTERNAME.ToLower()) {
#     "workstation-name" {
#         $env:POWERSHELL_SPECIFIC_VAR = "true"
#         Write-Host "🔒 Loaded PowerShell workstation-specific config" -ForegroundColor DarkCyan
#     }
#     "dev-laptop" {
#         $env:POWERSHELL_SPECIFIC_VAR = "false"
#         Write-Host "🔒 Loaded PowerShell dev laptop config" -ForegroundColor DarkCyan
#     }
# }

# Note: No "Global Pathing Configuration" or "Aliases" section here as those are already handled
# in Microsoft.Powershell_profile.ps1 or the environment variables are inherited from the OS.
# The 'projects' function is already in your main profile, keep it there.
