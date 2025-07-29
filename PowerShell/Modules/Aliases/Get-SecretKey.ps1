########## Get-SecretKey function
<#
.SYNOPSIS
Generates a cryptographically secure URL-safe string.
.DESCRIPTION
Uses Python's 'secrets' module to generate a random, URL-safe string suitable for secret keys,
tokens, etc. Requires Python 3.6+ to be installed and in the system PATH.
.PARAMETER Length
The desired length of the random byte string before base64 encoding. Defaults to 32 bytes,
resulting in approximately 43 URL-safe characters.
.EXAMPLE
Get-SecretKey
# Generates a default length secret key.
.EXAMPLE
gensecret -Length 48
# Generates a longer secret key using the alias.
#>
function Get-SecretKey {
    [CmdletBinding()]
    param (
        [Parameter()]
        [int]$Length = 32 # Number of random bytes
    )

    try {
        # Check if python is available
        $pythonCheck = Get-Command python -ErrorAction SilentlyContinue
        if (-not $pythonCheck) {
            throw "Python command not found. Please ensure Python 3.6+ is installed and in your PATH."
        }

        # Execute python command
        $command = "import secrets; print(secrets.token_urlsafe($Length))"
        Write-Verbose "Executing Python command: $command"
        $result = python -c $command 2>&1 # Capture stderr too

        # Check python exit code
        if ($LASTEXITCODE -ne 0) {
            throw "Python script failed with exit code $LASTEXITCODE. Output: $result"
        }

        # Output the result cleanly
        Write-Output $result.Trim()

    }
    catch {
        Write-Error "Failed to generate secret key: $_"
    }
}

# Alias for Get-SecretKey
# Set-Alias -Name gensecret -Value Get-SecretKey -Description "Alias for Get-SecretKey" -Scope Global -Force
