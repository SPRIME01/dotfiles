$sharedShellConfig = "$HOME\dotfiles\PowerShell\.shell_theme_common.ps1"
if (Test-Path $sharedShellConfig) {
    . $sharedShellConfig
}

# Initialize Python environment management (pyenv-win)
$pyenvInitScript = "$HOME\dotfiles\PowerShell\Modules\Aliases\Initialize-PyEnv.ps1"
if (Test-Path $pyenvInitScript) {
    . $pyenvInitScript
    Initialize-PyEnv
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

# Lazy-load the Aliases module by creating proxy functions.
# The module will be imported only when one of its commands is run for the first time.
$aliasesModulePath = "$HOME\dotfiles\PowerShell\Modules\Aliases\Aliases.psm1"
function finddir {
    Import-Module $aliasesModulePath -Force
    Find-Directory @args
}function grep {
    Import-Module $aliasesModulePath -Force
    Find-Text @args
}function aliashelp {
    Import-Module $aliasesModulePath -Force
    Get-AliasHelp @args
}function sizes {
    Import-Module $aliasesModulePath -Force
    Get-FileSize @args
}function filetree {
    Import-Module $aliasesModulePath -Force
    Get-FileTree @args
}function gs {
    Import-Module $aliasesModulePath -Force
    Get-GitStatus @args
}function netstat {
    Import-Module $aliasesModulePath -Force
    Get-NetworkConnections @args
}function projects {
    Import-Module $aliasesModulePath -Force
    Get-ProjectList @args
}function gensecret {
    Import-Module $aliasesModulePath -Force
    Get-SecretKey @args
}function sysinfo {
    Import-Module $aliasesModulePath -Force
    Get-SystemInfo @args
}function initializepyenv {
    Import-Module $aliasesModulePath -Force
    Initialize-PyEnv @args
}function updatealiases {
    Import-Module $aliasesModulePath -Force
    Invoke-UpdateAliasesModule @args
}function gc {
    Import-Module $aliasesModulePath -Force
    New-GitCommit @args
}function explore {
    Import-Module $aliasesModulePath -Force
    Open-Explorer @args
}function projectroot {
    Import-Module $aliasesModulePath -Force
    Set-ProjectRoot @args
}function json {
    Import-Module $aliasesModulePath -Force
    Show-Json @args
}function killport {
    Import-Module $aliasesModulePath -Force
    Stop-ProcessByPort @args
}function testnewfunction {
    Import-Module $aliasesModulePath -Force
    Test-NewFunction @args
}function testport {
    Import-Module $aliasesModulePath -Force
    Test-Port @args
}function aliasesmodule-function {
    Import-Module $aliasesModulePath -Force
    Update-AliasesModule-Function @args
}function aliasesmodulefunction {
    Import-Module $aliasesModulePath -Force
    Update-AliasesModuleFunction @args
}function updateenv {
    Import-Module $aliasesModulePath -Force
    Update-EnvVars @args
}
# Remaining PNPM and function definitions...
$env:PNPM_HOME = "$HOME\.pnpm-global" # Can also be relative to $HOME
$env:Path = "$env:PNPM_HOME;$env:Path"

function projects {
    Set-Location -Path "$HOME\Projects"
}
















