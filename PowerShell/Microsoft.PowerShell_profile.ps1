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

# Ensure USERPROFILE is set (Linux pwsh may not define it) to avoid Join-Path null errors in modules/tests
if (-not $env:USERPROFILE -or $env:USERPROFILE -eq '') {
    $env:USERPROFILE = $HOME
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
$defaultTheme = "powerlevel10k_classic.omp.json"
$ompTheme = if ($env:OMP_THEME) { $env:OMP_THEME } else { $defaultTheme }
$themePath = Join-Path $env:DOTFILES_ROOT "PowerShell/Themes/$ompTheme"

# Fallback to emodipt-extend if the theme doesn't exist
if (-not (Test-Path $themePath)) {
    Write-Warning "Theme '$ompTheme' not found, falling back to emodipt-extend.omp.json"
    $themePath = Join-Path $env:DOTFILES_ROOT 'PowerShell/Themes/emodipt-extend.omp.json'
}

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$themePath" | Invoke-Expression
} else {
    Write-Verbose "oh-my-posh not found; skipping prompt init" -Verbose:$false
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

# WSL-aware VS Code launchers: make `code .` work from UNC paths
try { Remove-Item Alias:code -ErrorAction SilentlyContinue } catch {}
try { Remove-Item Alias:code-insiders -ErrorAction SilentlyContinue } catch {}

function code {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]] $args)

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'),
        (Join-Path ${env:ProgramFiles} 'Microsoft VS Code\Code.exe'),
        ($(if (${env:ProgramFiles(x86)}) { Join-Path ${env:ProgramFiles(x86)} 'Microsoft VS Code\Code.exe' } else { $null }))
    )
    $codeExe = ($candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1)
    if (-not $codeExe) { $codeExe = 'code.cmd' }

    $pwdPath = (Get-Location).Path
    if ($pwdPath -match '^\\\\wsl(?:\.localhost)?\\([^\\]+)\\(.+)$') {
        $distro = $Matches[1]
        $rest = $Matches[2]
        $linuxPath = "/" + ($rest -replace '\\','/')

        $forwardArgs = @()
        if ($args -and $args.Count -gt 0) {
            foreach ($a in $args) {
                if ($a -eq '.') { $forwardArgs += $linuxPath } else { $forwardArgs += $a }
            }
        } else {
            $forwardArgs = @($linuxPath)
        }
        & $codeExe '--remote' ("wsl+{0}" -f $distro) @forwardArgs
        return
    }

    & $codeExe @args
}

function code-insiders {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]] $args)

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code Insiders\Code - Insiders.exe'),
        (Join-Path ${env:ProgramFiles} 'Microsoft VS Code Insiders\Code - Insiders.exe'),
        ($(if (${env:ProgramFiles(x86)}) { Join-Path ${env:ProgramFiles(x86)} 'Microsoft VS Code Insiders\Code - Insiders.exe' } else { $null }))
    )
    $codeExe = ($candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1)
    if (-not $codeExe) { $codeExe = 'code-insiders.cmd' }

    $pwdPath = (Get-Location).Path
    if ($pwdPath -match '^\\\\wsl(?:\.localhost)?\\([^\\]+)\\(.+)$') {
        $distro = $Matches[1]
        $rest = $Matches[2]
        $linuxPath = "/" + ($rest -replace '\\','/')

        $forwardArgs = @()
        if ($args -and $args.Count -gt 0) {
            foreach ($a in $args) {
                if ($a -eq '.') { $forwardArgs += $linuxPath } else { $forwardArgs += $a }
            }
        } else {
            $forwardArgs = @($linuxPath)
        }
        & $codeExe '--remote' ("wsl+{0}" -f $distro) @forwardArgs
        return
    }

    & $codeExe @args
}

# Dedicated Remote‑WSL launchers that work from any path
function wslcode {
    param(
        [string]$Path = '.',
        [string]$Distro
    )

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'),
        (Join-Path ${env:ProgramFiles} 'Microsoft VS Code\Code.exe'),
        ($(if (${env:ProgramFiles(x86)}) { Join-Path ${env:ProgramFiles(x86)} 'Microsoft VS Code\Code.exe' } else { $null }))
    )
    $codeExe = ($candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1)
    if (-not $codeExe) { $codeExe = 'code.cmd' }

    if (-not $Distro -or $Distro -eq '') {
        try {
            $Distro = (wsl.exe -l -v 2>$null | Select-String '\*' | ForEach-Object { ($_ -replace '\*','').Trim().Split()[0] } | Select-Object -First 1)
        } catch { $Distro = $null }
        if (-not $Distro) { $Distro = 'Ubuntu-24.04' }
    }

    $pwdPath = (Get-Location).Path
    $src = if ($Path -eq '.') { $pwdPath } else { $Path }
    if ($src -match '^\\\\wsl(?:\.localhost)?\\([^\\]+)\\(.+)$') {
        if (-not $Distro) { $Distro = $Matches[1] }
        $linuxPath = '/' + ($Matches[2] -replace '\\','/')
    } elseif ($src -match '^[A-Za-z]:\\') {
        $drive = $src.Substring(0,1).ToLower()
        $linuxPath = '/mnt/' + $drive + ($src.Substring(2) -replace '\\','/')
    } else {
        $linuxPath = $src
    }

    & $codeExe '--remote' ("wsl+{0}" -f $Distro) $linuxPath
}

