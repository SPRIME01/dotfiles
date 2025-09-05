# Determine DOTFILES_ROOT and PROJECTS_ROOT for this shell
# Minimal early utility definitions (must come before modular load and theme init)
# Debug toggle: set $env:DOTFILES_PWSH_DEBUG=1 to enable debug lines.
$__DotfilesPwshDebug = $false
# Consider the session non-interactive if stdin is not a TTY or when explicitly disabled
$__IsInteractive = $Host.UI.RawUI -ne $null -and ($PSVersionTable.PSEdition -ne 'Core' -or $Host.Name -ne 'ServerRemoteHost')
if ($env:DOTFILES_PWSH_NONINTERACTIVE -in @('1','true','True','TRUE','yes','YES')) { $__IsInteractive = $false }
if ($env:DOTFILES_PWSH_DEBUG -in @('0','false','False','FALSE','no','NO')) { $__DotfilesPwshDebug = $false }
function __Dotfiles-Debug {
    param([Parameter(Mandatory)][string]$Message)
    if ($__DotfilesPwshDebug -and $__IsInteractive) { Write-Host $Message -ForegroundColor DarkCyan }
}
if (-not (Get-Command Add-ToPath -ErrorAction SilentlyContinue)) {
    function Add-ToPath {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)][Alias('Directory')][string]$Path,
            [switch]$Quiet
        )
        if ([string]::IsNullOrWhiteSpace($Path)) { return }
        if (-not (Test-Path $Path)) { if (-not $Quiet) { Write-Verbose "Path not found: $Path" } ; return }
        $segments = $env:PATH -split ';'
        if ($segments -notcontains $Path) {
            $env:PATH = "$Path;" + $env:PATH
            if (-not $Quiet) { Write-Verbose "Added $Path to PATH" }
        } else {
            if (-not $Quiet) { Write-Verbose "Already in PATH: $Path" }
        }
    }
}
if (-not $env:DOTFILES_ROOT) {
    # Use the location of this profile to locate the repository root.  The profile resides in
    # $DOTFILES_ROOT\PowerShell\Microsoft.PowerShell_profile.ps1, so go up two directories.
    $currentFilePath = $PSCommandPath
    $profileDir = Split-Path -Parent $currentFilePath
    $env:DOTFILES_ROOT = Split-Path -Parent $profileDir
    __Dotfiles-Debug "🔍 Debug: DOTFILES_ROOT = $($env:DOTFILES_ROOT)"
}
if (-not $env:PROJECTS_ROOT) { $env:PROJECTS_ROOT = Join-Path $HOME 'Projects' }
__Dotfiles-Debug "🔍 Debug: PROJECTS_ROOT = $($env:PROJECTS_ROOT)"

# Ensure USERPROFILE is set (Linux pwsh may not define it) to avoid Join-Path null errors in modules/tests
if (-not $env:USERPROFILE -or $env:USERPROFILE -eq '') {
    $env:USERPROFILE = $HOME
}

# Load the new modular PowerShell configuration system
$modularIntegration = Join-Path $env:DOTFILES_ROOT 'shell/integration.ps1'
__Dotfiles-Debug "🔍 Debug: Looking for main profile at: $(Join-Path $env:DOTFILES_ROOT 'PowerShell/Microsoft.PowerShell_profile.ps1')"
if (Test-Path $modularIntegration) { . $modularIntegration } else { __Dotfiles-Debug "🔍 Debug: modular integration script missing ($modularIntegration)" }

# Load environment variables from .env files if the loader exists
$envLoader = Join-Path $env:DOTFILES_ROOT 'PowerShell/Utils/Load-Env.ps1'
if (Test-Path $envLoader) {
    . $envLoader
    # Load variables from the project .env (if present)
    $rootEnv = Join-Path $env:DOTFILES_ROOT '.env'
    if (Test-Path $rootEnv) { Load-EnvFile -FilePath $rootEnv }
    # Load variables from the MCP .env if it exists
    $mcpDir = Join-Path $env:DOTFILES_ROOT 'mcp'
    $mcpEnvFile = Join-Path $mcpDir '.env'
    if (Test-Path $mcpEnvFile) { Load-EnvFile -FilePath $mcpEnvFile }
}

