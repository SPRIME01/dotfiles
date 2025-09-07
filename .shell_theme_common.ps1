# dotfiles/PowerShell/.shell_theme_common.ps1
# Version: 1.2 - PowerShell specific common theme and utility functions
# Last Modified: July 2, 2025

# Get the directory of the current script for portable pathing
# This should resolve to "$HOME\dotfiles\PowerShell"
$shellConfigDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# --- Module Imports (PowerShell Specific) ---
Write-Verbose "Importing PowerShell modules..."
try {
    # --- Lazy Loading for Terminal-Icons ---
    # Intercept Get-ChildItem and its aliases (ls, dir) to lazy-load Terminal-Icons
    function Get-ChildItem {
        [CmdletBinding(DefaultParameterSetName = 'Items')]
        param(
            # Subset of Get-ChildItem parameters (common parameters are implicit; do not redeclare)
            [Parameter(Position = 0)]
            [string[]]$Path,
            [string]$Filter,
            [string[]]$Include,
            [string[]]$Exclude,
            [string[]]$LiteralPath,
            [switch]$Force,
            [switch]$Recurse,
            [int]$Depth,
            [Parameter(ParameterSetName = 'Items')]
            [switch]$File,
            [Parameter(ParameterSetName = 'Items')]
            [switch]$Directory,
            [Parameter(ParameterSetName = 'Items')]
            [switch]$Hidden,
            [Parameter(ParameterSetName = 'Items')]
            [switch]$ReadOnly,
            [Parameter(ParameterSetName = 'Items')]
            [switch]$System,
            [Parameter(ParameterSetName = 'Items')]
            [string[]]$Name,
            [Parameter(ParameterSetName = 'Items')]
            [System.Collections.Hashtable]$Attributes,
            [Parameter(ParameterSetName = 'Directory')]
            [switch]$Container, # For Get-ChildItem -Container
            [Parameter(ParameterSetName = 'File')]
            [switch]$Leaf # For Get-ChildItem -Leaf
        )

        # Check if Terminal-Icons is already loaded
        if (-not (Get-Module -Name Terminal-Icons -ErrorAction SilentlyContinue)) {
            Write-Verbose "Lazy loading Terminal-Icons..."
            try {
                Import-Module -Name Terminal-Icons -ErrorAction Stop
            }
            catch {
                Write-Warning "Failed to lazy-load Terminal-Icons: $_"
            }
        }

        # Call the original Get-ChildItem cmdlet
        & (Get-Command -Name Get-ChildItem -CommandType Cmdlet) @PSBoundParameters
    }

    # Avoid re-defining built-in aliases like 'ls' and 'dir' which may be AllScope/ReadOnly
    # Built-in aliases already point to Get-ChildItem, and will route to our function

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
    Set-PSReadLineOption -EditMode Emacs # Your preference
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView # Add if you like list view
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
    Set-PSReadLineOption -MaximumHistoryCount 10000

    # Example: Key bindings (customize as needed)
    Set-PSReadLineKeyHandler -Key Ctrl+Spacebar -Function MenuComplete

}
catch {
    Write-Warning "Failed to configure PSReadLine: $_"
}

# --- VS Code Specific Integration (Optional - usually done by VS Code itself) ---
# Ensures terminal features work correctly within VS Code's integrated terminal
# This line is often automatically injected by VS Code. Only keep if you find it's needed.
if ($env:TERM_PROGRAM -eq "vscode") {
    try {
        Write-Verbose "Applying VS Code shell integration..."
        # Use -ErrorAction SilentlyContinue to avoid breaking if path isn't found
        . "$(code-insiders --locate-shell-integration-path pwsh -ErrorAction SilentlyContinue)"
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
