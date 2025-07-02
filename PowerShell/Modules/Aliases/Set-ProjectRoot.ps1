########## Set-ProjectRoot function
<#
.SYNOPSIS
Changes the current location to a specified project directory.
.DESCRIPTION
A simple wrapper around Set-Location for quickly navigating to project roots.
.PARAMETER Path
The path to the directory to set as the current location.
.EXAMPLE
Set-ProjectRoot C:\MyProject
# Changes directory to C:\MyProject
.EXAMPLE
projectroot ..\OtherProject
# Uses alias to navigate to a relative path
#>
function Set-ProjectRoot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )
    try {
        Set-Location -Path $Path -ErrorAction Stop
        Write-Host "Current location set to: $(Get-Location)" -ForegroundColor Cyan
    }
    catch {
        Write-Error "Failed to set location to '$Path': $_"
    }
}

# Alias for Set-ProjectRoot
# Set-Alias -Name projectroot -Value Set-ProjectRoot -Description "Alias for Set-ProjectRoot" -Scope Global -Force
