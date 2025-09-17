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
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptRoot)

function Add-PathIfMissing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    if (!(($env:PATH -split ';') -contains $Path)) {
        $env:PATH = "$Path;$env:PATH"
    }
}

function Get-UserProfilePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Segments
    )

    $root = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
    foreach ($segment in $Segments) {
        $root = [System.IO.Path]::Combine($root, $segment)
    }
    return $root
}

# --- Quiet mode defaults & legacy compatibility ---
# Ensure quiet defaults for parity with bash/zsh direnv hooks
if (-not $env:DIRENV_LOG_FORMAT) { $env:DIRENV_LOG_FORMAT = '' }

# Shared PATH entries so automation matches interactive shells
$sharedPaths = @(
    (Get-UserProfilePath -Segments @('.local', 'bin')),
    (Get-UserProfilePath -Segments @('bin')),
    (Get-UserProfilePath -Segments @('.cargo', 'bin')),
    (Get-UserProfilePath -Segments @('go', 'bin')),
    (Get-UserProfilePath -Segments @('.poetry', 'bin')),
    (Get-UserProfilePath -Segments @('.npm-global'))
)

foreach ($pathEntry in $sharedPaths) {
    Add-PathIfMissing -Path $pathEntry
}

$voltaHome = if ($env:VOLTA_HOME) { $env:VOLTA_HOME } else { Get-UserProfilePath -Segments @('.volta') }
$voltaBin = [System.IO.Path]::Combine($voltaHome, 'bin')
if (Test-Path -LiteralPath $voltaBin) {
    $env:VOLTA_HOME = $voltaHome
    Add-PathIfMissing -Path $voltaBin
}

# Load shared cross-shell tooling modules
$toolDir = Join-Path $repoRoot 'shell/common/tools.d/ps1'
if (Test-Path -LiteralPath $toolDir) {
    Get-ChildItem -Path $toolDir -Filter '*.ps1' -File | Sort-Object Name | ForEach-Object {
        . $_.FullName
    }
}

# --- Toolchain activation (Mise first) ---
function Activate-Mise {
    [CmdletBinding()]
    param()
    if (Get-Command mise -ErrorAction SilentlyContinue) {
        try {
            (& mise activate pwsh --shims) | Invoke-Expression
        } catch {
            Write-Verbose "mise activation failed: $($_.Exception.Message)"
        }
    }
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

# When executed directly, activate mise then load a .env file from the parent directory
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Activate-Mise
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = Split-Path -Parent $scriptDir
    $envFile = Join-Path $projectRoot '.env'
    if (Test-Path $envFile) {
        Load-EnvFile -FilePath $envFile
    }
}
