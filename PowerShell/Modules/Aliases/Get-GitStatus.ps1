########## Get-GitStatus function
<#
.SYNOPSIS
Quick git status with branch info and clean output.
.DESCRIPTION
Displays git status information in a clean, readable format including current branch
and file changes. Only works if the current directory is a git repository.
.EXAMPLE
Get-GitStatus
# Shows git status for current repository.
.EXAMPLE
gs
# Uses the alias for quick git status check.
#>
function Get-GitStatus {
    [CmdletBinding()]
    param()

    if (Test-Path .git) {
        try {
            $repoName = Split-Path -Leaf (Get-Location)
            Write-Host "📁 $repoName" -ForegroundColor Cyan
            git status --short --branch
        }
        catch {
            Write-Error "Error getting git status: $_"
        }
    } else {
        Write-Warning "Not in a git repository"
    }
}
