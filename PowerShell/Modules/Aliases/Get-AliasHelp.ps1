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
        Write-Verbose "Gathering aliases from module: $MyInvocation.MyCommand.Module.Name"
        $aliases = Get-Command -Module $MyInvocation.MyCommand.Module.Name -CommandType Alias -ErrorAction Stop

        if (-not $aliases) {
            Write-Warning "No aliases found in the '$($MyInvocation.MyCommand.Module.Name)' module."
            return
        }

        $output = foreach ($alias in $aliases) {
            $description = $alias.Description
            # If description is empty, try getting synopsis from the resolved command
            if ([string]::IsNullOrWhiteSpace($description)) {
                try {
                    $resolvedCommand = Get-Command $alias.Definition -ErrorAction SilentlyContinue
                    if ($resolvedCommand -and $resolvedCommand.CommandType -eq 'Function' -and $null -eq $resolvedCommand.HelpUri) {
                        # Check if it's a function from this module
                        # Attempt to parse comment-based help synopsis
                        $synopsisMatch = $resolvedCommand.Definition -match '(?s)\.SYNOPSIS\s*(.*?)\s*(\.|\#\>)'
                        if ($synopsisMatch) {
                            $description = $matches[1].Trim() -replace '\s+', ' ' # Clean up whitespace
                        }
                        else {
                            $description = "(No description or synopsis found for $($alias.Definition))"
                        }
                    }
                    else {
                        $description = "(Alias for: $($alias.Definition))"
                    }
                }
                catch {
                    $description = "(Error retrieving description for $($alias.Definition))"
                }
            }

            [PSCustomObject]@{
                Alias       = $alias.Name
                Description = $description
                Command     = $alias.Definition
            }
        }

        $output | Format-Table -AutoSize -Wrap

    }
    catch {
        Write-Error "Failed to get alias help: $_"
    }
}

# Alias for Get-AliasHelp
# Set-Alias -Name aliashelp -Value Get-AliasHelp -Description "Lists aliases defined in this module with descriptions." -Scope Global -Force
