Param(
    [string]$DotfilesRoot
)

try {
    if (-not $DotfilesRoot) {
        Write-Error "DotfilesRoot parameter must be provided"
        exit 1
    }
    $loaderPath = Join-Path $DotfilesRoot 'PowerShell/Utils/Load-Env.ps1'
    if (-not (Test-Path $loaderPath)) {
        Write-Error "Environment loader not found at $loaderPath"
        exit 1
    }
    . $loaderPath
    # Create a temporary environment file
    $tempFile = [System.IO.Path]::GetTempFileName()
    @(
        'FOO=bar'
        'BAR="baz"'
    ) | Set-Content -Path $tempFile
    Load-EnvFile -FilePath $tempFile
    if ($env:FOO -ne 'bar' -or $env:BAR -ne 'baz') {
        Write-Error "Load-EnvFile did not set expected environment variables"
        exit 1
    }
    Write-Host "✅ Load-EnvFile successfully parsed sample .env file"
    Remove-Item $tempFile -ErrorAction SilentlyContinue
} catch {
    Write-Error $_
    exit 1
}