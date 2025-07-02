$sharedShellConfig = "$HOME/.shell_theme_common.ps1"
if (Test-Path $sharedShellConfig) {
    . $sharedShellConfig
}

switch ($env:COMPUTERNAME) {
    "WORKSTATION-NAME" {
        $env:SPECIAL_VAR = "true"
        Write-Host "🔒 Loaded workstation-specific config"
    }
    "DEV-LAPTOP" {
        $env:SPECIAL_VAR = "false"
        Write-Host "🔒 Loaded dev laptop config"
    }
}

$modulePath = "$HOME/OneDrive/MyDocuments/PowerShell/Modules/Aliases/Aliases.psm1"
Import-Module $modulePath
