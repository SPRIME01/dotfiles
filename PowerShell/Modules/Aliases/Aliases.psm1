# filepath: c:\Users\sprim\OneDrive\MyDocuments\PowerShell\Modules\Aliases\Aliases.psm1
# PowerShell Custom Aliases and Functions Module
# Version: 1.2
# Last Modified: April 26, 2025
# Description: Loads functions from individual files and sets aliases.

# Get the path to the current module directory
$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Verbose "Loading functions from module path: $ModulePath"

# Dot-source individual function script files
try {
    . "$ModulePath\Get-FileTree.ps1"
    . "$ModulePath\Set-ProjectRoot.ps1"
    . "$ModulePath\Update-EnvVars.ps1"
    . "$ModulePath\Get-SecretKey.ps1"
    . "$ModulePath\Get-AliasHelp.ps1"
    . "$ModulePath\Update-Aliases.ps1"
    # Add more .ps1 files here as you create them
    Write-Verbose "Successfully dot-sourced function files."
}
catch {
    Write-Error "Failed to dot-source one or more function files: $_"
    # Optionally re-throw or handle the error appropriately
    return
}

# Define Aliases (can also be in a separate sourced file if preferred)
try {
    Set-Alias -Name filetree -Value Get-FileTree -Description "Alias for Get-FileTree" -Scope Global -Force
    Set-Alias -Name projectroot -Value Set-ProjectRoot -Description "Alias for Set-ProjectRoot" -Scope Global -Force
    Set-Alias -Name updateenv -Value Update-EnvVars -Description "Alias for Update-EnvVars" -Scope Global -Force
    Set-Alias -Name gensecret -Value Get-SecretKey -Description "Alias for Get-SecretKey" -Scope Global -Force
    Set-Alias -Name aliashelp -Value Get-AliasHelp -Description "Lists aliases defined in this module with descriptions." -Scope Global -Force
    Set-Alias -Name updatealiases -Value Update-Aliases -Description "Updates the Aliases module based on .ps1 files found." -Scope Global -Force
    Write-Verbose "Successfully set aliases."
}
catch {
    Write-Error "Failed to set one or more aliases: $_"
}

# Export all public functions and their aliases from this module
# List the FUNCTION NAMES here (not the filenames)
Export-ModuleMember -Function Get-FileTree, Set-ProjectRoot, Update-EnvVars, Get-SecretKey, Get-AliasHelp, Update-Aliases `
    -Alias filetree, projectroot, updateenv, gensecret, aliashelp, updatealiases

Write-Verbose "Aliases module loaded successfully."
