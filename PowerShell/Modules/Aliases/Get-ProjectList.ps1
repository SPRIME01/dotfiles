########## Get-ProjectList function
<#
.SYNOPSIS
Find all package.json and pyproject.toml files and show project structure.
.DESCRIPTION
Scans the current directory and subdirectories for package.json (Node.js) and pyproject.toml (Python)
files and displays information about projects including name, version, and available scripts/tools.
.EXAMPLE
Get-ProjectList
# Shows all Node.js and Python projects in current directory tree.
.EXAMPLE
projects
# Uses the alias to list projects.
#>
function Get-ProjectList {
    [CmdletBinding()]
    param()

    try {
        Write-Host "🔍 Scanning for Node.js and Python projects..." -ForegroundColor Cyan

        # Find both Node.js and Python project files
        $packageFiles = Get-ChildItem -Filter "package.json" -Recurse -Depth 3 -ErrorAction SilentlyContinue
        $pyprojectFiles = Get-ChildItem -Filter "pyproject.toml" -Recurse -Depth 3 -ErrorAction SilentlyContinue

        if (-not $packageFiles -and -not $pyprojectFiles) {
            Write-Warning "No package.json or pyproject.toml files found"
            return
        }

        $projects = @()

        # Process Node.js projects (package.json)
        foreach ($file in $packageFiles) {
            try {
                $dir = Split-Path $file.FullName -Parent
                $relativePath = Resolve-Path -Path $dir -Relative

                $pkg = Get-Content $file.FullName | ConvertFrom-Json
                $scripts = if ($pkg.scripts) {
                    ($pkg.scripts.PSObject.Properties.Name -join ", ")
                } else {
                    "None"
                }

                $projects += [PSCustomObject]@{
                    Directory = $relativePath
                    Type = "📦 Node.js"
                    Name = $pkg.name ?? "Unknown"
                    Version = $pkg.version ?? "Unknown"
                    Scripts = $scripts
                }
            }
            catch {
                Write-Verbose "Error reading $($file.FullName): $_"
            }
        }

        # Process Python projects (pyproject.toml)
        foreach ($file in $pyprojectFiles) {
            try {
                $dir = Split-Path $file.FullName -Parent
                $relativePath = Resolve-Path -Path $dir -Relative

                $content = Get-Content $file.FullName -Raw

                # Parse basic project info from pyproject.toml
                $name = "Unknown"
                $version = "Unknown"
                $tools = @()

                # Extract project name
                if ($content -match 'name\s*=\s*"([^"]+)"') {
                    $name = $matches[1]
                } elseif ($content -match "name\s*=\s*'([^']+)'") {
                    $name = $matches[1]
                }

                # Extract version
                if ($content -match 'version\s*=\s*"([^"]+)"') {
                    $version = $matches[1]
                } elseif ($content -match "version\s*=\s*'([^']+)'") {
                    $version = $matches[1]
                }

                # Check for common Python tools
                if ($content -match '\[tool\.') {
                    $toolMatches = [regex]::Matches($content, '\[tool\.([^\]]+)\]')
                    $tools = $toolMatches | ForEach-Object { $_.Groups[1].Value }
                }

                $toolsText = if ($tools) { ($tools -join ", ") } else { "None" }

                $projects += [PSCustomObject]@{
                    Directory = $relativePath
                    Type = "🐍 Python"
                    Name = $name
                    Version = $version
                    Scripts = $toolsText
                }
            }
            catch {
                Write-Verbose "Error reading $($file.FullName): $_"
            }
        }

        if ($projects) {
            Write-Host "`n📊 Found $($projects.Count) projects:" -ForegroundColor Green
            $projects | Sort-Object Type, Directory | Format-Table -AutoSize -Wrap

            $nodeCount = ($projects | Where-Object Type -like "*Node.js*").Count
            $pythonCount = ($projects | Where-Object Type -like "*Python*").Count
            Write-Host "📈 Summary: $nodeCount Node.js, $pythonCount Python projects" -ForegroundColor Cyan
        } else {
            Write-Warning "No valid project files found"
        }
    }
    catch {
        Write-Error "Error scanning for projects: $_"
    }
}
