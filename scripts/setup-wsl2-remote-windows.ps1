# Windows WSL2 Remote Access Configuration Script
# Run this as Administrator on Windows to enable remote access to WSL2

param(
    [string]$WSLUsername = $env:USERNAME,
    [int]$SSHPort = 2222,
    [switch]$Force
)

Write-Host "🪟 Configuring Windows for WSL2 Remote Access..." -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Error "This script must be run as Administrator"
    Write-Host "💡 Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

try {
    # Step 1: Get WSL2 IP Address
    Write-Host "📋 Step 1: Getting WSL2 IP Address..." -ForegroundColor Green
    
    $wslIP = (wsl hostname -I 2>$null)
    if (-not $wslIP) {
        Write-Error "Could not get WSL2 IP address. Make sure WSL2 is running."
        exit 1
    }
    
    $wslIP = $wslIP.Trim()
    Write-Host "✅ WSL2 IP Address: $wslIP" -ForegroundColor Green

    # Step 2: Configure Windows Firewall
    Write-Host "📋 Step 2: Configuring Windows Firewall..." -ForegroundColor Green
    
    $ruleName = "WSL2 SSH Access"
    $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    
    if ($existingRule) {
        if ($Force) {
            Remove-NetFirewallRule -DisplayName $ruleName
            Write-Host "⚠️  Removed existing firewall rule" -ForegroundColor Yellow
        } else {
            Write-Host "✅ Firewall rule already exists" -ForegroundColor Green
            Write-Host "💡 Use -Force to recreate the rule" -ForegroundColor Yellow
        }
    }
    
    if (-not $existingRule -or $Force) {
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $SSHPort -Action Allow | Out-Null
        Write-Host "✅ Created firewall rule for port $SSHPort" -ForegroundColor Green
    }

    # Step 3: Configure Port Forwarding
    Write-Host "📋 Step 3: Configuring Port Forwarding..." -ForegroundColor Green
    
    # Remove existing port proxy rules for this port
    $existingProxy = netsh interface portproxy show v4tov4 | Select-String -Pattern "0.0.0.0.*$SSHPort"
    
    if ($existingProxy) {
        if ($Force) {
            netsh interface portproxy delete v4tov4 listenport=$SSHPort listenaddress=0.0.0.0 | Out-Null
            Write-Host "⚠️  Removed existing port proxy rule" -ForegroundColor Yellow
        } else {
            Write-Host "✅ Port proxy rule already exists" -ForegroundColor Green
            Write-Host "💡 Use -Force to recreate the rule" -ForegroundColor Yellow
        }
    }
    
    if (-not $existingProxy -or $Force) {
        netsh interface portproxy add v4tov4 listenport=$SSHPort listenaddress=0.0.0.0 connectport=$SSHPort connectaddress=$wslIP | Out-Null
        Write-Host "✅ Created port proxy rule: 0.0.0.0:$SSHPort -> $wslIP:$SSHPort" -ForegroundColor Green
    }

    # Step 4: Verify Configuration
    Write-Host "📋 Step 4: Verifying Configuration..." -ForegroundColor Green
    
    # Check firewall rule
    $firewallRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    if ($firewallRule -and $firewallRule.Enabled -eq "True") {
        Write-Host "✅ Firewall rule is active" -ForegroundColor Green
    } else {
        Write-Warning "Firewall rule may not be active"
    }
    
    # Check port proxy
    $portProxy = netsh interface portproxy show v4tov4 | Select-String -Pattern "$SSHPort"
    if ($portProxy) {
        Write-Host "✅ Port proxy is configured" -ForegroundColor Green
        Write-Host "📡 Port forwarding rules:" -ForegroundColor Cyan
        netsh interface portproxy show v4tov4 | Where-Object { $_ -match "$SSHPort" }
    } else {
        Write-Warning "Port proxy may not be configured correctly"
    }

    # Step 5: Get Network Information
    Write-Host "📋 Step 5: Network Information..." -ForegroundColor Green
    
    $windowsIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback" -and $_.InterfaceAlias -notmatch "WSL" } | Select-Object -First 1).IPAddress
    
    Write-Host "🌐 Network Configuration:" -ForegroundColor Cyan
    Write-Host "   Windows IP: $windowsIP" -ForegroundColor White
    Write-Host "   WSL2 IP: $wslIP" -ForegroundColor White
    Write-Host "   SSH Port: $SSHPort" -ForegroundColor White

    # Step 6: Generate Client Configuration
    Write-Host "📋 Step 6: Client SSH Configuration..." -ForegroundColor Green
    
    $computerName = $env:COMPUTERNAME.ToLower()
    
    Write-Host ""
    Write-Host "📝 Add this to your client's ~/.ssh/config:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Host wsl-$computerName" -ForegroundColor White
    Write-Host "    HostName $windowsIP" -ForegroundColor White
    Write-Host "    Port $SSHPort" -ForegroundColor White
    Write-Host "    User $WSLUsername" -ForegroundColor White
    Write-Host "    IdentityFile ~/.ssh/id_ed25519" -ForegroundColor White
    Write-Host "    StrictHostKeyChecking no" -ForegroundColor White
    Write-Host "    ServerAliveInterval 60" -ForegroundColor White
    Write-Host ""

    # Step 7: Test Connectivity
    Write-Host "📋 Step 7: Testing Connectivity..." -ForegroundColor Green
    
    # Test if WSL SSH is responding
    $testResult = Test-NetConnection -ComputerName $wslIP -Port $SSHPort -WarningAction SilentlyContinue
    
    if ($testResult.TcpTestSucceeded) {
        Write-Host "✅ WSL2 SSH server is reachable" -ForegroundColor Green
    } else {
        Write-Warning "Cannot reach WSL2 SSH server. Make sure SSH is running in WSL2."
    }

    # Step 8: Generate Maintenance Commands
    Write-Host "📋 Step 8: Maintenance Commands..." -ForegroundColor Green
    
    Write-Host ""
    Write-Host "🔧 Useful maintenance commands:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "# View all port proxy rules:" -ForegroundColor Gray
    Write-Host "netsh interface portproxy show v4tov4" -ForegroundColor White
    Write-Host ""
    Write-Host "# Remove port proxy rule:" -ForegroundColor Gray
    Write-Host "netsh interface portproxy delete v4tov4 listenport=$SSHPort listenaddress=0.0.0.0" -ForegroundColor White
    Write-Host ""
    Write-Host "# View firewall rules:" -ForegroundColor Gray
    Write-Host "Get-NetFirewallRule -DisplayName '*WSL*'" -ForegroundColor White
    Write-Host ""
    Write-Host "# Update WSL2 IP (if it changes):" -ForegroundColor Gray
    Write-Host ".\setup-wsl2-remote-windows.ps1 -Force" -ForegroundColor White
    Write-Host ""

    Write-Host "🎉 Windows WSL2 Remote Access Configuration Complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Make sure SSH server is running in WSL2" -ForegroundColor White
    Write-Host "2. Add your public key to WSL2 ~/.ssh/authorized_keys" -ForegroundColor White
    Write-Host "3. Configure SSH client with the configuration above" -ForegroundColor White
    Write-Host "4. Test connection: ssh wsl-$computerName" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 For VS Code, install Remote-SSH extension and connect to 'wsl-$computerName'" -ForegroundColor Cyan

} catch {
    Write-Error "Configuration failed: $($_.Exception.Message)"
    exit 1
}
