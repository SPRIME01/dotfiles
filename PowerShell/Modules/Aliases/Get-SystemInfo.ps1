########## Get-SystemInfo function
<#
.SYNOPSIS
Show system resources and running processes.
.DESCRIPTION
Displays current system resource usage including CPU, memory, and uptime.
Provides a quick overview of system health and performance.
.EXAMPLE
Get-SystemInfo
# Shows current system resource usage.
.EXAMPLE
sysinfo
# Uses the alias for quick system check.
#>
function Get-SystemInfo {
    [CmdletBinding()]
    param()

    try {
        Write-Host "💻 System Status" -ForegroundColor Cyan

        # CPU Usage
        try {
            $cpu = Get-Counter "\Processor(_Total)\% Processor Time" -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty CounterSamples |
                Select-Object -ExpandProperty CookedValue
            $cpuColor = if($cpu -gt 80) {"Red"} elseif($cpu -gt 60) {"Yellow"} else {"Green"}
            Write-Host "🔥 CPU Usage: $([math]::Round($cpu, 1))%" -ForegroundColor $cpuColor
        }
        catch {
            Write-Host "🔥 CPU Usage: Unable to determine" -ForegroundColor Yellow
        }

        # Memory Usage
        try {
            $memory = Get-Counter "\Memory\Available MBytes" -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty CounterSamples |
                Select-Object -ExpandProperty CookedValue
            $totalMemory = (Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue |
                Measure-Object -Property Capacity -Sum).Sum / 1MB
            $usedMemory = $totalMemory - $memory
            $memoryPercent = ($usedMemory / $totalMemory) * 100
            $memColor = if($memoryPercent -gt 85) {"Red"} elseif($memoryPercent -gt 70) {"Yellow"} else {"Green"}
            Write-Host "🧠 Memory: $([math]::Round($usedMemory, 0)) MB used / $([math]::Round($totalMemory, 0)) MB total ($([math]::Round($memoryPercent, 1))%)" -ForegroundColor $memColor
        }
        catch {
            Write-Host "🧠 Memory: Unable to determine" -ForegroundColor Yellow
        }

        # Uptime
        try {
            $uptime = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).LastBootUpTime
            if ($uptime) {
                $uptimeDuration = (Get-Date) - $uptime
                Write-Host "⏰ Uptime: $($uptimeDuration.Days)d $($uptimeDuration.Hours)h $($uptimeDuration.Minutes)m" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "⏰ Uptime: Unable to determine" -ForegroundColor Yellow
        }

        # Disk Usage (C: drive)
        try {
            $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
            if ($disk) {
                $freeGB = [math]::Round($disk.FreeSpace / 1GB, 1)
                $totalGB = [math]::Round($disk.Size / 1GB, 1)
                $usedPercent = (($totalGB - $freeGB) / $totalGB) * 100
                $diskColor = if($usedPercent -gt 90) {"Red"} elseif($usedPercent -gt 80) {"Yellow"} else {"Green"}
                Write-Host "💾 Disk (C:): $freeGB GB free / $totalGB GB total ($([math]::Round($usedPercent, 1))% used)" -ForegroundColor $diskColor
            }
        }
        catch {
            Write-Host "💾 Disk: Unable to determine" -ForegroundColor Yellow
        }

        Write-Host ""
    }
    catch {
        Write-Error "Error getting system information: $_"
    }
}
