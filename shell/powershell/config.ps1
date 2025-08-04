# PowerShell-specific configuration
# Part of the modular dotfiles configuration system

# PowerShell execution policy (if not already set)
if ((Get-ExecutionPolicy) -eq 'Restricted') {
    Write-Warning "PowerShell execution policy is Restricted. Consider running: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
}

# PowerShell-specific settings
$PSDefaultParameterValues = @{
    '*:Encoding' = 'utf8'
    'Export-Csv:NoTypeInformation' = $true
    'ConvertTo-Csv:NoTypeInformation' = $true
}

# PSReadLine configuration (if available)
if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    
    if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
        Set-PSReadLineOption -EditMode Windows
        Set-PSReadLineOption -BellStyle None
        
        # Key bindings
        Set-PSReadLineKeyHandler -Key Tab -Function Complete
        Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteChar
        Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardDeleteWord
        Set-PSReadLineKeyHandler -Key Alt+d -Function DeleteWord
        Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function BackwardWord
        Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord
    }
}

# PowerShell history settings
$MaximumHistoryCount = 10000

# PowerShell-specific functions
function Get-PowerShellVersion {
    $PSVersionTable
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-CommandSource {
    param(
        [Parameter(Mandatory)]
        [string]$CommandName
    )
    
    $command = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($command) {
        [PSCustomObject]@{
            Name = $command.Name
            CommandType = $command.CommandType
            Source = $command.Source
            Definition = if ($command.CommandType -eq 'Alias') { $command.Definition } else { $command.Source }
        }
    } else {
        Write-Warning "Command '$CommandName' not found"
    }
}
Set-Alias -Name which -Value Get-CommandSource

function Start-ProfileTimer {
    $script:ProfileStartTime = Get-Date
}

function Stop-ProfileTimer {
    if ($script:ProfileStartTime) {
        $elapsed = (Get-Date) - $script:ProfileStartTime
        Write-Host "Profile loaded in $($elapsed.TotalMilliseconds)ms" -ForegroundColor Cyan
    }
}

# PowerShell profile management
function Edit-PowerShellProfile {
    if (Test-Path $PROFILE) {
        & $env:EDITOR $PROFILE
    } else {
        Write-Warning "PowerShell profile not found at: $PROFILE"
        $createProfile = Read-Host "Would you like to create it? (y/N)"
        if ($createProfile -eq 'y' -or $createProfile -eq 'Y') {
            New-Item -ItemType File -Path $PROFILE -Force
            & $env:EDITOR $PROFILE
        }
    }
}
Set-Alias -Name psprofile -Value Edit-PowerShellProfile

function Reload-PowerShellProfile {
    if (Test-Path $PROFILE) {
        . $PROFILE
        Write-Host "PowerShell profile reloaded" -ForegroundColor Green
    } else {
        Write-Warning "PowerShell profile not found at: $PROFILE"
    }
}
Set-Alias -Name reps -Value Reload-PowerShellProfile

# Module management helpers
function Get-ModuleCommands {
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )
    
    if (Get-Module $ModuleName -ErrorAction SilentlyContinue) {
        Get-Command -Module $ModuleName | Sort-Object Name
    } else {
        Write-Warning "Module '$ModuleName' is not loaded"
    }
}

function Find-Module {
    param(
        [Parameter(Mandatory)]
        [string]$Pattern
    )
    
    Get-Module -ListAvailable | Where-Object Name -like "*$Pattern*"
}

# PowerShell-specific aliases
Set-Alias -Name psversion -Value Get-PowerShellVersion
Set-Alias -Name isadmin -Value Test-Administrator