# Basic PowerShell setup - must come first
# Oh My Posh Theme Selection - can be overridden by environment variable
$defaultTheme = "powerlevel10k_modern.omp.json"
$ompTheme = if ($env:OMP_THEME) { $env:OMP_THEME } else { $defaultTheme }
$themePath = Join-Path $env:DOTFILES_ROOT "PowerShell/Themes/$ompTheme"

# Fallback to emodipt-extend if the theme doesn't exist
if (-not (Test-Path $themePath)) {
    if ($__IsInteractive) { Write-Warning "Theme '$ompTheme' not found, falling back to emodipt-extend.omp.json" }
    $themePath = Join-Path $env:DOTFILES_ROOT 'PowerShell/Themes/emodipt-extend.omp.json'
}

# Initialize Oh My Posh if available
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    if ($__IsInteractive) { Write-Warning "oh-my-posh not found on PATH. Install via: winget install JanDeDobbeleer.OhMyPosh or scoop install oh-my-posh" }
} else {
    try {
        oh-my-posh init pwsh --config "$themePath" | Invoke-Expression
    } catch {
        if ($__IsInteractive) { Write-Warning "oh-my-posh initialization failed: $($_.Exception.Message)" }
    }
}
Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue
Import-Module PSReadLine -ErrorAction SilentlyContinue
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

# Changed: source the shared theme config from the repo root ('.shell_theme_common.ps1')
$sharedShellConfig = Join-Path $env:DOTFILES_ROOT '.shell_theme_common.ps1'
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
    if ($__IsInteractive) { Write-Warning "Theme management script not found at: $setThemeScript" }
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

# SSH Agent Bridge Integration for WSL
if ($env:WSL_DISTRO_NAME -or (Get-Content /proc/version -ErrorAction SilentlyContinue | Select-String -Pattern "microsoft" -Quiet)) {
    # Set SSH_AUTH_SOCK if not already set
    if (-not $env:SSH_AUTH_SOCK) {
        $env:SSH_AUTH_SOCK = (Join-Path $HOME ".ssh/agent.sock")
    }
    # Check if bridge tools are available
    $socatAvailable = Get-Command socat -ErrorAction SilentlyContinue
    $npiperelayAvailable = (Get-Command npiperelay.exe -ErrorAction SilentlyContinue) -or (Get-Command npiperelay -ErrorAction SilentlyContinue)

    if ($socatAvailable -and $npiperelayAvailable) {
    if ($socatAvailable -and $npiperelayAvailable) {
        # Bridge tools available
        $agentOk = $false
        try {
            & ssh-add -l *> $null
            if ($LASTEXITCODE -eq 0) { $agentOk = $true }
        } catch {
            $agentOk = $false
        }
        if (-not $agentOk) {
            Write-Host "⚠️ SSH agent bridge tools available but agent not reachable via $env:SSH_AUTH_SOCK" -ForegroundColor Yellow
            Write-Host "💡 Run 'ssh-agent-bridge/preflight.sh' to diagnose bridge status" -ForegroundColor Cyan
        }
    } else {
        Write-Host "💡 Install npiperelay and socat, then run 'scripts/setup-ssh-agent-bridge.sh'" -ForegroundColor Cyan
    }

    # Helper function to check bridge status
    function Get-SshBridgeStatus {
        $preflightScript = Join-Path $env:DOTFILES_ROOT "ssh-agent-bridge/preflight.sh"
        if (Test-Path $preflightScript) {
            & $preflightScript
        } else {
            Write-Host "Preflight script not found: $preflightScript" -ForegroundColor Yellow
            Write-Host "Available SSH keys:"
            try {
                ssh-add -l
            } catch {
                Write-Host "No SSH keys loaded or agent not available" -ForegroundColor Yellow
            }
        }
    }

    # Set alias for convenience
    Set-Alias -Name ssh-bridge-status -Value Get-SshBridgeStatus -ErrorAction SilentlyContinue
}
