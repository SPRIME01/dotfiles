#!/usr/bin/env pwsh
# dotfiles/setup-themes.ps1
# Cross-platform theme setup for both Oh My Posh and Zsh Powerlevel10k
# Version: 1.0
# Last Modified: July 20, 2025

param(
    [switch]$InstallFonts,
    [switch]$ConfigureZsh,
    [switch]$ConfigurePowerShell,
    [switch]$All
)

if ($All) {
    $InstallFonts = $true
    $ConfigureZsh = $true
    $ConfigurePowerShell = $true
}

Write-Host "🎨 Setting up unified theme experience..." -ForegroundColor Cyan

# Install recommended fonts
if ($InstallFonts) {
    Write-Host "🔤 Installing recommended fonts..." -ForegroundColor Yellow

    if ($IsWindows) {
        # Windows font installation
        $fontsPath = "$env:TEMP\dotfiles-fonts"
        New-Item -ItemType Directory -Path $fontsPath -Force | Out-Null

        $fonts = @(
            @{ Name = "MesloLGS NF Regular"; Url = "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf" },
            @{ Name = "MesloLGS NF Bold"; Url = "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf" },
            @{ Name = "MesloLGS NF Italic"; Url = "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf" },
            @{ Name = "MesloLGS NF Bold Italic"; Url = "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf" }
        )

        foreach ($font in $fonts) {
            $fontFile = Join-Path $fontsPath "$($font.Name).ttf"
            Write-Host "  📥 Downloading $($font.Name)..." -ForegroundColor Gray
            try {
                Invoke-WebRequest -Uri $font.Url -OutFile $fontFile -ErrorAction Stop
                # Install font (requires elevated privileges)
                $fontFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)
                $fontFolder.CopyHere($fontFile)
                Write-Host "  ✅ Installed $($font.Name)" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to install $($font.Name): $_"
            }
        }

        Remove-Item -Path $fontsPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-Host "  ℹ️  Run './install_zsh.sh' on Linux/WSL2 for automatic font installation" -ForegroundColor Blue
    }
}

# Configure PowerShell themes
if ($ConfigurePowerShell) {
    Write-Host "💜 Configuring PowerShell themes..." -ForegroundColor Magenta

    # Set default theme to official powerlevel10k classic
    $env:OMP_THEME = "powerlevel10k_classic.omp.json"

    # Save to Windows registry if available
    if ($IsWindows) {
        try {
            Set-ItemProperty -Path "HKCU:\Environment" -Name "OMP_THEME" -Value "powerlevel10k_classic.omp.json"
            Write-Host "  ✅ Set Powerlevel10k Classic as default theme" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not save theme preference to registry"
        }
    }

    Write-Host "  📋 Available PowerShell commands:" -ForegroundColor Yellow
    Write-Host "    settheme powerlevel10k_classic   # Official Powerlevel10k classic" -ForegroundColor Gray
    Write-Host "    settheme powerlevel10k_modern    # Official Powerlevel10k modern" -ForegroundColor Gray
    Write-Host "    settheme powerlevel10k_lean      # Official Powerlevel10k lean" -ForegroundColor Gray
    Write-Host "    settheme minimal-clean           # Clean theme" -ForegroundColor Gray
    Write-Host "    gettheme                         # Show current theme" -ForegroundColor Gray
    Write-Host "    listthemes                       # List all themes" -ForegroundColor Gray
}

# Configure Zsh themes
if ($ConfigureZsh) {
    Write-Host "🐚 Configuring Zsh themes..." -ForegroundColor Green

    Write-Host "  📋 Available Zsh commands:" -ForegroundColor Yellow
    Write-Host "    p10k configure    # Configure Powerlevel10k theme" -ForegroundColor Gray
    Write-Host "    exec zsh          # Restart Zsh with new config" -ForegroundColor Gray

    if (Test-Path "$HOME/.zshrc") {
        Write-Host "  ✅ Zsh configuration found" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠️  Run './install_zsh.sh' to set up Zsh" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎯 Theme Setup Summary:" -ForegroundColor Cyan
Write-Host "  PowerShell: Oh My Posh with Powerlevel10k-inspired theme" -ForegroundColor White
Write-Host "  Zsh:        Oh My Zsh with Powerlevel10k theme" -ForegroundColor White
Write-Host "  Fonts:      MesloLGS NF (Nerd Font)" -ForegroundColor White
Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Set your terminal font to 'MesloLGS NF'" -ForegroundColor Gray
Write-Host "  2. Restart your shell for full effect" -ForegroundColor Gray
Write-Host "  3. Use theme commands to customize appearance" -ForegroundColor Gray
Write-Host ""
Write-Host "🔧 Troubleshooting:" -ForegroundColor Yellow
Write-Host "  • If icons don't display: Install Nerd Fonts and set terminal font" -ForegroundColor Gray
Write-Host "  • If colors are off: Check terminal supports 256 colors" -ForegroundColor Gray
Write-Host "  • For WSL2: Run 'p10k configure' for best experience" -ForegroundColor Gray
