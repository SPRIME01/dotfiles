########## Find-Directory function
<#
.SYNOPSIS
Quickly find and navigate to directories by partial name.
.DESCRIPTION
Searches for directories by partial name match within the current directory and up to 2 levels deep.
Useful for quickly locating project folders or subdirectories without remembering the full path.
.PARAMETER Pattern
The partial name pattern to search for in directory names.
.EXAMPLE
Find-Directory "proj"
# Finds all directories with "proj" in their name.
.EXAMPLE
finddir "web"
# Uses the alias to find directories containing "web".
#>
function Find-Directory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Pattern
    )

    try {
        $directories = Get-ChildItem -Directory -Recurse -Depth 2 -ErrorAction SilentlyContinue |
            Where-Object Name -like "*$Pattern*" |
            Select-Object FullName, Name

        if ($directories) {
            Write-Host "📁 Found directories matching '$Pattern':" -ForegroundColor Cyan
            $directories | ForEach-Object {
                Write-Host "  $($_.FullName)" -ForegroundColor Green
            }
        } else {
            Write-Warning "No directories found matching '$Pattern'"
        }
    }
    catch {
        Write-Error "Error searching for directories: $_"
    }
}
