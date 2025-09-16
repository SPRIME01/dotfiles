# PowerShell common environment variables
# Part of the modular dotfiles configuration system

# Editor settings
if (-not $env:EDITOR) { $env:EDITOR = "code" }
if (-not $env:VISUAL) { $env:VISUAL = $env:EDITOR }

# Development environment variables
if (-not $env:NODE_ENV) { $env:NODE_ENV = "development" }

# PowerShell-specific settings
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# Path additions (platform-specific paths will be added by platform modules)
$LocalBinPaths = @(
    (Join-Path $env:USERPROFILE ".local\bin"),
    (Join-Path $env:USERPROFILE "bin"),
    (Join-Path $env:USERPROFILE ".cargo\bin"),
    (Join-Path $env:USERPROFILE "go\bin"),
    (Join-Path $env:USERPROFILE ".poetry\bin"),
    (Join-Path $env:USERPROFILE ".npm-global")
)

foreach ($BinPath in $LocalBinPaths) {
    if (Test-Path $BinPath) {
        $env:PATH = "$BinPath;$env:PATH"
    }
}

# Volta (Node.js toolchain manager)
$voltaHome = if ($env:VOLTA_HOME) { $env:VOLTA_HOME } else { Join-Path $env:USERPROFILE '.volta' }
$voltaBin = Join-Path $voltaHome 'bin'
if (Test-Path $voltaBin) {
    $env:VOLTA_HOME = $voltaHome
    if (!(($env:PATH -split ';') -contains $voltaBin)) {
        $env:PATH = "$voltaBin;$env:PATH"
    }
}

# Go development
if (Test-Path (Join-Path $env:USERPROFILE "go")) {
    $env:GOPATH = Join-Path $env:USERPROFILE "go"
}

# Color settings
$env:CLICOLOR = "1"