function wslcodei {
    param(
        [string]$Path = '.',
        [string]$Distro
    )

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code Insiders\Code - Insiders.exe'),
        (Join-Path ${env:ProgramFiles} 'Microsoft VS Code Insiders\Code - Insiders.exe'),
        ($(if (${env:ProgramFiles(x86)}) { Join-Path ${env:ProgramFiles(x86)} 'Microsoft VS Code Insiders\Code - Insiders.exe' } else { $null }))
    )
    $codeExe = ($candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1)
    if (-not $codeExe) { $codeExe = 'code-insiders.cmd' }

    if (-not $Distro -or $Distro -eq '') {
        try {
            $Distro = (wsl.exe -l -v 2>$null | Select-String '\*' | ForEach-Object { ($_ -replace '\*','').Trim().Split()[0] } | Select-Object -First 1)
        } catch { $Distro = $null }
        if (-not $Distro) { $Distro = 'Ubuntu-24.04' }
    }

    $pwdPath = (Get-Location).Path
    $src = if ($Path -eq '.') { $pwdPath } else { $Path }
    if ($src -match '^\\\\wsl(?:\.localhost)?\\([^\\]+)\\(.+)$') {
        if (-not $Distro) { $Distro = $Matches[1] }
        $linuxPath = '/' + ($Matches[2] -replace '\\','/')
    } elseif ($src -match '^[A-Za-z]:\\') {
        $drive = $src.Substring(0,1).ToLower()
        $linuxPath = '/mnt/' + $drive + ($src.Substring(2) -replace '\\','/')
    } else {
        $linuxPath = $src
    }

    & $codeExe '--remote' ("wsl+{0}" -f $Distro) $linuxPath
}

# Function to create Windows symlink to WSL projects directory
# Environment variables for customization:
#   WSL_PROJECTS_PATH - Custom Windows path for projects symlink (default: $env:USERPROFILE\projects)
#   WSL_USER - WSL username (default: $env:USERNAME)
#   WSL_DISTRO - WSL distribution name (default: auto-detected from wsl.exe -l -v)
function Link-WSLProjects {
    # Use environment variables for configuration with fallbacks
    $WSL_USER = if ($env:WSL_USER) { $env:WSL_USER } else { $env:USERNAME }
    $WSL_DISTRO = if ($env:WSL_DISTRO) { $env:WSL_DISTRO } else {
        try {
            (wsl.exe -l -v 2>$null | Select-String '*' | ForEach-Object { ($_ -replace '\*', '').Trim() } | Select-Object -First 1)
        } catch { '' }
    }
    $DefaultProjects = Join-Path $env:USERPROFILE 'projects'
    $WIN_PROJECTS = if ($env:WSL_PROJECTS_PATH) { $env:WSL_PROJECTS_PATH } else { $DefaultProjects }

    if (-not $WSL_DISTRO) {
        Write-Warning 'Could not detect WSL distro. Set $env:WSL_DISTRO to proceed.'
        return
    }

    $wslPath = "\\\\wsl.localhost\\$WSL_DISTRO\\home\\$WSL_USER\\projects"
    if (-not (Test-Path $WIN_PROJECTS)) {
        New-Item -ItemType Directory -Path $WIN_PROJECTS -Force | Out-Null
    }
    try {
        New-Item -ItemType SymbolicLink -Path $WIN_PROJECTS -Target $wslPath -Force | Out-Null
        Write-Host "Linked Windows projects to $wslPath" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to create symlink. Try enabling Developer Mode or run elevated."
    }
}

