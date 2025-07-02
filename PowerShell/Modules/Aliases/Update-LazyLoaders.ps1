
# Update-LazyLoaders.ps1
# This script automatically generates lazy-loading proxy functions for the Aliases module.

$modulePath = "$HOME\dotfiles\PowerShell\Modules\Aliases"
$profilePath = "$HOME\dotfiles\PowerShell\Microsoft.PowerShell_profile.ps1"

# Get all function names from the .ps1 files in the module directory
$functionFiles = Get-ChildItem -Path $modulePath -Filter "*.ps1"
$functionNames = $functionFiles | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_) }

# Generate the lazy-loading proxy functions
$lazyLoaders = $functionNames | ForEach-Object {
    $functionName = $_
    $aliasName = ($functionName -split '(?=[A-Z])' | ForEach-Object { $_.ToLower() }) -join ''
    @"
function $aliasName {
    Import-Module "$modulePath\Aliases.psm1" -Force
    $functionName @args
}
"@
}

# Read the existing profile content
$profileContent = Get-Content -Path $profilePath -Raw

# Replace the old lazy-loaders with the new ones
$startMarker = "# Lazy-load the Aliases module"
$endMarker = "# Remaining PNPM and function definitions..."
$newProfileContent = $profileContent -replace "(?s)$startMarker.*$endMarker", "$startMarker`n$($lazyLoaders -join "`n")`n$endMarker"

# Write the updated content back to the profile
Set-Content -Path $profilePath -Value $newProfileContent

Write-Host "Successfully updated lazy-loading functions in $profilePath"
