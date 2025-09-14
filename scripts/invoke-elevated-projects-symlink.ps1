param(
    [string]$Path = $null,
    [Parameter(Mandatory=$true)][string]$Target
)

try {
    if (-not $Path -or [string]::IsNullOrWhiteSpace($Path)) {
        $Path = Join-Path $env:USERPROFILE 'projects'
    }

    # Build the elevated command to remove any existing item and create a symlink
    $escaped = @(
        "\$p = `"$Path`";",
        "\$t = `"$Target`";",
        "if (Test-Path \$p) { Remove-Item -Recurse -Force \$p };",
        "New-Item -ItemType SymbolicLink -Path \$p -Target \$t -Force;",
        "Write-Host '✅ Created projects symlink' -ForegroundColor Green"
    ) -join ' '

    Start-Process -FilePath 'PowerShell' -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$escaped`"" | Out-Null
    Write-Host "🔼 Elevation requested. Approve the UAC prompt to create the projects symlink." -ForegroundColor Yellow
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

