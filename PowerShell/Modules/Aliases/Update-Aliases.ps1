function Update-Aliases {
    <#
    .SYNOPSIS
        Updates the Aliases module by adding new PS1 files and creating aliases.

    .DESCRIPTION
        This function scans the module directory for new PS1 files, adds them to the main module,
        creates aliases for them, and updates the Export-ModuleMember statements in the module.

    .EXAMPLE
        Update-Aliases

        Updates the Aliases module with any new PS1 files found in the module directory.

    .NOTES
        Author: Original author
        Version: 1.1
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    #region Configuration
    $ErrorActionPreference = 'Stop'
    Write-Verbose "Starting alias update process"

    # File paths
    $ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $MainModuleFile = Join-Path -Path $ModulePath -ChildPath "Aliases.psm1"
    $BackupFolder = $ModulePath

    # Configuration settings
    $MaxBackups = 2
    $DotSourceMarker = "# Add more .ps1 files here as you create them"
    $SetAliasMarker = "# Add more Set-Alias lines here"
    $ExportMemberCommand = "Export-ModuleMember"
    $ExcludedFiles = @("Aliases.psm1", "Update-Aliases.psm1")
    #endregion Configuration

    #region Helper Functions
    function Backup-ModuleFile {
        [CmdletBinding(SupportsShouldProcess)]
        param (
            [Parameter(Mandatory)][string]$FilePath,
            [Parameter(Mandatory)][string]$BackupDir,
            [Parameter(Mandatory)][int]$MaxCount
        )

        Write-Verbose "Creating backup of $FilePath"

        # Check if source file exists
        if (-not (Test-Path -Path $FilePath)) {
            Write-Error "Source file not found: $FilePath"
            return $false
        }

        # Create backup directory if needed
        if (-not (Test-Path -Path $BackupDir -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($BackupDir, "Create backup directory")) {
                $null = New-Item -Path $BackupDir -ItemType Directory -Force
            }
            else { return $false }
        }

        # Clean up old backups
        $fileNameOnly = [System.IO.Path]::GetFileName($FilePath)
        $existingBackups = Get-ChildItem -Path $BackupDir -Filter "$fileNameOnly.*.bak" |
        Sort-Object -Property LastWriteTime

        $backupsToRemove = $existingBackups.Count - $MaxCount + 1
        if ($backupsToRemove -gt 0) {
            $existingBackups | Select-Object -First $backupsToRemove | ForEach-Object {
                if ($PSCmdlet.ShouldProcess($_.FullName, "Remove old backup")) {
                    Remove-Item -Path $_.FullName -Force
                }
            }
        }

        # Create new backup
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFile = Join-Path -Path $BackupDir -ChildPath "$fileNameOnly.$timestamp.bak"

        if ($PSCmdlet.ShouldProcess($FilePath, "Backup to $backupFile")) {
            try {
                Copy-Item -Path $FilePath -Destination $backupFile -Force
                return $true
            }
            catch {
                Write-Error "Failed to create backup: $_"
                return $false
            }
        }

        return $false
    }

    function Get-NewFunctionFiles {
        param (
            [Parameter(Mandatory)][string]$Directory,
            [string[]]$ExcludeFiles,
            [string[]]$ExistingFiles
        )

        Write-Verbose "Scanning for new function files in $Directory"

        $allScriptFiles = Get-ChildItem -Path $Directory -Filter "*.ps1" -File |
        Where-Object { $_.Name -notin $ExcludeFiles }

        return $allScriptFiles | Where-Object { $_.Name -notin $ExistingFiles }
    }

    function Get-LineIndentation {
        param ([string]$Line)
        if ([string]::IsNullOrEmpty($Line)) { return "" }
        return $Line -replace '\S.*', ''
    }

    function Update-ModuleExports {
        param (
            [string[]]$FileContent,
            [string[]]$FunctionNames,
            [string[]]$AliasNames
        )

        Write-Verbose "Updating module export statements"
        $startIndex = -1
        $endIndex = -1
        $indentation = ""

        # Find Export-ModuleMember statement
        for ($i = 0; $i -lt $FileContent.Length; $i++) {
            $line = $FileContent[$i]
            if ($line.TrimStart().StartsWith($ExportMemberCommand)) {
                $startIndex = $i
                $indentation = Get-LineIndentation -Line $line

                # Find the end of the statement (line not ending with backtick)
                for ($j = $i; $j -lt $FileContent.Length; $j++) {
                    if (-not $FileContent[$j].TrimEnd().EndsWith('`')) {
                        $endIndex = $j
                        break
                    }
                }

                # If we didn't find an explicit end, assume it's a one-liner
                if ($endIndex -eq -1) {
                    $endIndex = $i
                }

                break
            }
        }

        # If no export statement found, return original content
        if ($startIndex -eq -1) {
            Write-Warning "No $ExportMemberCommand statement found in module file."
            return $FileContent
        }

        # Extract current exports
        $exportBlock = $FileContent[$startIndex..$endIndex] -join "`n"

        # Parse existing function and alias exports
        $functionMatch = [regex]::Match($exportBlock, '-Function\s+([^-]+?)(?=\s+-\w+|\s*$)')
        $aliasMatch = [regex]::Match($exportBlock, '-Alias\s+(.+?)(?=\s+-\w+|\s*$)')

        $existingFunctions = @()
        if ($functionMatch.Success) {
            $existingFunctions = $functionMatch.Groups[1].Value -split '[,\s`]+' |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        }

        $existingAliases = @()
        if ($aliasMatch.Success) {
            $existingAliases = $aliasMatch.Groups[1].Value -split '[,\s`]+' |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        }

        # Combine and deduplicate
        $allFunctions = ($existingFunctions + $FunctionNames) |
        Where-Object { -not [string]::IsNullOrEmpty($_) } |
        Sort-Object -Unique

        $allAliases = ($existingAliases + $AliasNames) |
        Where-Object { -not [string]::IsNullOrEmpty($_) } |
        Sort-Object -Unique

        # Create new export statement
        $newExport = "$indentation$ExportMemberCommand -Function $($allFunctions -join ', ') -Alias $($allAliases -join ', ')"

        # Replace in content
        $updatedContent = @()
        $updatedContent += $FileContent[0..($startIndex - 1)]
        $updatedContent += $newExport
        if ($endIndex + 1 -lt $FileContent.Length) {
            $updatedContent += $FileContent[($endIndex + 1)..($FileContent.Length - 1)]
        }

        return $updatedContent
    }
    #endregion Helper Functions

    #region Main Process
    try {
        # Step 1: Backup the main module file
        if (-not (Backup-ModuleFile -FilePath $MainModuleFile -BackupDir $BackupFolder -MaxCount $MaxBackups)) {
            Write-Warning "Backup operation failed or was cancelled. Aborting update."
            return
        }

        # Step 2: Read module content
        Write-Verbose "Reading module file: $MainModuleFile"
        $moduleContent = Get-Content -Path $MainModuleFile -ErrorAction Stop

        # Step 3: Find existing dot-sourced files
        $existingDotSources = $moduleContent |
        Where-Object { $_ -match '^\s*\.\s*"\$ModulePath\\(?<FileName>[\w\-]+\.ps1)"' } |
        ForEach-Object { $Matches.FileName }

        Write-Verbose "Found existing dot-sourced files: $($existingDotSources -join ', ')"

        # Step 4: Find new function files
        $newFiles = Get-NewFunctionFiles -Directory $ModulePath -ExcludeFiles $ExcludedFiles -ExistingFiles $existingDotSources

        if ($newFiles.Count -eq 0) {
            Write-Output "No new function files found to add."
            if ($PSCmdlet.ShouldProcess("Aliases Module", "Force reload")) {
                Import-Module -Name Aliases -Force -ErrorAction SilentlyContinue
            }
            return
        }

        Write-Verbose "Found $($newFiles.Count) new files to add"

        # Step 5: Prepare updated content
        $updatedContent = [System.Collections.ArrayList]::new()
        $newFunctions = @()
        $newAliases = @()

        foreach ($line in $moduleContent) {
            # Insert dot-source statements before the marker
            if ($line.Trim() -eq $DotSourceMarker) {
                $indent = Get-LineIndentation -Line $line
                # Add new dot-source lines
                foreach ($file in $newFiles) {
                    $dotSourceLine = "$indent. `"$ModulePath\$($file.Name)`""
                    [void]$updatedContent.Add($dotSourceLine)
                }
            }

            # Insert alias statements before the marker
            if ($line.Trim() -eq $SetAliasMarker) {
                $indent = Get-LineIndentation -Line $line
                # Add new alias lines
                foreach ($file in $newFiles) {
                    $functionName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                    $aliasName = $functionName.ToLower()

                    # Track new functions and aliases
                    $newFunctions += $functionName
                    $newAliases += $aliasName

                    $aliasLine = "$indent Set-Alias -Name $aliasName -Value $functionName -Description `"Alias for $functionName`" -Scope Global -Force"
                    [void]$updatedContent.Add($aliasLine)
                }
            }

            # Add the original line
            [void]$updatedContent.Add($line)
        }

        # Step 6: Update Export-ModuleMember statement
        $finalContent = Update-ModuleExports -FileContent $updatedContent.ToArray() -FunctionNames $newFunctions -AliasNames $newAliases

        # Step 7: Write changes and reload module
        if ($PSCmdlet.ShouldProcess($MainModuleFile, "Update module file")) {
            Set-Content -Path $MainModuleFile -Value $finalContent -Encoding UTF8

            Write-Verbose "Reloading Aliases module"
            Import-Module -Name Aliases -Force
            Write-Output "Aliases module updated and reloaded successfully."
        }
        else {
            Write-Output "Update cancelled. No changes written."
        }
    }
    catch {
        Write-Error "Error updating Aliases module: $_"
    }
    #endregion Main Process
}


