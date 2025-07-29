########## Get-FileSize function
<#
.SYNOPSIS
Show file sizes in human readable format.
.DESCRIPTION
Displays files and directories with their sizes in a human-readable format (B, KB, MB, GB).
Shows folders with a folder icon and includes last modified timestamps.
.PARAMETER Path
The directory path to analyze. Defaults to current directory.
.EXAMPLE
Get-FileSize
# Shows sizes of all items in current directory.
.EXAMPLE
sizes "C:\Projects"
# Uses alias to show sizes in Projects directory.
#>
function Get-FileSize {
    [CmdletBinding()]
    param(
        [string]$Path = "."
    )

    try {
        Write-Host "📊 Analyzing file sizes in: $Path" -ForegroundColor Cyan

        $items = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue

        if (-not $items) {
            Write-Warning "No items found in $Path"
            return
        }

        $results = foreach ($item in $items) {
            $size = if ($item.PSIsContainer) {
                "📁 Folder"
            } else {
                switch ($item.Length) {
                    {$_ -gt 1GB} { "{0:N2} GB" -f ($_ / 1GB); break }
                    {$_ -gt 1MB} { "{0:N2} MB" -f ($_ / 1MB); break }
                    {$_ -gt 1KB} { "{0:N2} KB" -f ($_ / 1KB); break }
                    default { "{0} B" -f $_ }
                }
            }

            [PSCustomObject]@{
                Name = $item.Name
                Size = $size
                Modified = $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
                Type = if ($item.PSIsContainer) { "Folder" } else { $item.Extension }
            }
        }

        $results | Sort-Object @{Expression={$_.Type -eq "Folder"}; Descending=$true}, Name |
            Format-Table -AutoSize -Wrap

        $fileCount = ($results | Where-Object Type -ne "Folder").Count
        $folderCount = ($results | Where-Object Type -eq "Folder").Count
        Write-Host "📈 Total: $fileCount files, $folderCount folders" -ForegroundColor Green
    }
    catch {
        Write-Error "Error analyzing file sizes: $_"
    }
}
