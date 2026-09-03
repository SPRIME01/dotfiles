---
name: dotfiles-doctor
description: Audit, repair, document, and test a Windows plus WSL2 dotfiles architecture from Windows PowerShell. Use when validating profile and module loading, host separation, recursion safety, UNC usage, and cross-host contamination in dotfiles repositories.
---

# Dotfiles Doctor

Load the bundled script and run the dispatcher:

```powershell
. "$PSScriptRoot/scripts/dotfiles-doctor.ps1"
Invoke-DotfilesDoctor -Action Audit
Invoke-DotfilesDoctor -Action Fix
Invoke-DotfilesDoctor -Action Fix -Apply -ConfirmToken APPLY
Invoke-DotfilesDoctor -Action Document
Invoke-DotfilesDoctor -Action Test
```

## Safety Contract

- Never modify files unless `-Apply -ConfirmToken APPLY` is provided.
- Always print diffs before applying changes.
- Always run tests automatically after `Fix -Apply`.

