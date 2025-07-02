########## Get-AliasHelp function
<#
.SYNOPSIS
Lists all aliases defined in this module with their descriptions or function synopses.
.DESCRIPTION
Provides a quick reference guide for the custom aliases available from the 'Aliases' module.
It displays the alias name and a brief description (either explicitly set or derived from the
synopsis of the function the alias points to).
.EXAMPLE
Get-AliasHelp
# Displays a table of aliases and their descriptions from this module.
.EXAMPLE
aliashelp
# Uses the alias to display the help table.
#>
function Get-AliasHelp {
    [CmdletBinding()]
    param()

    try {
        # Try multiple methods to get aliases
        $aliases = @()

        # Method 1: Try to get from the current module if available
        if ($MyInvocation.MyCommand.Module) {
            Write-Verbose "Getting aliases from module: $($MyInvocation.MyCommand.Module.Name)"
            $aliases = Get-Command -Module $MyInvocation.MyCommand.Module.Name -CommandType Alias -ErrorAction SilentlyContinue
        }

        # Method 2: If that didn't work, try to import the module and get aliases
        if (-not $aliases) {
            $modulePath = "$HOME\dotfiles\PowerShell\Modules\Aliases\Aliases.psm1"
            if (Test-Path $modulePath) {
                Write-Verbose "Importing module from: $modulePath"
                $tempModule = Import-Module $modulePath -PassThru -Force -ErrorAction SilentlyContinue
                if ($tempModule) {
                    $aliases = Get-Command -Module $tempModule.Name -CommandType Alias -ErrorAction SilentlyContinue
                }
            }
        }

        # Method 3: If still no aliases, get all aliases that point to functions in our module
        if (-not $aliases) {
            Write-Verbose "Fallback: Getting all aliases that point to our functions"
            $ourFunctions = @(
                'Get-AliasHelp', 'Get-FileTree', 'Get-SecretKey', 'Set-ProjectRoot', 'Update-EnvVars',
                'Test-NewFunction', 'Invoke-UpdateAliasesModule', 'Find-Directory', 'Open-Explorer',
                'Get-GitStatus', 'New-GitCommit', 'Get-ProjectList', 'Stop-ProcessByPort', 'Find-Text',
                'Get-FileSize', 'Get-SystemInfo', 'Test-Port', 'Get-NetworkConnections', 'Show-Json'
            )

            $allAliases = Get-Alias -ErrorAction SilentlyContinue
            $aliases = $allAliases | Where-Object { $_.Definition -in $ourFunctions }
        }

        if (-not $aliases) {
            Write-Warning "No aliases found. Make sure the Aliases module is loaded."
            return
        }

        Write-Host "📋 Available PowerShell Aliases ($($aliases.Count) total)" -ForegroundColor Cyan
        Write-Host ""

        $output = foreach ($alias in $aliases) {
            $description = $alias.Description
            # If description is empty, try getting synopsis from the resolved command
            if ([string]::IsNullOrWhiteSpace($description)) {
                try {
                    $resolvedCommand = Get-Command $alias.Definition -ErrorAction SilentlyContinue
                    if ($resolvedCommand -and $resolvedCommand.CommandType -eq 'Function') {
                        # Attempt to parse comment-based help synopsis
                        $synopsisMatch = $resolvedCommand.Definition -match '(?s)\.SYNOPSIS\s*(.*?)\s*\.DESCRIPTION'
                        if ($synopsisMatch) {
                            $description = $matches[1].Trim() -replace '\s+', ' '
                        }
                        elseif ($resolvedCommand.Definition -match '(?s)\.SYNOPSIS\s*(.*?)\s*\.') {
                            $description = $matches[1].Trim() -replace '\s+', ' '
                        }
                        else {
                            $description = "PowerShell function: $($alias.Definition)"
                        }
                    }
                    else {
                        $description = "Alias for: $($alias.Definition)"
                    }
                }
                catch {
                    $description = "Error retrieving description for $($alias.Definition)"
                }
            }

            [PSCustomObject]@{
                Alias       = $alias.Name
                Description = $description
                Command     = $alias.Definition
            }
        }

        $output | Sort-Object Alias | Format-Table -AutoSize -Wrap

        Write-Host "💡 Tip: Use 'updatealiases' to regenerate all aliases after adding new functions" -ForegroundColor Yellow

    }
    catch {
        Write-Error "Failed to get alias help: $_"
    }
}

# Alias for Get-AliasHelp
# Set-Alias -Name aliashelp -Value Get-AliasHelp -Description "Lists aliases defined in this module with descriptions." -Scope Global -Force
