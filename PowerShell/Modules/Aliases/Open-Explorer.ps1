########## Open-Explorer function
<#
.SYNOPSIS
Open current directory in Windows Explorer.
.DESCRIPTION
Opens the current PowerShell working directory in Windows File Explorer.
Useful for quick file management and navigation.
.EXAMPLE
Open-Explorer
# Opens current directory in Explorer.
.EXAMPLE
explore
# Uses the alias to open Explorer.
#>
function Open-Explorer {
    [CmdletBinding()]
    param()

    try {
        $currentPath = (Get-Location).Path
        Write-Host "📂 Opening Explorer at: $currentPath" -ForegroundColor Cyan
        Start-Process explorer.exe -ArgumentList $currentPath
    }
    catch {
        Write-Error "Error opening Explorer: $_"
    }
}
