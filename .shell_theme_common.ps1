oh-my-posh init pwsh | Invoke-Expression
Import-Module Terminal-Icons

if (-not (Get-Module PSReadLine)) {
    Import-Module PSReadLine
}

Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -PredictionSource History
