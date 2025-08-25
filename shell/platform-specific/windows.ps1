# Windows-specific PowerShell configuration
# Part of the modular dotfiles configuration system

# Windows-specific environment variables
if (-not $env:BROWSER) { $env:BROWSER = "start" }

# Windows-specific aliases
function explorer. { explorer . }
function notepad { notepad.exe @args }

# Package manager aliases
if (Get-Command winget -ErrorAction SilentlyContinue) {
    function install { winget install @args }
    function search { winget search @args }
    function uninstall { winget uninstall @args }
    function upgrade { winget upgrade @args }
}

if (Get-Command choco -ErrorAction SilentlyContinue) {
    function choco-install { choco install @args }
    function choco-upgrade { choco upgrade all }
    function choco-search { choco search @args }
}

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    function scoop-install { scoop install @args }
    function scoop-update { scoop update * }
    function scoop-search { scoop search @args }
}

# Windows-specific functions
function Get-WindowsVersion {
    Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory
}

function Start-ElevatedPowerShell {
    Start-Process PowerShell -Verb RunAs
}
Set-Alias -Name sudo -Value Start-ElevatedPowerShell

function Get-WindowsFeatures {
    Get-WindowsOptionalFeature -Online | Where-Object State -eq "Enabled"
}

function Test-Port {
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,
        [Parameter(Mandatory)]
        [int]$Port,
        [int]$Timeout = 5000
    )

    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connect = $tcpClient.BeginConnect($ComputerName, $Port, $null, $null)
    $wait = $connect.AsyncWaitHandle.WaitOne($Timeout, $false)

    if ($wait) {
        try {
            $tcpClient.EndConnect($connect)
            $result = $true
        } catch {
            $result = $false
        }
    } else {
        $result = $false
    }

    $tcpClient.Close()
    return $result
}

function Get-SystemInfo {
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        PowerShellVersion = $PSVersionTable.PSVersion
        DotNetVersion = [System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
        OSVersion = [System.Environment]::OSVersion
        ProcessorCount = [System.Environment]::ProcessorCount
        MachineName = [System.Environment]::MachineName
        UserDomainName = [System.Environment]::UserDomainName
        WorkingSet = [math]::Round((Get-Process -Id $PID).WorkingSet / 1MB, 2)
    }
}
Set-Alias -Name sysinfo -Value Get-SystemInfo

# Windows path additions
$WindowsPaths = @(
    "$env:ProgramFiles\Git\bin",
    "$env:ProgramFiles\Docker\Docker\resources\bin",
    "$env:ProgramFiles\Microsoft VS Code\bin",
    "$env:USERPROFILE\.dotnet\tools"
)

foreach ($WinPath in $WindowsPaths) {
    if (Test-Path $WinPath) {
    Add-ToPath -Directory $WinPath -Quiet
    }
}

# WSL integration functions
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    function Enter-WSL {
        param([string]$Distribution = $null)

        if ($Distribution) {
            wsl -d $Distribution
        } else {
            wsl
        }
    }
    Set-Alias -Name wsl-enter -Value Enter-WSL

    function Get-WSLDistributions {
        wsl --list --verbose
    }
    Set-Alias -Name wsl-list -Value Get-WSLDistributions
}
