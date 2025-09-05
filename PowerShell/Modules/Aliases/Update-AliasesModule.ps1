# Update-AliasesModule.ps1
# This script completely regenerates the Aliases module and profile lazy-loading functions
# Version: 2.0
# Last Modified: July 2, 2025

<#
.SYNOPSIS
    Completely regenerates the Aliases module and profile lazy-loading functions.

.DESCRIPTION
    This script scans the module directory for .ps1 function files and:
    1. Completely regenerates the Aliases.psm1 module file with proper dot-sourcing, aliases, and exports
    2. Updates the PowerShell profile with corresponding lazy-loading proxy functions
    3. Creates backups of both files before making changes

.PARAMETER WhatIf
    Shows what would be done without making actual changes.

.PARAMETER Confirm
    Prompts for confirmation before making changes.

.EXAMPLE
    .\Update-AliasesModule.ps1
    Regenerates both the module and profile files.

.EXAMPLE
    .\Update-AliasesModule.ps1 -WhatIf
    Shows what changes would be made without executing them.

.NOTES
    This script replaces the functionality of both Update-Aliases.ps1 and Update-LazyLoaders.ps1.
#>

[CmdletBinding(SupportsShouldProcess)]
param()

#region Configuration
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# File paths
$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$MainModuleFile = Join-Path $ModulePath "Aliases.psm1"
# Build profile path cross-platform based on this repo's PowerShell folder
$PowerShellDir = Split-Path -Parent (Split-Path -Parent $ModulePath)
$ProfilePath = Join-Path $PowerShellDir 'Microsoft.PowerShell_profile.ps1'

# Configuration settings
$MaxBackups = 3
$ExcludedFiles = @("Aliases.psm1", "Update-Aliases.ps1", "Update-LazyLoaders.ps1", "Update-AliasesModule.ps1")

# Lazy-loading markers in profile
$LazyLoadStartMarker = "# Lazy-load the Aliases module by creating proxy functions."
$LazyLoadEndMarker = "# Remaining PNPM and function definitions..."
#endregion Configuration

#region Helper Functions
function Backup-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][int]$MaxCount
    )

    if (-not (Test-Path $FilePath)) {
        Write-Warning "File not found for backup: $FilePath"
        return $false
    }

    $directory = Split-Path $FilePath -Parent
    $fileName = Split-Path $FilePath -Leaf

    # Clean up old backups
    $existingBackups = Get-ChildItem -Path $directory -Filter "$fileName.*.bak" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime

    $backupsToRemove = $existingBackups.Count - $MaxCount + 1
    if ($backupsToRemove -gt 0) {
        $existingBackups | Select-Object -First $backupsToRemove | ForEach-Object {
            Write-Verbose "Removing old backup: $($_.FullName)"
            Remove-Item $_.FullName -Force
        }
    }

    # Create new backup
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "$FilePath.$timestamp.bak"

    try {
        Copy-Item $FilePath $backupFile -Force
        Write-Verbose "Created backup: $backupFile"
        return $true
    }
    catch {
        Write-Error "Failed to create backup of $FilePath`: $_"
        return $false
    }
}

