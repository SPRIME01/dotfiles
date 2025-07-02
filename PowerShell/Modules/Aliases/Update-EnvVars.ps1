########## Update-EnvVars function
<#
.SYNOPSIS
Updates or creates a user-level environment variable persistently.
.DESCRIPTION
Modifies a Windows environment variable at the user scope. The change persists across sessions
and the current session is updated immediately. Supports -WhatIf and -Confirm.
.PARAMETER Name
The name of the environment variable.
.PARAMETER Value
The new value for the environment variable.
.EXAMPLE
Update-EnvVars -Name "MY_VARIABLE" -Value "MyValue"
# Sets MY_VARIABLE=MyValue for the current user.
.EXAMPLE
updateenv "JAVA_HOME" "C:\Program Files\Java\jdk-17"
# Uses the alias to update JAVA_HOME.
.NOTES
Uses [Environment]::SetEnvironmentVariable for persistence.
Refreshes the current session using Set-Item env:.
#>
function Update-EnvVars {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )

    $target = [System.EnvironmentVariableTarget]::User
    $action = "Set User Environment Variable '$Name' to '$Value'"

    if ($PSCmdlet.ShouldProcess($Name, $action)) {
        try {
            [System.Environment]::SetEnvironmentVariable($Name, $Value, $target)
            Write-Verbose "Successfully set environment variable '$Name' at User scope."

            # Refresh current session's environment variable
            Set-Item -Path "env:$Name" -Value $Value -ErrorAction Stop
            Write-Verbose "Refreshed environment variable '$Name' in current session."
            Write-Host "Environment variable '$Name' updated successfully." -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to update environment variable '$Name': $_"
        }
    }
}

# Alias for Update-EnvVars
# Set-Alias -Name updateenv -Value Update-EnvVars -Description "Alias for Update-EnvVars" -Scope Global -Force
