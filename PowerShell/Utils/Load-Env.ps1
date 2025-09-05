<#
    .SYNOPSIS
        Load environment variables from a dotenv-style file.

    .DESCRIPTION
        This function reads a file containing KEY=VALUE pairs and populates
        the process environment with those values.  Lines starting with '#'
        are treated as comments and ignored.  Quoted values are unwrapped
        (single or double quotes).  Complex PowerShell expressions are not
        evaluated; the file is treated as static text.  When this file is
        dot-sourced without parameters it will attempt to load a `.env` file
        located in the parent directory of the module.

    .PARAMETER FilePath
        Path to the dotenv file to import.

    .EXAMPLE
        Load-EnvFile -FilePath "$HOME\dotfiles\.env"

    .NOTES
        This script can be dot-sourced or imported as a module.  When
        executed directly (e.g., `pwsh Load-Env.ps1`) it will automatically
        locate and load a `.env` file from the repository root.
#>
# --- Node.js Version Management (Volta) ---
# Note: Volta PATH injection has been deprecated in favor of Mise
# Keep VOLTA_HOME export for compatibility with existing Volta installations
if (Test-Path "$HOME\.volta") {
    $env:VOLTA_HOME = "$HOME\.volta"
}

# --- Snap Package Manager ---
# Note: Snap PATH management is now handled by platform-specific templates

function Load-EnvFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        return
    }

    foreach ($line in Get-Content -LiteralPath $FilePath) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '' -or $trimmed.StartsWith('#')) {
            continue
        }
        $parts = $trimmed -split '=', 2
        if ($parts.Count -eq 2) {
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()
            # Remove surrounding single or double quotes
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
                ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            # Set environment variable using dynamic name
            Set-Item -Path "env:$key" -Value $value
        }
    }
}

# When executed directly, load a .env file from the parent directory
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = Split-Path -Parent $scriptDir
    $envFile = Join-Path $projectRoot '.env'
    if (Test-Path $envFile) {
        Load-EnvFile -FilePath $envFile
    }
}