function Get-FunctionInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][System.IO.FileInfo]$File
    )

    $functionName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)

    # Generate alias name using specific mapping to match current conventions
    $aliasMapping = @{
        'Get-FileTree'              = 'filetree'
        'Set-ProjectRoot'           = 'projectroot'
        'Update-EnvVars'            = 'updateenv'
        'Get-SecretKey'             = 'gensecret'
        'Get-AliasHelp'             = 'aliashelp'
        'Test-NewFunction'          = 'testnewfunction'
        'Invoke-UpdateAliasesModule' = 'updatealiases'
        'Find-Directory'            = 'finddir'
        'Open-Explorer'             = 'explore'
        'Get-GitStatus'             = 'gs'
        'New-GitCommit'             = 'gc'
        'Get-ProjectList'           = 'projects'
        'Stop-ProcessByPort'        = 'killport'
        'Find-Text'                 = 'grep'
        'Get-FileSize'              = 'sizes'
        'Get-SystemInfo'            = 'sysinfo'
        'Test-Port'                 = 'testport'
        'Get-NetworkConnections'    = 'netstat'
        'Show-Json'                 = 'json'
    }

    $aliasName = if ($aliasMapping.ContainsKey($functionName)) {
        $aliasMapping[$functionName]
    } else {
        # For any new functions, use lowercase with verb prefix removed
        if ($functionName -match '^(Get-|Set-|Update-)(.+)') {
            $matches[2].ToLower()
        } else {
            ($functionName -replace '-', '').ToLower()
        }
    }

    # Read file content to extract synopsis for description
    $content = Get-Content $File.FullName -Raw
    $synopsis = ""

    if ($content -match '(?s)\.SYNOPSIS\s*(.*?)\s*\.DESCRIPTION') {
        $synopsis = $matches[1].Trim() -replace '\s+', ' '
    }
    elseif ($content -match '(?s)\.SYNOPSIS\s*(.*?)\s*\.') {
        $synopsis = $matches[1].Trim() -replace '\s+', ' '
    }

    if ([string]::IsNullOrWhiteSpace($synopsis)) {
        $synopsis = "Alias for $functionName"
    }

    return @{
        FunctionName = $functionName
        AliasName = $aliasName
        FileName = $File.Name
        Synopsis = $synopsis
    }
}

function Generate-ModuleContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][array]$FunctionInfos
    )

    $content = @"
# filepath: $MainModuleFile
# PowerShell Custom Aliases and Functions Module
# Version: 2.0
# Last Modified: auto-generated
# Description: Loads functions from individual files and sets aliases.
# This file is auto-generated by Update-AliasesModule.ps1

# Get the path to the current module directory
`$ModulePath = Split-Path -Parent `$MyInvocation.MyCommand.Definition
Write-Verbose "Loading functions from module path: `$ModulePath"

# Dot-source individual function script files
try {
"@

    # Add dot-sourcing lines
    foreach ($info in $FunctionInfos) {
        # Use Join-Path for cross-platform path separators
        $content += "`n    . (Join-Path -Path ``$ModulePath -ChildPath '$($info.FileName)')"
    }

    $content += @"

    Write-Verbose "Successfully dot-sourced function files."
}
catch {
    Write-Error "Failed to dot-source one or more function files: `$_"
    return
}

# Define Aliases
try {
"@

    # Add alias definitions
    foreach ($info in $FunctionInfos) {
        $content += "`n    Set-Alias -Name $($info.AliasName) -Value $($info.FunctionName) -Description `"$($info.Synopsis)`" -Scope Global -Force"
    }

    $content += @"

    Write-Verbose "Successfully set aliases."
}
catch {
    Write-Error "Failed to set one or more aliases: `$_"
}

# Export all public functions and their aliases from this module
Export-ModuleMember -Function $($FunctionInfos.FunctionName -join ', ') ``
    -Alias $($FunctionInfos.AliasName -join ', ')

Write-Verbose "Aliases module loaded successfully."
"@

    return $content
}

function Generate-LazyLoadingFunctions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][array]$FunctionInfos
    )

    $content = @"
# Lazy-load the Aliases module by creating proxy functions.
# The module will be imported only when one of its commands is run for the first time.
`$aliasesModulePath = Join-Path -Path ``$PSScriptRoot -ChildPath (Join-Path -Path 'Modules' -ChildPath (Join-Path -Path 'Aliases' -ChildPath 'Aliases.psm1'))

"@

    foreach ($info in $FunctionInfos) {
        $content += @"
function $($info.AliasName) {
    Import-Module `$aliasesModulePath -Force
    $($info.FunctionName) @args
}
"@
    }

    return $content
}

