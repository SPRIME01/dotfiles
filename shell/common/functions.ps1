# PowerShell common functions
# Part of the modular dotfiles configuration system

# Create directory and cd into it
function New-DirectoryAndEnter {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location $Path
}
Set-Alias -Name mkcd -Value New-DirectoryAndEnter

# Find files by name
function Find-Files {
    param(
        [Parameter(Mandatory)]
        [string]$Pattern,
        [string]$Path = "."
    )

    Get-ChildItem -Path $Path -Recurse -File -Filter "*$Pattern*" -ErrorAction SilentlyContinue
}
Set-Alias -Name ff -Value Find-Files

# Find directories by name
function Find-Directories {
    param(
        [Parameter(Mandatory)]
        [string]$Pattern,
        [string]$Path = "."
    )

    Get-ChildItem -Path $Path -Recurse -Directory -Filter "*$Pattern*" -ErrorAction SilentlyContinue
}
Set-Alias -Name fd -Value Find-Directories

# Quick grep with Select-String
function Search-Content {
    param(
        [Parameter(Mandatory)]
        [string]$Pattern,
        [Parameter(Mandatory)]
        [string]$Path
    )

    Select-String -Pattern $Pattern -Path $Path
}
Set-Alias -Name grepf -Value Search-Content

# Get public IP address
function Get-PublicIP {
    try {
        (Invoke-RestMethod -Uri "https://ifconfig.me/ip").Trim()
    } catch {
        Write-Error "Failed to get public IP: $($_.Exception.Message)"
    }
}
Set-Alias -Name myip -Value Get-PublicIP

# Create backup of file
function New-FileBackup {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = "$FilePath.bak.$timestamp"
    Copy-Item $FilePath $backupPath
    Write-Host "Backup created: $backupPath" -ForegroundColor Green
}
Set-Alias -Name backup -Value New-FileBackup

# Quick note taking
function Add-Note {
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Text
    )

    $noteDir = Join-Path $env:USERPROFILE ".notes"
    $noteFile = Join-Path $noteDir "$(Get-Date -Format 'yyyy-MM-dd').md"

    if (-not (Test-Path $noteDir)) {
        New-Item -ItemType Directory -Path $noteDir -Force | Out-Null
    }

    if ($Text.Count -eq 0) {
        # Open today's note file
        & $env:EDITOR $noteFile
    } else {
        # Add note with timestamp
        $timestamp = Get-Date -Format "HH:mm"
        $noteText = "$timestamp - $($Text -join ' ')"
        Add-Content -Path $noteFile -Value $noteText
        Write-Host "Note added to $noteFile" -ForegroundColor Green
    }
}
Set-Alias -Name note -Value Add-Note

# Process management helpers
function Get-ProcessByName {
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    Get-Process -Name "*$ProcessName*" -ErrorAction SilentlyContinue
}
Set-Alias -Name psg -Value Get-ProcessByName

# Disk usage
function Get-DiskUsage {
    param(
        [string]$Path = $null
    )

    if ($Path) {
        Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum |
            ForEach-Object {
                $size = $_.Sum / 1MB
                Write-Host "Total size: $($size.ToString('F2')) MB"
            }
    } else {
        Get-WmiObject -Class Win32_LogicalDisk |
            Select-Object DeviceID,
                @{Name="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}},
                @{Name="FreeSpace(GB)";Expression={[math]::Round($_.FreeSpace/1GB,2)}},
                @{Name="PercentFree";Expression={[math]::Round(($_.FreeSpace/$_.Size)*100,2)}}
    }
}
Set-Alias -Name usage -Value Get-DiskUsage

# Path manipulation (supports -Directory or legacy -Path)
function Add-ToPath {
    [CmdletBinding()] param(
        [Parameter(Mandatory)][Alias('Directory')][string]$Path,
        [switch]$Quiet
    )
    if (-not (Test-Path $Path)) {
        if (-not $Quiet) { Write-Warning "Directory does not exist: $Path" }
        return
    }
    $segments = $env:PATH -split ';'
    if ($segments -notcontains $Path) {
        $env:PATH = "$Path;" + $env:PATH
        if (-not $Quiet) { Write-Host "Added $Path to PATH" -ForegroundColor Green }
    } else {
        if (-not $Quiet) { Write-Host "$Path is already in PATH" -ForegroundColor Yellow }
    }
}

function Remove-FromPath {
    param(
        [Parameter(Mandatory)]
        [string]$Directory
    )

    $env:PATH = ($env:PATH -split ';' | Where-Object { $_ -ne $Directory }) -join ';'
    Write-Host "Removed $Directory from PATH" -ForegroundColor Green
}

# Show PATH in readable format
function Show-Path {
    $env:PATH -split ';' | Where-Object { $_ } | ForEach-Object { $i = 1 } { "$i. $_"; $i++ }
}
