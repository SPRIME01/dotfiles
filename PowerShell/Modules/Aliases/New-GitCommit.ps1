########## New-GitCommit function
<#
.SYNOPSIS
Quick commit with message prompt.
.DESCRIPTION
Adds all changes and creates a commit with the specified message. If no message
is provided, prompts the user for one. Simplifies the git add + commit workflow.
.PARAMETER Message
The commit message. If not provided, user will be prompted.
.EXAMPLE
New-GitCommit "Fix navigation bug"
# Adds all files and commits with the specified message.
.EXAMPLE
gc
# Uses the alias and prompts for commit message.
#>
function New-GitCommit {
    [CmdletBinding()]
    param(
        [string]$Message
    )

    if (-not (Test-Path .git)) {
        Write-Warning "Not in a git repository"
        return
    }

    try {
        if (-not $Message) {
            $Message = Read-Host "Commit message"
        }

        if ([string]::IsNullOrWhiteSpace($Message)) {
            Write-Warning "Commit message cannot be empty"
            return
        }

        Write-Host "📝 Adding all changes and committing..." -ForegroundColor Cyan
        git add .
        git commit -m $Message
        Write-Host "✅ Committed: $Message" -ForegroundColor Green
    }
    catch {
        Write-Error "Error creating commit: $_"
    }
}
