########## Get-NetworkConnections function
<#
.SYNOPSIS
Show active network connections.
.DESCRIPTION
Displays currently established network connections showing local and remote
addresses and ports. Useful for monitoring network activity and debugging.
.EXAMPLE
Get-NetworkConnections
# Shows all active network connections.
.EXAMPLE
netstat
# Uses the alias to show network connections.
#>
function Get-NetworkConnections {
    [CmdletBinding()]
    param()

    try {
        Write-Host "🌐 Active Network Connections" -ForegroundColor Cyan

        $connections = Get-NetTCPConnection |
            Where-Object State -eq "Established" |
            Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, @{
                Name = "Process"
                Expression = {
                    try {
                        $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
                        if ($process) { $process.ProcessName } else { "Unknown" }
                    }
                    catch { "Unknown" }
                }
            } |
            Sort-Object LocalPort

        if ($connections) {
            $connections | Format-Table -AutoSize
            Write-Host "📊 Total: $($connections.Count) active connections" -ForegroundColor Green
        } else {
            Write-Warning "No established connections found"
        }
    }
    catch {
        Write-Error "Error getting network connections: $_"
    }
}
