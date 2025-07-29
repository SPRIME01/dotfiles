########## Find-Text function
<#
.SYNOPSIS
Search for text in files with colored output.
.DESCRIPTION
Searches for text patterns in files within the specified directory and its subdirectories.
Provides colored output showing filename, line number, and matching content.
.PARAMETER Pattern
The text pattern to search for.
.PARAMETER Path
The directory path to search in. Defaults to current directory.
.PARAMETER Include
File extensions to include in search. Defaults to common development files.
.EXAMPLE
Find-Text "TODO"
# Finds all TODO comments in development files.
.EXAMPLE
grep "function.*export" -Path "src"
# Uses alias to search for export functions in src directory.
#>
function Find-Text {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Pattern,

        [string]$Path = ".",

        [string[]]$Include = @("*.ps1", "*.js", "*.ts", "*.jsx", "*.tsx", "*.json", "*.md", "*.txt", "*.yml", "*.yaml", "*.xml", "*.html", "*.css", "*.scss")
    )

    try {
        Write-Host "🔍 Searching for '$Pattern' in $Path..." -ForegroundColor Cyan

        $results = Get-ChildItem -Path $Path -Recurse -Include $Include -ErrorAction SilentlyContinue |
            Select-String -Pattern $Pattern -ErrorAction SilentlyContinue

        if (-not $results) {
            Write-Warning "No matches found for '$Pattern'"
            return
        }

        $groupedResults = $results | Group-Object Filename

        foreach ($group in $groupedResults) {
            Write-Host "`n📄 $($group.Name)" -ForegroundColor Yellow
            foreach ($match in $group.Group) {
                Write-Host "   Line $($match.LineNumber): " -ForegroundColor Gray -NoNewline
                Write-Host $match.Line.Trim() -ForegroundColor White
            }
        }

        Write-Host "`n✅ Found $($results.Count) matches in $($groupedResults.Count) files" -ForegroundColor Green
    }
    catch {
        Write-Error "Error searching for text: $_"
    }
}
