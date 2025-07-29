########## Get-FileTree function
<#
.SYNOPSIS
Displays a tree view of a directory structure.
.DESCRIPTION
Generates a visual tree representation of files and folders within a specified path,
optionally limiting the depth and including files. Excludes .venv and .git directories.
.PARAMETER Path
The root directory path for the tree view. Defaults to the current directory.
.PARAMETER Depth
Specifies the maximum depth of the directory structure to display.
.PARAMETER ShowFiles
Include files in the tree view. By default, only directories are shown unless Depth is specified.
.EXAMPLE
Get-FileTree -Path C:\Projects -Depth 2
# Shows directories up to 2 levels deep under C:\Projects.
.EXAMPLE
filetree -ShowFiles
# Shows files and directories in the current location using the alias.
#>
function Get-FileTree {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Path = '.',
        [int]$Depth,
        [switch]$ShowFiles
    )

    try {
        # Normalize the path
        $resolvedPath = (Resolve-Path $Path).Path
        Write-Verbose "Starting tree view for path: $resolvedPath"

        # Base parameters for Get-ChildItem
        $gciParams = @{
            Path        = $resolvedPath
            Recurse     = $true
            ErrorAction = 'Stop' # Stop on errors like access denied
        }

        # Determine if files should be included based on parameters
        $includeFiles = $ShowFiles.IsPresent -or $PSBoundParameters.ContainsKey('Depth')

        # Get items, applying depth filter if specified
        $allItems = Get-ChildItem @gciParams
        if ($PSBoundParameters.ContainsKey('Depth')) {
            $baseDepth = $resolvedPath.Split([IO.Path]::DirectorySeparatorChar).Count
            $items = $allItems | Where-Object {
                ($_.FullName.Split([IO.Path]::DirectorySeparatorChar).Count - $baseDepth) -le $Depth
            }
            Write-Verbose "Filtering items to depth: $Depth"
        }
        else {
            $items = $allItems
        }

        # Filter out .venv and .git directories and their contents
        $items = $items | Where-Object {
            $_.FullName -notmatch '(\\|/)(\.venv|\.git)(\\|$|\/)'
        }

        # Filter out files if not requested
        if (-not $includeFiles) {
            $items = $items | Where-Object { $_.PSIsContainer }
            Write-Verbose "Filtering out files."
        }

        # Build tree structure (hashtable: key=parent path, value=array of child items)
        $tree = @{}
        foreach ($item in $items) {
            $parent = [System.IO.Path]::GetDirectoryName($item.FullName)
            # Ensure parent exists in the tree keys, otherwise it's outside the scope or root
            if ($parent -eq $resolvedPath -or $items.FullName -contains $parent) {
                if (-not $tree.ContainsKey($parent)) {
                    $tree[$parent] = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                }
                $tree[$parent].Add($item)
            }
        }

        # Helper function to recursively write tree levels
        function Write-TreeLevel {
            param($dir, $prefix = '')

            if (-not $tree.ContainsKey($dir)) { return }

            # Sort items: directories first, then files, alphabetically
            $sortedItems = $tree[$dir] | Sort-Object -Property @{ Expression = { $_.PSIsContainer }; Descending = $true }, Name

            for ($i = 0; $i -lt $sortedItems.Count; $i++) {
                $item = $sortedItems[$i]
                $isLast = ($i -eq $sortedItems.Count - 1)
                $connector = if ($isLast) { "└── " } else { "├── " }
                $icon = if ($item.PSIsContainer) { "📁" } else { "📄" }

                Write-Output "$prefix$connector$icon $($item.Name)"

                # Recurse into directories
                if ($item.PSIsContainer) {
                    $newPrefix = $prefix + $(if ($isLast) { "    " } else { "│   " })
                    Write-TreeLevel -dir $item.FullName -prefix $newPrefix
                }
            }
        }

        # Start printing from the root directory specified
        Write-Output "📁 $($resolvedPath)" # Print root directory name
        Write-TreeLevel -dir $resolvedPath -prefix ""

    }
    catch {
        Write-Error "Error generating file tree for '$Path': $_"
    }
}

# Alias for Get-FileTree
# Set-Alias -Name filetree -Value Get-FileTree -Description "Alias for Get-FileTree" -Scope Global -Force
