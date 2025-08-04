# Determine DOTFILES_ROOT and PROJECTS_ROOT for this shell
if (-not $env:DOTFILES_ROOT) {
    # Use the location of this profile to locate the repository root.  The profile resides in
    # $DOTFILES_ROOT\PowerShell\Microsoft.PowerShell_profile.ps1, so go up two directories.
    $currentFilePath = $PSCommandPath
    $profileDir = Split-Path -Parent $currentFilePath
    $env:DOTFILES_ROOT = Split-Path -Parent $profileDir
}
if (-not $env:PROJECTS_ROOT) {
    $env:PROJECTS_ROOT = Join-Path $HOME 'Projects'
}

# Load the new modular PowerShell configuration system
$modularIntegration = Join-Path $env:DOTFILES_ROOT 'shell/integration.ps1'
if (Test-Path $modularIntegration) {
    . $modularIntegration
}

# Load environment variables from .env files if the loader exists
$envLoader = Join-Path $env:DOTFILES_ROOT 'PowerShell/Utils/Load-Env.ps1'
if (Test-Path $envLoader) {
    . $envLoader
    # Load variables from the project .env
    Load-EnvFile -FilePath (Join-Path $env:DOTFILES_ROOT '.env')
    # Load variables from the MCP .env if it exists
    $mcpDir = Join-Path $env:DOTFILES_ROOT 'mcp'
    $mcpEnvFile = Join-Path $mcpDir '.env'
    Load-EnvFile -FilePath $mcpEnvFile
}

# Basic PowerShell setup - must come first
# Oh My Posh Theme Selection - can be overridden by environment variable
$defaultTheme = "powerlevel10k_classic.omp.json"
$ompTheme = if ($env:OMP_THEME) { $env:OMP_THEME } else { $defaultTheme }
$themePath = Join-Path $env:DOTFILES_ROOT "PowerShell/Themes/$ompTheme"

# Fallback to emodipt-extend if the theme doesn't exist
if (-not (Test-Path $themePath)) {
    Write-Warning "Theme '$ompTheme' not found, falling back to emodipt-extend.omp.json"
    $themePath = Join-Path $env:DOTFILES_ROOT 'PowerShell/Themes/emodipt-extend.omp.json'
}

oh-my-posh init pwsh --config "$themePath" | Invoke-Expression
Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue
Import-Module PSReadLine -ErrorAction SilentlyContinue
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

 $sharedShellConfig = Join-Path $env:DOTFILES_ROOT 'PowerShell/.shell_theme_common.ps1'
if (Test-Path $sharedShellConfig) {
    . $sharedShellConfig
}

# PNPM configuration
$env:PNPM_HOME = "$HOME\.pnpm-global"
$env:Path = "$env:PNPM_HOME;$env:Path"

# Lazy-load the Aliases module by creating proxy functions.
$aliasesModulePath = Join-Path $env:DOTFILES_ROOT 'PowerShell/Modules/Aliases/Aliases.psm1'

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
$setThemeScript = Join-Path $env:DOTFILES_ROOT 'PowerShell/Modules/Aliases/Set-OhMyPoshTheme.ps1'
if (Test-Path $setThemeScript) {
    . $setThemeScript
    function settheme { Set-OhMyPoshTheme @args }
    function gettheme { Get-OhMyPoshTheme @args }
    function listthemes { Set-OhMyPoshTheme -List @args }
} else {
    Write-Warning "Theme management script not found at: $setThemeScript"
    # Create basic fallback functions
    function settheme { Write-Host "Theme management not available - Set-OhMyPoshTheme.ps1 not found" -ForegroundColor Yellow }
    function gettheme { Write-Host "Theme management not available - Set-OhMyPoshTheme.ps1 not found" -ForegroundColor Yellow }
    function listthemes { Write-Host "Theme management not available - Set-OhMyPoshTheme.ps1 not found" -ForegroundColor Yellow }
}

# Single projects function that uses environment variable
function projects {
    Set-Location -Path $env:PROJECTS_ROOT
}

# Function to create Windows symlink to WSL projects directory
# Environment variables for customization:
#   WSL_PROJECTS_PATH - Custom Windows path for projects symlink (default: $env:USERPROFILE\projects)
#   WSL_USER - WSL username (default: $env:USERNAME)
#   WSL_DISTRO - WSL distribution name (default: auto-detected from wsl.exe -l -v)
function Link-WSLProjects {
    # Use environment variables for configuration with fallbacks
    $WindowsPath = $env:WSL_PROJECTS_PATH
    if (-not $WindowsPath) {
        $WindowsPath = Join-Path $env:USERPROFILE "projects"
    }

    $WSLUser = $env:WSL_USER
    if (-not $WSLUser) { $WSLUser = $env:USERNAME }

    $defaultDistro = $env:WSL_DISTRO
    if (-not $defaultDistro) {
        $defaultDistro = wsl.exe -l -v | Where-Object { $_ -match '\*' } | ForEach-Object {
            ($_ -split '\s+')[1]
        }
    }

    if (-not $defaultDistro) {
        Write-Error "Could not detect default WSL distro."
        return
    }

    # Build WSL UNC path
    $wslPath = "\\wsl.localhost\$defaultDistro\home\$WSLUser\projects"

    # Check if link already exists
    if (Test-Path $WindowsPath) {
        Write-Host "Link or folder already exists at $WindowsPath" -ForegroundColor Yellow
        return
    }

    # Create symbolic link using the working method
    try {
        # Remove any existing item first
        Remove-Item $WindowsPath -Force -ErrorAction SilentlyContinue

        # Create the symlink
        New-Item -ItemType SymbolicLink -Path $WindowsPath -Target $wslPath -Force | Out-Null
        Write-Host "✅ Successfully linked '$WindowsPath' to '$wslPath'" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create symbolic link: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "💡 Make sure PowerShell is running as Administrator" -ForegroundColor Yellow
    }
}

if ($env:TERM_PROGRAM -eq "kiro") { . "$(kiro --locate-shell-integration-path pwsh)" }