function Update-ProfileFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$LazyLoadingContent
    )

    if (-not (Test-Path $ProfilePath)) {
        Write-Error "Profile file not found: $ProfilePath"
        return $false
    }

    $profileContent = Get-Content $ProfilePath -Raw

    # Find the lazy-loading section
    $startIndex = $profileContent.IndexOf($LazyLoadStartMarker)
    $endIndex = $profileContent.IndexOf($LazyLoadEndMarker)

    if ($startIndex -eq -1 -or $endIndex -eq -1) {
        Write-Warning "Could not find lazy-loading section markers in profile file; skipping profile update."
        return $true
    }

    # Replace the entire lazy-loading section including the end marker line
    $beforeSection = $profileContent.Substring(0, $startIndex)
    $endMarkerLineStart = $profileContent.IndexOf($LazyLoadEndMarker)
    $afterSection = $profileContent.Substring($endMarkerLineStart)

    # Check idempotency: if the section content is already identical, skip write
    $currentSection = $profileContent.Substring($startIndex, $endMarkerLineStart - $startIndex)
    $norm = { param($s) ($s -replace "\r\n?", "`n").Trim() }
    if (& $norm $currentSection -eq (& $norm ($LazyLoadingContent + "`n"))) {
        Write-Host "Profile lazy-loading section unchanged; skipping write." -ForegroundColor Yellow
        return $true
    }

    $newProfileContent = $beforeSection + $LazyLoadingContent + "`n" + $afterSection

    if ($PSCmdlet.ShouldProcess($ProfilePath, "Update lazy-loading functions")) {
        try {
            # Backup only when content is changing
            [void](Backup-File -FilePath $ProfilePath -MaxCount $MaxBackups)
            Set-Content -Path $ProfilePath -Value $newProfileContent -Encoding UTF8
            Write-Host "Successfully updated profile file: $ProfilePath" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Error "Failed to update profile file: $_"
            return $false
        }
    }

    return $false
}
#endregion Helper Functions

#region Main Process
try {
    Write-Host "Starting Aliases module regeneration..." -ForegroundColor Cyan

    # Step 1: Find all function files
    Write-Verbose "Scanning for function files in: $ModulePath"
    $functionFiles = Get-ChildItem -Path $ModulePath -Filter "*.ps1" -File |
        Where-Object { $_.Name -notin $ExcludedFiles }

    if ($functionFiles.Count -eq 0) {
        Write-Warning "No function files found to process"
        return
    }

    Write-Host "Found $($functionFiles.Count) function files to process" -ForegroundColor Yellow

    # Step 2: Extract function information
    $functionInfos = @()
    foreach ($file in $functionFiles) {
        $info = Get-FunctionInfo -File $file
        $functionInfos += $info
        Write-Verbose "Processed: $($info.FunctionName) -> $($info.AliasName)"
    }

    # Step 3: Generate new module content
    Write-Host "Generating new module content..." -ForegroundColor Yellow
    $newModuleContent = Generate-ModuleContent -FunctionInfos $functionInfos

    # Step 4: Generate lazy-loading functions
    Write-Host "Generating lazy-loading functions..." -ForegroundColor Yellow
    $lazyLoadingContent = Generate-LazyLoadingFunctions -FunctionInfos $functionInfos

    # Step 5: Write new module file only if content changed
    $existingModuleContent = ""
    if (Test-Path $MainModuleFile) { $existingModuleContent = Get-Content -Path $MainModuleFile -Raw }
    if ($existingModuleContent -ne $newModuleContent) {
        if ($PSCmdlet.ShouldProcess($MainModuleFile, "Regenerate module file")) {
            try {
                [void](Backup-File -FilePath $MainModuleFile -MaxCount $MaxBackups)
                Set-Content -Path $MainModuleFile -Value $newModuleContent -Encoding UTF8
                Write-Host "Successfully regenerated module file: $MainModuleFile" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to write module file: $_"
                return
            }
        }
    }
    else {
        Write-Host "Module file unchanged; skipping write." -ForegroundColor Yellow
    }

    # Step 6: Update profile file (idempotent inside function)
    [void](Update-ProfileFile -LazyLoadingContent $lazyLoadingContent)

    # Step 8: Display summary
    Write-Host "`nModule regeneration completed successfully!" -ForegroundColor Green
    Write-Host "Functions processed:" -ForegroundColor Cyan

    $functionInfos | ForEach-Object {
        Write-Host "  $($_.FunctionName) -> $($_.AliasName)" -ForegroundColor White
    }

    Write-Host "`nTo apply changes to your current session (run in PowerShell):" -ForegroundColor Yellow
    Write-Host "  Import-Module '$MainModuleFile' -Force" -ForegroundColor White
    Write-Host "  . '$ProfilePath'" -ForegroundColor White

}
catch {
    Write-Error "Error during module regeneration: $_"
}
#endregion Main Process
