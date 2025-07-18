# PowerShell test script for MCP integration (WSL2-aware)
# This script verifies that MCP integration is working correctly with WSL2 symlinked dotfiles

Write-Host "🧪 Testing MCP Integration (WSL2-aware)..." -ForegroundColor Cyan

# Test 1: Check if MCP environment file exists
Write-Host "📋 Test 1: MCP environment file" -ForegroundColor Yellow
$envFile = "$env:USERPROFILE\dotfiles\mcp\.env"
if (Test-Path $envFile) {
    Write-Host "✅ MCP environment file found at: $envFile" -ForegroundColor Green
} else {
    Write-Host "❌ MCP environment file not found at: $envFile" -ForegroundColor Red
    exit 1
}

# Test 2: Check if shell common file has MCP integration
Write-Host "📋 Test 2: Shell integration" -ForegroundColor Yellow
$shellCommonFile = "$env:USERPROFILE\dotfiles\.shell_common.sh"
if (Test-Path $shellCommonFile) {
    $content = Get-Content $shellCommonFile -Raw
    if ($content -match "MCP_ENV_PATH") {
        Write-Host "✅ Shell integration configured in .shell_common.sh" -ForegroundColor Green
    } else {
        Write-Host "❌ Shell integration not configured" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ Shell common file not found" -ForegroundColor Red
    exit 1
}

# Test 3: Load and verify environment variables
Write-Host "📋 Test 3: Environment variables" -ForegroundColor Yellow
$envVars = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $name = $matches[1]
        $value = $matches[2]
        # Remove quotes if present
        $value = $value -replace '^"(.*)"$', '$1'
        $value = $value -replace "^'(.*)'$", '$1'
        # Convert paths for Windows compatibility
        $value = $value -replace '/home/sprime01/', "$env:USERPROFILE\"
        $value = $value -replace '\$HOME', $env:USERPROFILE
        $envVars[$name] = $value
    }
}

$requiredVars = @("MCP_GATEWAY_URL", "MCP_ADMIN_USERNAME", "MCP_BRIDGE_SCRIPT_PATH")
$allVarsPresent = $true

foreach ($var in $requiredVars) {
    if ($envVars.ContainsKey($var) -and $envVars[$var]) {
        if ($var -like "*PASSWORD*") {
            Write-Host "✅ ${var}: [REDACTED]" -ForegroundColor Green
        } else {
            Write-Host "✅ ${var}: $($envVars[$var])" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ $var not set" -ForegroundColor Red
        $allVarsPresent = $false
    }
}

if (!$allVarsPresent) {
    exit 1
}

# Test 4: Check if bridge script path is accessible
Write-Host "📋 Test 4: Bridge script accessibility" -ForegroundColor Yellow
$bridgeScript = $envVars["MCP_BRIDGE_SCRIPT_PATH"]
if ($bridgeScript) {
    # For WSL2 paths, check if the WSL file exists
    if ($bridgeScript -match "^/home/") {
        # This is a WSL path - we can't directly test from PowerShell
        Write-Host "⚠️  Bridge script is in WSL2: $bridgeScript" -ForegroundColor Yellow
        Write-Host "💡 This is expected for WSL2 setup - cannot verify from PowerShell" -ForegroundColor Cyan
    } elseif (Test-Path $bridgeScript) {
        Write-Host "✅ Bridge script found at: $bridgeScript" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Bridge script not found at: $bridgeScript" -ForegroundColor Yellow
        Write-Host "💡 This is expected if MCPContextForge is not set up yet" -ForegroundColor Cyan
    }
}

# Test 5: Check helper scripts
Write-Host "📋 Test 5: Helper scripts" -ForegroundColor Yellow
$bashHelper = "$env:USERPROFILE\dotfiles\mcp\mcp-helper.sh"
$psHelper = "$env:USERPROFILE\dotfiles\mcp\mcp-helper.ps1"

if (Test-Path $bashHelper) {
    Write-Host "✅ Bash helper script found" -ForegroundColor Green
} else {
    Write-Host "❌ Bash helper script not found" -ForegroundColor Red
}

if (Test-Path $psHelper) {
    Write-Host "✅ PowerShell helper script found" -ForegroundColor Green
} else {
    Write-Host "❌ PowerShell helper script not found" -ForegroundColor Red
}

# Test 6: Test PowerShell helper functionality
Write-Host "📋 Test 6: PowerShell helper functionality" -ForegroundColor Yellow
try {
    & $psHelper "env"
    Write-Host "✅ PowerShell helper script executed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ PowerShell helper script failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "🎉 MCP integration test complete!" -ForegroundColor Green
Write-Host "💡 Next steps:" -ForegroundColor Cyan
Write-Host "   - In WSL2: source ~/.bashrc or ~/.zshrc to activate MCP environment" -ForegroundColor Cyan
Write-Host "   - Run migration script: .\migrate-vscode-settings.ps1" -ForegroundColor Cyan
