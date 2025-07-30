# Windows SSH Agent Setup Script
param(
    [string]$KeyPath = "$env:USERPROFILE\.ssh\id_ed25519",
    [switch]$Force
)

Write-Host "Setting up Windows SSH Agent..." -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Warning "Some operations require Administrator privileges"
}

try {
    # Configure SSH Agent Service
    Write-Host "Configuring SSH Agent Service..." -ForegroundColor Green

    $sshAgentService = Get-Service ssh-agent -ErrorAction SilentlyContinue
    if ($sshAgentService) {
        if ($isAdmin) {
            Set-Service ssh-agent -StartupType Automatic
            Write-Host "SSH Agent service set to start automatically" -ForegroundColor Green

            if ($sshAgentService.Status -ne "Running") {
                Start-Service ssh-agent
                Write-Host "SSH Agent service started" -ForegroundColor Green
            }
        } else {
            Write-Warning "Cannot configure service without Administrator privileges"
        }
    } else {
        Write-Error "SSH Agent service not found"
        exit 1
    }

    # Add SSH Key
    Write-Host "Adding SSH Key..." -ForegroundColor Green

    if (Test-Path $KeyPath) {
        $serviceStatus = Get-Service ssh-agent
        if ($serviceStatus.Status -eq "Running") {
            $result = ssh-add $KeyPath 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "SSH key added successfully" -ForegroundColor Green
            } else {
                Write-Warning "Could not add SSH key"
            }
            ssh-add -l
        }
    } else {
        Write-Warning "SSH key not found at: $KeyPath"
    }

    # Configure PowerShell Profile
    Write-Host "Configuring PowerShell Profile..." -ForegroundColor Green

    $profileContent = @'

# SSH Agent Auto-configuration
$sshService = Get-Service ssh-agent -ErrorAction SilentlyContinue
if ($sshService -and $sshService.Status -eq "Running") {
    $loadedKeys = ssh-add -l 2>$null
    if ($LASTEXITCODE -ne 0) {
        ssh-add "$env:USERPROFILE\.ssh\id_ed25519" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SSH key loaded" -ForegroundColor Green
        }
    }
}
'@

    $profilePath = $PROFILE
    $profileDir = Split-Path -Parent $profilePath

    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    if (Test-Path $profilePath) {
        $existingContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
        if ($existingContent -and $existingContent.Contains("SSH Agent Auto-configuration")) {
            if (-not $Force) {
                Write-Host "SSH configuration already exists in PowerShell profile" -ForegroundColor Green
                return
            }
        }
    }

    Add-Content -Path $profilePath -Value $profileContent
    Write-Host "Added SSH auto-loading to PowerShell profile" -ForegroundColor Green

    # Test Configuration
    Write-Host "Testing GitHub SSH connection..." -ForegroundColor Cyan
    $testResult = ssh -T git@github.com 2>&1
    if ($testResult -match "successfully authenticated") {
        Write-Host "GitHub SSH connection successful" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "SSH Agent setup complete!" -ForegroundColor Green

} catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    exit 1
}
