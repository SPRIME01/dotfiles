########## Show-Json function
<#
.SYNOPSIS
Pretty print JSON files with syntax highlighting.
.DESCRIPTION
Reads and displays JSON files with proper formatting and indentation.
Useful for quickly viewing configuration files and API responses.
.PARAMETER Path
The path to the JSON file to display.
.EXAMPLE
Show-Json "package.json"
# Displays the package.json file with pretty formatting.
.EXAMPLE
json "config.json"
# Uses the alias to show a configuration file.
#>
function Show-Json {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        if (-not (Test-Path $Path)) {
            Write-Warning "File not found: $Path"
            return
        }

        Write-Host "📄 Contents of $Path" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Gray

        $content = Get-Content $Path -Raw
        $jsonObject = $content | ConvertFrom-Json
        $prettyJson = $jsonObject | ConvertTo-Json -Depth 10

        Write-Host $prettyJson -ForegroundColor White
        Write-Host "----------------------------------------" -ForegroundColor Gray
    }
    catch {
        Write-Error "Error reading JSON file: $_"
        Write-Host "Raw file contents:" -ForegroundColor Yellow
        try {
            Get-Content $Path | Write-Host -ForegroundColor Gray
        }
        catch {
            Write-Error "Cannot read file contents"
        }
    }
}
