# Windows SSH Agent Setup Script
# This script configures Windows SSH Agent to start automatically and load your SSH keys

param(
    [string]$KeyPath = "$env:USERPROFILE\.ssh\id_ed25519",
    [switch]$Force
)

Write-Host "🔐 Configuring Windows SSH Agent..." -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Warning "Some operations require Administrator privileges"
    Write-Host "💡 For full setup, run PowerShell as Administrator" -ForegroundColor Yellow
}

try {
    # Step 1: Configure SSH Agent Service
    Write-Host "📋 Step 1: Configuring SSH Agent Service..." -ForegroundColor Green
    
    $sshAgentService = Get-Service ssh-agent -ErrorAction SilentlyContinue
    if ($sshAgentService) {
        if ($isAdmin) {
            # Set to automatic startup
            Set-Service ssh-agent -StartupType Automatic
            Write-Host "✅ SSH Agent service set to start automatically" -ForegroundColor Green
            
            # Start the service if not running
            if ($sshAgentService.Status -ne "Running") {
                Start-Service ssh-agent
                Write-Host "✅ SSH Agent service started" -ForegroundColor Green
            } else {
                Write-Host "✅ SSH Agent service already running" -ForegroundColor Green
            }
        } else {
            Write-Warning "Cannot configure service without Administrator privileges"
            Write-Host "💡 Run these commands as Administrator:" -ForegroundColor Yellow
            Write-Host "   Set-Service ssh-agent -StartupType Automatic" -ForegroundColor White
            Write-Host "   Start-Service ssh-agent" -ForegroundColor White
        }
    } else {
        Write-Error "SSH Agent service not found. Install OpenSSH client feature."
        exit 1
    }

    # Step 2: Add SSH Key
    Write-Host "📋 Step 2: Adding SSH Key..." -ForegroundColor Green
    
    if (Test-Path $KeyPath) {
        # Check if service is running
        $serviceStatus = Get-Service ssh-agent
        if ($serviceStatus.Status -eq "Running") {
            # Add the key
            $addResult = ssh-add "$KeyPath" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ SSH key added successfully" -ForegroundColor Green
            } else {
                Write-Warning "Could not add SSH key: $addResult"
            }
            
            # List loaded keys
            Write-Host "📋 Currently loaded keys:" -ForegroundColor Cyan
            ssh-add -l
        } else {
            Write-Warning "SSH Agent service is not running"
        }
    } else {
        Write-Warning "SSH key not found at: $KeyPath"
        Write-Host "💡 Generate an SSH key first or specify correct path with -KeyPath" -ForegroundColor Yellow
    }

    # Step 3: Configure PowerShell Profile for Auto-loading
    Write-Host "📋 Step 3: Configuring PowerShell Profile..." -ForegroundColor Green
    
    $profileContent = @"

# SSH Agent Auto-configuration
if (Get-Service ssh-agent -ErrorAction SilentlyContinue | Where-Object Status -eq "Running") {
    # Check if key is already loaded
    `$loadedKeys = ssh-add -l 2>`$null
    if (`$LASTEXITCODE -ne 0 -or `$loadedKeys -notmatch "$(Split-Path -Leaf $KeyPath)") {
        # Add SSH key if not already loaded
        ssh-add "$KeyPath" 2>`$null
        if (`$LASTEXITCODE -eq 0) {
            Write-Host "🔑 SSH key loaded" -ForegroundColor Green
        }
    }
}
"@

    # Add to current user's PowerShell profile
    $profilePath = $PROFILE
    $profileDir = Split-Path -Parent $profilePath
    
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    # Check if SSH configuration already exists
    if (Test-Path $profilePath) {
        $existingContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
        if ($existingContent -and $existingContent.Contains("SSH Agent Auto-configuration")) {
            if ($Force) {
                Write-Host "⚠️  Updating existing SSH configuration in profile" -ForegroundColor Yellow
            } else {
                Write-Host "✅ SSH configuration already exists in PowerShell profile" -ForegroundColor Green
                Write-Host "💡 Use -Force to update existing configuration" -ForegroundColor Yellow
                return
            }
        }
    }
    
    # Append SSH configuration to profile
    Add-Content -Path $profilePath -Value $profileContent
    Write-Host "✅ Added SSH auto-loading to PowerShell profile" -ForegroundColor Green
    Write-Host "📍 Profile location: $profilePath" -ForegroundColor Cyan

    # Step 4: Test Configuration
    Write-Host "📋 Step 4: Testing Configuration..." -ForegroundColor Green
    
    # Test SSH connection to GitHub
    Write-Host "🧪 Testing GitHub SSH connection..." -ForegroundColor Cyan
    $testResult = ssh -T git@github.com 2>&1
    if ($testResult -match "successfully authenticated") {
        Write-Host "✅ GitHub SSH connection successful" -ForegroundColor Green
    } else {
        Write-Warning "GitHub SSH test failed: $testResult"
    }

    Write-Host ""
    Write-Host "🎉 SSH Agent setup complete!" -ForegroundColor Green
    Write-Host "💡 Open a new PowerShell window to test automatic key loading" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 Summary:" -ForegroundColor Yellow
    if ($isAdmin) {
        Write-Host "  ✅ SSH Agent service configured for automatic startup" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  SSH Agent service needs manual configuration (requires admin)" -ForegroundColor Yellow
    }
    Write-Host "  ✅ SSH key loading added to PowerShell profile" -ForegroundColor Green
    Write-Host "  ✅ Configuration tested" -ForegroundColor Green

} catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    exit 1
}
