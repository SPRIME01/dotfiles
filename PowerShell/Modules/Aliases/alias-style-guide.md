# PowerShell Aliases Module Style Guide

This document outlines the coding standards and best practices for the Aliases PowerShell module.

## Table of Contents
- [File Organization](#file-organization)
- [Function Structure](#function-structure)
- [Error Handling](#error-handling)
- [Naming Conventions](#naming-conventions)
- [Formatting](#formatting)
- [Comments](#comments)
- [Module Exports](#module-exports)
- [Parameter Handling](#parameter-handling)

## File Organization

### Module Structure
- Main module file (`Aliases.psm1`) contains dot-sourced references to individual function files
- Each function should be in its own PS1 file with the same name as the function
- Support functions like `Update-Aliases` are in their own module files

### Code Regions
Use regions to organize code into logical sections:
```powershell
#region Configuration
# Configuration code here
#endregion Configuration

#region Helper Functions
# Helper functions here
#endregion Helper Functions

#region Main Process
# Main process code here
#endregion Main Process
```

## Function Structure

### Function Declaration
- Use proper verb-noun naming following PowerShell conventions
- Include comment-based help for all public functions
- Declare `CmdletBinding` and parameters properly

```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
        Brief description
    .DESCRIPTION
        Detailed description
    .EXAMPLE
        Example-usage
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$ParameterName
    )

    # Function code
}
```

### Helper Functions
- Declare helper functions inside the main function they support
- Use clear, descriptive names that explain their purpose
- Include proper parameter declarations with types

## Error Handling

### Try/Catch Blocks
- Use try/catch blocks for error-prone operations
- Set `$ErrorActionPreference = 'Stop'` for consistent error behavior
- Include meaningful error messages with context

```powershell
try {
    # Operation that might fail
}
catch {
    Write-Error "Context description: $_"
}
```

### ShouldProcess
- Use `ShouldProcess` for functions that change state
- Include proper `-WhatIf` support
- Return meaningful values from functions to indicate success/failure

## Naming Conventions

### Variables
- Use PascalCase for all variables: `$VariableName`
- Use descriptive names that indicate purpose: `$ModulePath`, not `$path`
- Avoid abbreviations unless very common: `$Dir` is acceptable for directory

### Functions
- Public functions: Use approved PowerShell Verb-Noun format
- Helper functions: Use descriptive action names like `Get-LineIndentation`
- Boolean functions: Consider using Is/Has prefix for functions returning boolean values

## Formatting

### Indentation
- Use 4 spaces for indentation (not tabs)
- Indent consistently within code blocks
- Align parameters and pipeline operations for readability

### Line Length
- Keep lines to a reasonable length (80-120 characters)
- Use backtick (`) for line continuation when necessary
- For string concatenation, prefer string format or subexpressions over concatenation

### Spacing
- Use a space after commas and around operators
- Use blank lines to separate logical code sections
- No trailing whitespace

## Comments

### Required Comments
- Comment-based help for all public functions
- Brief comments explaining complex logic
- Description for each parameter in comment-based help

### Code Markers
Use special comment markers for maintainable code:
```powershell
# Marker for dot sourcing new files
$DotSourceMarker = "# Add more .ps1 files here as you create them"

# Marker for alias declarations
$SetAliasMarker = "# Add more Set-Alias lines here"
```

## Module Exports

### Export-ModuleMember
- Always explicitly declare which functions and aliases to export
- Group exports at the end of each module file
- Use consistent formatting for multi-line export statements

```powershell
Export-ModuleMember -Function Get-Thing, Set-Thing -Alias gthing, sthing
```

## Parameter Handling

### Parameter Declaration
- Include parameter types for all parameters
- Use mandatory attribute when appropriate
- Use parameter validation attributes where possible
- Group related parameters with ParameterSets when applicable

### Parameter Defaults
- Use sensible defaults where appropriate
- Document defaults in parameter help

### Parameter Validation
- Use validation attributes when possible
- For complex validation, include validation in the function body

## Examples

### Good Example: Helper Function

```powershell
function Get-LineIndentation {
    param ([string]$Line)
    if ([string]::IsNullOrEmpty($Line)) { return "" }
    return $Line -replace '\S.*', ''
}
```

### Good Example: Error Handling

```powershell
if (-not (Test-Path -Path $FilePath)) {
    Write-Error "Source file not found: $FilePath"
    return $false
}
```

### Good Example: ArrayList Usage

```powershell
$updatedContent = [System.Collections.ArrayList]::new()
# When adding items
[void]$updatedContent.Add($line)  # [void] suppresses output
```
