#!/usr/bin/env bash
set -euo pipefail

ps_code=$(
	cat <<'PWS'
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force | Out-Null
$script = "\\wsl.localhost\Ubuntu-24.04\home\sprime01\dotfiles\scripts\move-documents-off-onedrive.ps1"
try { wsl -l -q *> $null } catch {}
$max=20; for($i=0;$i -lt $max -and -not (Test-Path $script);$i++){ Start-Sleep -Milliseconds 250 }
if (Test-Path $script) { & $script -DryRun } else { Write-Error "Script not reachable: $script" }
PWS
)
enc=$(printf "%s" "$ps_code" | iconv -f utf-8 -t utf-16le | base64 -w0)
powershell.exe -NoProfile -NonInteractive -EncodedCommand "$enc" | tr -d '\r'
