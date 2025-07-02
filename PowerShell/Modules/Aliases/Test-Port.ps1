########## Test-Port function
<#
.SYNOPSIS
Test if a port is open on localhost or remote host.
.DESCRIPTION
Tests network connectivity to a specific port on a host. Useful for checking
if services are running or if ports are accessible.
.PARAMETER Host
The hostname or IP address to test. Defaults to localhost.
.PARAMETER Port
The port number to test.
.EXAMPLE
Test-Port 3000
# Tests if port 3000 is open on localhost.
.EXAMPLE
testport "google.com" 80
# Uses alias to test port 80 on google.com.
#>
function Test-Port {
    [CmdletBinding()]
    param(
        [string]$Host = "localhost",

        [Parameter(Mandatory)]
        [int]$Port
    )

    try {
        Write-Host "🌐 Testing connection to $Host`:$Port..." -ForegroundColor Cyan

        $tcp = New-Object System.Net.Sockets.TcpClient
        $connection = $tcp.BeginConnect($Host, $Port, $null, $null)
        $wait = $connection.AsyncWaitHandle.WaitOne(3000, $false)

        if ($wait) {
            try {
                $tcp.EndConnect($connection)
                $tcp.Close()
                Write-Host "✅ Port $Port is open on $Host" -ForegroundColor Green
                return $true
            }
            catch {
                Write-Host "❌ Port $Port is closed on $Host" -ForegroundColor Red
                return $false
            }
        } else {
            $tcp.Close()
            Write-Host "⏰ Connection to $Host`:$Port timed out" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "❌ Error testing port $Port on $Host`: $_" -ForegroundColor Red
        return $false
    }
}
