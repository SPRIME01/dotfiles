########## Stop-ProcessByPort function
<#
.SYNOPSIS
Kill processes by port number.
.DESCRIPTION
Finds and terminates processes that are listening on the specified port.
Useful for stopping development servers or freeing up ports.
.PARAMETER Port
The port number to check and kill processes on.
.EXAMPLE
Stop-ProcessByPort 3000
# Kills any process running on port 3000.
.EXAMPLE
killport 8080
# Uses the alias to kill process on port 8080.
#>
function Stop-ProcessByPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Port
    )

    try {
        $connections = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue

        if (-not $connections) {
            Write-Warning "No process found listening on port $Port"
            return
        }

        $processIds = $connections | Select-Object -ExpandProperty OwningProcess -Unique

        foreach ($processId in $processIds) {
            try {
                $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                if ($process) {
                    Write-Host "🔫 Killing process: $($process.ProcessName) (PID: $processId) on port $Port" -ForegroundColor Yellow
                    Stop-Process -Id $processId -Force
                    Write-Host "✅ Process killed successfully" -ForegroundColor Green
                } else {
                    Write-Warning "Process $processId not found"
                }
            }
            catch {
                Write-Error "Error killing process $processId`: $_"
            }
        }
    }
    catch {
        Write-Error "Error finding processes on port $Port`: $_"
    }
}