# --- WSL Interop Convenience (Windows only) ---
if ($IsWindows) {
    function Initialize-WSLInterop {
        # Gently wake WSL to ensure UNC is available
        try { wsl.exe -l -q *> $null } catch {}
        try {
            # Prefer quiet list of distro names
            $d = (wsl.exe -l -q 2>$null | Where-Object { $_ -and $_.Trim() -ne '' } | Select-Object -First 1)
            if (-not $d) {
                # Fallback: parse starred default from verbose list and take the first token (name)
                $d = (wsl.exe -l -v 2>$null | Select-String '^\s*\*' | ForEach-Object { ($_ -replace '^\s*\*','').Trim().Split()[0] } | Select-Object -First 1)
            }
        } catch { $d = '' }
        if (-not $d) { $d = 'Ubuntu' }
        # Sanitize any embedded nulls and whitespace
        $d = ($d -replace "`0", '').Trim()
        $global:WSLDistro = $d
        # Prefer \\wsl.localhost, fallback to legacy \\wsl$
        $rootCandidates = @(("\\wsl.localhost\" + $d), ("\\wsl$\" + $d))
        $chosen = $null
        foreach ($rc in $rootCandidates) {
            # Retry a few times to allow UNC to appear
            for ($i=0; $i -lt 8; $i++) {
                if (Test-Path $rc) { $chosen = $rc; break }
                Start-Sleep -Milliseconds 150
            }
            if ($chosen) { break }
        }
        if (-not $chosen) { $chosen = ("\\wsl.localhost\" + $d) }
        $global:WSLRoot = $chosen
        try { $global:WSLUser = (wsl.exe -d $d -e sh -lc 'echo -n $USER' 2>$null) } catch { $global:WSLUser = $env:USERNAME.ToLower() }
        $global:wsl = $global:WSLRoot
        if (-not (Get-PSDrive -Name 'WSL' -ErrorAction SilentlyContinue)) {
            try { New-PSDrive -Name 'WSL' -PSProvider FileSystem -Root $global:WSLRoot -Scope Global -ErrorAction SilentlyContinue | Out-Null } catch {}
        }
    }
    Initialize-WSLInterop

    # Aliases + helpers
    Set-Alias ubuntu wsl -ErrorAction SilentlyContinue
    function Run-LinuxCommand {
        param([Parameter(ValueFromRemainingArguments = $true)][string[]] $Args)
        if (-not $Args -or $Args.Count -eq 0) { Write-Host 'Usage: Run-LinuxCommand <command...>'; return }
        $cmd = ($Args -join ' ')
        wsl.exe bash -lc $cmd
    }
    Set-Alias rlc Run-LinuxCommand -ErrorAction SilentlyContinue

    function wslcd {
        param([string]$Path = '~')
        if (-not $global:WSLRoot) { Initialize-WSLInterop }
        $p = $Path
        if ($p -eq '~') { $p = "home/$global:WSLUser" }
        if ($p.StartsWith('/')) { $p = $p.TrimStart('/') }
        $p = ($p -replace '/', '\\')
        $dest = Join-Path $global:WSLRoot $p
        Set-Location -LiteralPath $dest
    }

    function Mount-WSLDrive {
        param([string]$Name = 'L', [switch]$Persist)
        if (-not $global:WSLRoot) { Initialize-WSLInterop }
        $args = @{ Name = $Name; PSProvider = 'FileSystem'; Root = $global:WSLRoot }
        if ($Persist) { $args['Persist'] = $true }
        try { New-PSDrive @args | Out-Null; Write-Host ("✅ Mounted ${Name}: -> " + $global:WSLRoot) -ForegroundColor Green } catch { Write-Warning $_.Exception.Message }
    }
}

# Make `just` work globally in Windows by falling back to a global justfile
# Only apply on Windows so WSL/Linux pwsh aren't affected
if ($IsWindows) {
    function just {
        param([Parameter(ValueFromRemainingArguments = $true)][string[]] $Args)

        # Ensure just.exe is installed
        $justCmd = Get-Command just.exe -ErrorAction SilentlyContinue
        if (-not $justCmd) {
            Write-Error 'just.exe not found on PATH. Install from https://github.com/casey/just/releases or via winget/choco.'
            return
        }

        # Detect a local justfile by walking up directories
        $hasLocal = $false
        $dir = (Get-Location).Path
        while ($true) {
            if (Test-Path (Join-Path $dir 'justfile')) { $hasLocal = $true; break }
            $parent = Split-Path -Parent $dir
            if (-not $parent -or $parent -eq $dir) { break }
            $dir = $parent
        }

        if ($hasLocal) {
            & $justCmd @Args
            return
        }

        # Fallback global justfile locations
        $candidates = @(
            (Join-Path $env:APPDATA 'just\justfile'),
            (Join-Path $HOME '.config\just\justfile')
        )
        $global = ($candidates | Where-Object { Test-Path $_ } | Select-Object -First 1)

        if ($global) {
            & $justCmd --justfile $global @Args
        } else {
            # No global justfile: run normally (will error with "No justfile found")
            & $justCmd @Args
        }
    }
}
