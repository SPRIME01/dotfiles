param(
    [Parameter(Mandatory=$true)][string]$Target
)

try {
    $escapedCmd = "New-Item -ItemType SymbolicLink -Path ``'$PROFILE``' -Target ``'$Target``' -Force; Write-Host '✅ Created symbolic link' -ForegroundColor Green"
    Start-Process -FilePath 'PowerShell' -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$escapedCmd`"" | Out-Null
    Write-Host "🔼 Elevation requested. Approve the UAC prompt to create the symlink." -ForegroundColor Yellow
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

