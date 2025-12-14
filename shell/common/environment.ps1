# PowerShell common environment variables
# Part of the modular dotfiles configuration system

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

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

# Editor settings
if (-not $env:EDITOR) { $env:EDITOR = "code" }
if (-not $env:VISUAL) { $env:VISUAL = $env:EDITOR }

# Development environment variables
if (-not $env:NODE_ENV) { $env:NODE_ENV = "development" }

# PowerShell-specific settings
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# Path additions (platform-specific paths will be added by platform modules)
$localBinCandidates = @(
    (Get-UserProfilePath -Segments @('.local', 'bin')),
    (Get-UserProfilePath -Segments @('bin')),
    (Get-UserProfilePath -Segments @('.cargo', 'bin')),
    (Get-UserProfilePath -Segments @('go', 'bin')),
    (Get-UserProfilePath -Segments @('.poetry', 'bin')),
    (Get-UserProfilePath -Segments @('.npm-global'))
)

foreach ($candidate in $localBinCandidates) {
    Add-PathIfMissing -Path $candidate
}



# Go development
if (Test-Path (Get-UserProfilePath -Segments @('go'))) {
    $env:GOPATH = Get-UserProfilePath -Segments @('go')
}

# Load shared cross-shell tooling modules
$toolRoot = Join-Path $scriptRoot 'tools.d'
$toolDir = Join-Path $toolRoot 'ps1'
if (Test-Path -LiteralPath $toolDir) {
    Get-ChildItem -Path $toolDir -Filter '*.ps1' -File | Sort-Object Name | ForEach-Object {
        . $_.FullName
    }
}

# Color settings
$env:CLICOLOR = '1'
