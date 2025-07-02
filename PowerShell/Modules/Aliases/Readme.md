# PowerShell Aliases Module

This module provides a collection of custom PowerShell functions and their corresponding aliases, organized for easy management. It includes a utility function to automatically update the module when new function files are added.

## Features

*   Loads functions from individual `.ps1` files within the module directory.
*   Defines convenient aliases for loaded functions.
*   Includes an `Update-Aliases` function to automatically:
    *   Scan for new `.ps1` function files.
    *   Backup the main `Aliases.psm1` file (keeps the last 2 backups).
    *   Add dot-sourcing lines for new functions to `Aliases.psm1`.
    *   Add `Set-Alias` commands for new functions (assumes lowercase alias based on function name).
    *   Update the `Export-ModuleMember` command in `Aliases.psm1`.
    *   Reload the module in the current session.

## Available Functions and Aliases

*   **`Get-FileTree` (`filetree`)**: Displays a tree view of files and folders.
*   **`Set-ProjectRoot` (`projectroot`)**: Sets a project root environment variable.
*   **`Update-EnvVars` (`updateenv`)**: Updates user environment variables persistently and in the current session.
*   **`Get-SecretKey` (`gensecret`)**: Generates a secure random key.
*   **`Get-AliasHelp` (`aliashelp`)**: Lists aliases defined in this module with their descriptions.
*   **`Update-Aliases` (`updatealiases`)**: Updates the module based on `.ps1` files found (see below).

## Using `Update-Aliases`

The `updatealiases` command simplifies adding new functions to this module.

**Prerequisites:**

1.  **Function File Naming:** The `.ps1` file name should match the function name defined within it (e.g., `My-NewFunction.ps1` contains `function My-NewFunction {...}`).
2.  **Alias Convention:** The script automatically creates a lowercase alias based on the function name (e.g., `my-newfunction`).
3.  **Markers in `Aliases.psm1`:** The main `Aliases.psm1` file *must* contain the following specific comment lines in the correct locations for the update script to work:
    *   Inside the dot-sourcing `try` block:
        ```powershell
        # Add more .ps1 files here as you create them
        ```
    *   Inside the `Set-Alias` `try` block:
        ```powershell
        # Add more Set-Alias lines here
        ```
    *   The line starting with `Export-ModuleMember`.

**Usage:**

1.  Create your new function and save it as a `.ps1` file (e.g., `My-CoolFunction.ps1`) inside the `Aliases` module directory (`C:\Users\sprim\OneDrive\MyDocuments\PowerShell\Modules\Aliases`).
2.  Open your PowerShell terminal.
3.  Run the command:
    ```powershell
    updatealiases
    ```
4.  The script will:
    *   Backup the current `Aliases.psm1`.
    *   Modify `Aliases.psm1` to include the dot-source, alias definition, and export for `My-CoolFunction`.
    *   Reload the `Aliases` module.
5.  Your new function (`My-CoolFunction`) and its alias (`my-coolfunction`) should now be available in your session.

## Installation/Setup

1.  Place the `Aliases` folder (containing `Aliases.psm1` and all the function `.ps1` files) into one of your PowerShell module paths (e.g., `C:\Users\sprim\OneDrive\MyDocuments\PowerShell\Modules`).
2.  Ensure your PowerShell profile (`Microsoft.PowerShell_profile.ps1`) imports the module, typically with `Import-Module Aliases`.

## Backup Mechanism

The `updatealiases` command automatically creates timestamped backups of `Aliases.psm1` before making changes. It keeps the two most recent backups (`Aliases.psm1.YYYYMMDD_HHMMSS.bak`) in the module directory and removes older ones.
