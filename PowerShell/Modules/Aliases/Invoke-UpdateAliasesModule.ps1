########## Invoke-UpdateAliasesModule function
<#
.SYNOPSIS
Completely regenerates the Aliases module and profile lazy-loading functions.
.DESCRIPTION
This function wraps the Update-AliasesModule.ps1 script to provide a callable function
that can be aliased. It scans the module directory for .ps1 function files and:
1. Completely regenerates the Aliases.psm1 module file with proper dot-sourcing, aliases, and exports
2. Updates the PowerShell profile with corresponding lazy-loading proxy functions
3. Creates backups of both files before making changes
.PARAMETER WhatIf
Shows what would be done without making actual changes.
.PARAMETER Confirm
Prompts for confirmation before making changes.
.EXAMPLE
Invoke-UpdateAliasesModule
# Regenerates both the module and profile files.
.EXAMPLE
updatealiases
# Uses the alias to regenerate the module and profile files.
.EXAMPLE
Invoke-UpdateAliasesModule -WhatIf
# Shows what changes would be made without executing them.
.NOTES
This function calls the Update-AliasesModule.ps1 script.
#>
function Invoke-UpdateAliasesModule {
    [CmdletBinding(SupportsShouldProcess)]
    param()    # Try multiple portable methods to find the script
    $possiblePaths = @()

    # Method 1: If called from within the module, use the module's base directory
    if ($MyInvocation.MyCommand.Module -and $MyInvocation.MyCommand.Module.Path) {
        $moduleBase = Split-Path $MyInvocation.MyCommand.Module.Path -Parent
        $possiblePaths += Join-Path $moduleBase "Update-AliasesModule.ps1"
    }

    # Method 2: Use known dotfiles structure (most portable)
    $possiblePaths += Join-Path "$HOME\dotfiles\PowerShell\Modules\Aliases" "Update-AliasesModule.ps1"

    # Method 3: Use the current PowerShell location if we're in the right directory
    $possiblePaths += Join-Path (Get-Location) "Update-AliasesModule.ps1"

    # Method 4: Try to use the function file's directory (works when called directly, not through proxy)
    try {
        $functionPath = $MyInvocation.MyCommand.Definition
        if ($functionPath -and (Test-Path $functionPath) -and $functionPath.EndsWith('.ps1')) {
            $possiblePaths += Join-Path (Split-Path -Parent $functionPath) "Update-AliasesModule.ps1"
        }
    }
    catch {
        # Ignore errors from proxy functions
    }

    $scriptPath = $null
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $scriptPath = $path
            Write-Verbose "Found script at: $scriptPath"
            break
        }
    }

    if (-not $scriptPath) {
        Write-Error "Update-AliasesModule.ps1 script not found. Tried paths: $($possiblePaths -join ', ')"
        return
    }

    # Forward all parameters to the script
    $splatParams = @{}
    if ($PSBoundParameters.ContainsKey('WhatIf')) { $splatParams['WhatIf'] = $WhatIf }
    if ($PSBoundParameters.ContainsKey('Confirm')) { $splatParams['Confirm'] = $Confirm }
    if ($PSBoundParameters.ContainsKey('Verbose')) { $splatParams['Verbose'] = $Verbose }

    & $scriptPath @splatParams
}
