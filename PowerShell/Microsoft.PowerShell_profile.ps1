# Basic PowerShell setup - must come first
# Oh My Posh Theme Selection - can be overridden by environment variable
$defaultTheme = "powerlevel10k_classic.omp.json"
$ompTheme = if ($env:OMP_THEME) { $env:OMP_THEME } else { $defaultTheme }
$themePath = "$HOME\dotfiles\PowerShell\Themes\$ompTheme"

# Fallback to emodipt-extend if the theme doesn't exist
if (-not (Test-Path $themePath)) {
    Write-Warning "Theme '$ompTheme' not found, falling back to emodipt-extend.omp.json"
    $themePath = "$HOME\dotfiles\PowerShell\Themes\emodipt-extend.omp.json"
}

oh-my-posh init pwsh --config "$themePath" | Invoke-Expression
Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue
Import-Module PSReadLine -ErrorAction SilentlyContinue
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

$sharedShellConfig = "$HOME\dotfiles\PowerShell\.shell_theme_common.ps1"
if (Test-Path $sharedShellConfig) {
    . $sharedShellConfig
}

# PNPM configuration
$env:PNPM_HOME = "$HOME\.pnpm-global"
$env:Path = "$env:PNPM_HOME;$env:Path"

# Lazy-load the Aliases module by creating proxy functions.
$aliasesModulePath = "$HOME\dotfiles\PowerShell\Modules\Aliases\Aliases.psm1"

function finddir { Import-Module $aliasesModulePath -Force; Find-Directory @args }
function grep { Import-Module $aliasesModulePath -Force; Find-Text @args }
function aliashelp { Import-Module $aliasesModulePath -Force; Get-AliasHelp @args }
function sizes { Import-Module $aliasesModulePath -Force; Get-FileSize @args }
function filetree { Import-Module $aliasesModulePath -Force; Get-FileTree @args }
function gs { Import-Module $aliasesModulePath -Force; Get-GitStatus @args }
function netstat { Import-Module $aliasesModulePath -Force; Get-NetworkConnections @args }
function gensecret { Import-Module $aliasesModulePath -Force; Get-SecretKey @args }
function sysinfo { Import-Module $aliasesModulePath -Force; Get-SystemInfo @args }

function updatealiases { Import-Module $aliasesModulePath -Force; Invoke-UpdateAliasesModule @args }
function gc { Import-Module $aliasesModulePath -Force; New-GitCommit @args }
function explore { Import-Module $aliasesModulePath -Force; Open-Explorer @args }
function projectroot { Import-Module $aliasesModulePath -Force; Set-ProjectRoot @args }
function json { Import-Module $aliasesModulePath -Force; Show-Json @args }
function killport { Import-Module $aliasesModulePath -Force; Stop-ProcessByPort @args }
function testnewfunction { Import-Module $aliasesModulePath -Force; Test-NewFunction @args }
function testport { Import-Module $aliasesModulePath -Force; Test-Port @args }
function aliasesmodulefunction { Import-Module $aliasesModulePath -Force; Update-AliasesModuleFunction @args }
function updateenv { Import-Module $aliasesModulePath -Force; Update-EnvVars @args }

# Theme management functions
. "$HOME\dotfiles\PowerShell\Modules\Aliases\Set-OhMyPoshTheme.ps1"
function settheme { Set-OhMyPoshTheme @args }
function gettheme { Get-OhMyPoshTheme @args }
function listthemes { Set-OhMyPoshTheme -List @args }

# Single projects function that uses environment variable
function projects {
    Set-Location -Path $env:PROJECTS_ROOT
}

if ($env:TERM_PROGRAM -eq "kiro") { . "$(kiro --locate-shell-integration-path pwsh)" }
