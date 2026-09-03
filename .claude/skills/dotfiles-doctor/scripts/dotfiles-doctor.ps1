Set-StrictMode -Version Latest

function New-DdIssue {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][ValidateSet('Info','Warning','Error')][string]$Severity,
        [Parameter(Mandatory)][string]$Message,
        [string]$File,
        [int]$Line = 0,
        [hashtable]$Data
    )
    [pscustomobject]@{
        Id       = $Id
        Severity = $Severity
        Message  = $Message
        File     = $File
        Line     = $Line
        Data     = $Data
    }
}

function Resolve-DotfilesRoot {
    [CmdletBinding()]
    param(
        [string]$RootPath,
        [string]$Distro = 'Ubuntu'
    )

    if ($RootPath -and (Test-Path $RootPath)) { return (Resolve-Path $RootPath).Path }
    if ($env:DOTFILES_ROOT -and (Test-Path $env:DOTFILES_ROOT)) { return (Resolve-Path $env:DOTFILES_ROOT).Path }

    $cwd = (Get-Location).Path
    if (Test-Path (Join-Path $cwd 'PowerShell\Microsoft.PowerShell_profile.ps1')) { return $cwd }

    $unc = "\\wsl.localhost\$Distro\home\$env:USERNAME\dotfiles"
    if (Test-Path $unc) { return $unc }
    $legacy = "\\wsl$\$Distro\home\$env:USERNAME\dotfiles"
    if (Test-Path $legacy) { return $legacy }

    throw "Unable to resolve dotfiles root. Provide -RootPath."
}

function Resolve-WindowsBootstrapProfilePath {
    [CmdletBinding()]
    param([string]$BootstrapProfilePath)

    if ($BootstrapProfilePath -and (Test-Path $BootstrapProfilePath)) {
        return (Resolve-Path $BootstrapProfilePath).Path
    }

    $candidates = @(
        $PROFILE.CurrentUserCurrentHost,
        (Join-Path (Join-Path $env:USERPROFILE 'Documents\PowerShell') 'Microsoft.PowerShell_profile.ps1'),
        (Join-Path (Join-Path $env:USERPROFILE 'OneDrive\MyDocuments\PowerShell') 'Microsoft.PowerShell_profile.ps1')
    ) | Where-Object { $_ -and (Test-Path $_) }

    if ($candidates.Count -gt 0) { return (Resolve-Path $candidates[0]).Path }
    throw "Unable to resolve Windows bootstrap profile path. Provide -BootstrapProfilePath."
}

function Get-DdRepoProfilePath {
    param([Parameter(Mandatory)][string]$RootPath)
    Join-Path $RootPath 'PowerShell\Microsoft.PowerShell_profile.ps1'
}

function Convert-UncToLinuxPath {
    param([Parameter(Mandatory)][string]$Path)
    if ($Path -match '^\\\\wsl(?:\.localhost)?\\([^\\]+)\\(.+)$') {
        '/' + ($Matches[2] -replace '\\','/')
    } else {
        $Path
    }
}

function Get-DotfilesTextFiles {
    param([Parameter(Mandatory)][string]$RootPath)
    $includeExt = @('.ps1','.psm1','.psd1','.sh','.zsh','.bash','.tmpl')
    Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch '\\\.git\\' -and
            $_.FullName -notmatch '\\\.doctor\\' -and
            ($includeExt -contains $_.Extension -or $_.Name -match 'profile|bashrc|zshrc')
        }
}

function Get-FileImports {
    param([Parameter(Mandatory)][string]$FilePath)
    $lines = Get-Content -Path $FilePath -ErrorAction SilentlyContinue
    $imports = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*\.\s+["'']?([^"'']+\.ps1)["'']?') {
            $imports += [pscustomobject]@{ Kind='DotSource'; Target=$Matches[1]; Line=$i+1; Raw=$line }
        }
        if ($line -match 'Import-Module\s+["'']?([^"'']+)["'']?') {
            $imports += [pscustomobject]@{ Kind='ImportModule'; Target=$Matches[1]; Line=$i+1; Raw=$line }
        }
    }
    $imports
}

function Resolve-ImportTarget {
    param(
        [Parameter(Mandatory)][string]$SourceFile,
        [Parameter(Mandatory)][string]$ImportTarget,
        [Parameter(Mandatory)][string]$RootPath
    )

    if ($ImportTarget -match '^[A-Za-z]:\\' -or $ImportTarget -match '^\\\\') { return $null }
    if ($ImportTarget -notmatch '\.ps1$') { return $null }

    $base = Split-Path -Parent $SourceFile
    $candidate = Join-Path $base $ImportTarget
    if (Test-Path $candidate) { return (Resolve-Path $candidate).Path }
    $candidate2 = Join-Path $RootPath ($ImportTarget -replace '/','\')
    if (Test-Path $candidate2) { return (Resolve-Path $candidate2).Path }
    $null
}

function Build-ModuleDag {
    param([Parameter(Mandatory)][string]$RootPath)

    $files = Get-DotfilesTextFiles -RootPath $RootPath
    $edges = New-Object System.Collections.Generic.List[object]
    $byFile = @{}

    foreach ($f in $files) { $byFile[$f.FullName] = Get-FileImports -FilePath $f.FullName }

    foreach ($kv in $byFile.GetEnumerator()) {
        $src = $kv.Key
        foreach ($imp in $kv.Value) {
            $targetPath = Resolve-ImportTarget -SourceFile $src -ImportTarget $imp.Target -RootPath $RootPath
            $edges.Add([pscustomobject]@{
                Source = $src
                Target = $targetPath
                Kind   = $imp.Kind
                Raw    = $imp.Raw
                Line   = $imp.Line
            })
        }
    }

    [pscustomobject]@{
        Files = $files.FullName
        Edges = $edges
    }
}

function Test-DagCycles {
    param([Parameter(Mandatory)]$Dag)

    $adj = @{}
    foreach ($f in $Dag.Files) { $adj[$f] = @() }
    foreach ($e in $Dag.Edges | Where-Object { $_.Target }) { $adj[$e.Source] += $e.Target }

    $visited = @{}
    $stack = @{}
    $cycles = New-Object System.Collections.Generic.List[object]

    function VisitNode([string]$n, [System.Collections.Generic.List[string]]$path) {
        $visited[$n] = $true
        $stack[$n] = $true
        $path.Add($n) | Out-Null

        foreach ($m in $adj[$n]) {
            if (-not $visited.ContainsKey($m)) {
                VisitNode -n $m -path $path
            } elseif ($stack.ContainsKey($m) -and $stack[$m]) {
                $idx = $path.IndexOf($m)
                if ($idx -ge 0) {
                    $cycle = $path.GetRange($idx, $path.Count - $idx)
                    $cycles.Add(($cycle + @($m)) -join ' -> ')
                }
            }
        }

        $stack[$n] = $false
        if ($path.Count -gt 0) { $path.RemoveAt($path.Count - 1) }
    }

    foreach ($node in $Dag.Files) {
        if (-not $visited.ContainsKey($node)) { VisitNode -n $node -path (New-Object System.Collections.Generic.List[string]) }
    }

    ($cycles | Select-Object -Unique)
}

function Test-WindowsBootstrapProfile {
    param([Parameter(Mandatory)][string]$BootstrapPath)
    $content = Get-Content -Raw -Path $BootstrapPath
    $issues = @()

    if ($content -notmatch 'DOTFILES_WINDOWS_BOOTSTRAP_LOADING') {
        $issues += New-DdIssue -Id 'bootstrap.guard' -Severity Error -Message 'Missing re-entry guard variable.' -File $BootstrapPath
    }
    if ($content -notmatch 'DOTFILES_ROOT') {
        $issues += New-DdIssue -Id 'bootstrap.root' -Severity Error -Message 'Does not set DOTFILES_ROOT.' -File $BootstrapPath
    }
    if ($content -notmatch 'PowerShell\\Microsoft\.PowerShell_profile\.ps1') {
        $issues += New-DdIssue -Id 'bootstrap.repo-profile' -Severity Error -Message 'Does not dot-source repo PowerShell profile.' -File $BootstrapPath
    }
    if ($content -notmatch 'Terminal-Icons') {
        $issues += New-DdIssue -Id 'bootstrap.terminal-icons' -Severity Warning -Message 'Terminal-Icons import not found in Windows bootstrap.' -File $BootstrapPath
    }

    $issues
}

function Test-WslRepoProfile {
    param([Parameter(Mandatory)][string]$RepoProfilePath)
    $content = Get-Content -Raw -Path $RepoProfilePath
    $issues = @()

    if ($content -notmatch 'DOTFILES_PWSH_PROFILE_LOADING') {
        $issues += New-DdIssue -Id 'repo.guard' -Severity Error -Message 'Missing DOTFILES_PWSH_PROFILE_LOADING guard.' -File $RepoProfilePath
    }
    if ($content -match 'Import-Module\s+Terminal-Icons') {
        $issues += New-DdIssue -Id 'repo.terminal-icons' -Severity Error -Message 'Terminal-Icons import found in WSL-side repo profile.' -File $RepoProfilePath
    }
    if ($content -match '\\\\wsl(?:\.localhost)?\\') {
        $issues += New-DdIssue -Id 'repo.unc-load' -Severity Warning -Message 'UNC path appears inside repo profile. Prefer DOTFILES_ROOT-relative paths.' -File $RepoProfilePath
    }

    $issues
}

function Test-PSModulePathByHost {
    param([string]$Distro = 'Ubuntu')
    $issues = @()
    $windowsParts = ($env:PSModulePath -split ';')
    if ($windowsParts -match 'OneDrive') {
        $issues += New-DdIssue -Id 'psmodulepath.windows.onedrive' -Severity Warning -Message 'Windows PSModulePath contains OneDrive entries.'
    }

    $wslValue = $null
    $wslParts = @()
    $wslCmd = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if ($wslCmd) {
        $raw = & wsl.exe -d $Distro -- pwsh -NoProfile -NonInteractive -Command '$env:PSModulePath' 2>$null
        $wslValue = ($raw | Out-String).Trim()
        if ($wslValue) { $wslParts = $wslValue -split ':' }
        if ($wslParts -match 'OneDrive|\\wsl\\|\\wsl\.localhost\\') {
            $issues += New-DdIssue -Id 'psmodulepath.wsl.contamination' -Severity Error -Message 'WSL PSModulePath contains Windows/UNC contamination.' -Data @{ Value = $wslValue }
        }
    } else {
        $issues += New-DdIssue -Id 'psmodulepath.wsl.skipped' -Severity Warning -Message 'wsl.exe not available; skipped WSL PSModulePath validation.'
    }

    [pscustomobject]@{
        Windows = $windowsParts
        WslRaw  = $wslValue
        Wsl     = $wslParts
        Issues  = $issues
    }
}

function Find-TerminalIconsOutsideBootstrap {
    param(
        [Parameter(Mandatory)][string]$RootPath,
        [Parameter(Mandatory)][string]$BootstrapPath
    )
    $issues = @()
    $files = Get-DotfilesTextFiles -RootPath $RootPath
    foreach ($f in $files) {
        if ((Resolve-Path $f.FullName).Path -eq (Resolve-Path $BootstrapPath).Path) { continue }
        $matches = Select-String -Path $f.FullName -Pattern 'Terminal-Icons' -SimpleMatch -ErrorAction SilentlyContinue
        foreach ($m in $matches) {
            $issues += New-DdIssue -Id 'terminal-icons.outside-windows' -Severity Error -Message 'Terminal-Icons reference outside Windows bootstrap profile.' -File $f.FullName -Line $m.LineNumber
        }
    }
    $issues
}

function Find-CrossHostContamination {
    param([Parameter(Mandatory)][string]$RootPath)
    $issues = @()
    $files = Get-DotfilesTextFiles -RootPath $RootPath
    foreach ($f in $files) {
        $matches = Select-String -Path $f.FullName -Pattern '[A-Za-z]:\\|\\\\wsl(?:\.localhost)?\\' -AllMatches -ErrorAction SilentlyContinue
        foreach ($m in $matches) {
            $issues += New-DdIssue -Id 'cross-host.path' -Severity Warning -Message 'Host-specific absolute path found; verify host-aware guard exists.' -File $f.FullName -Line $m.LineNumber
        }
    }
    $issues
}

function Invoke-DotfilesDoctorAudit {
    [CmdletBinding()]
    param(
        [string]$RootPath,
        [string]$BootstrapProfilePath,
        [string]$Distro = 'Ubuntu',
        [string]$OutputDir
    )

    $root = Resolve-DotfilesRoot -RootPath $RootPath -Distro $Distro
    $bootstrap = Resolve-WindowsBootstrapProfilePath -BootstrapProfilePath $BootstrapProfilePath
    $repoProfile = Get-DdRepoProfilePath -RootPath $root
    $dag = Build-ModuleDag -RootPath $root
    $cycles = Test-DagCycles -Dag $dag
    $issues = @()

    $issues += Test-WindowsBootstrapProfile -BootstrapPath $bootstrap
    if (Test-Path $repoProfile) {
        $issues += Test-WslRepoProfile -RepoProfilePath $repoProfile
    } else {
        $issues += New-DdIssue -Id 'repo.profile.missing' -Severity Error -Message 'WSL-side PowerShell profile missing.' -File $repoProfile
    }

    $psm = Test-PSModulePathByHost -Distro $Distro
    $issues += $psm.Issues
    $issues += Find-TerminalIconsOutsideBootstrap -RootPath $root -BootstrapPath $bootstrap
    $issues += Find-CrossHostContamination -RootPath $root

    foreach ($c in $cycles) { $issues += New-DdIssue -Id 'dag.cycle' -Severity Error -Message "Module loading cycle: $c" }

    $report = [pscustomobject]@{
        Timestamp        = (Get-Date).ToString('s')
        RootPath         = $root
        BootstrapProfile = $bootstrap
        RepoProfile      = $repoProfile
        Distro           = $Distro
        Dag              = $dag
        Issues           = $issues
        Summary          = [pscustomobject]@{
            Errors   = ($issues | Where-Object Severity -eq 'Error').Count
            Warnings = ($issues | Where-Object Severity -eq 'Warning').Count
            Infos    = ($issues | Where-Object Severity -eq 'Info').Count
        }
    }

    if ($OutputDir) {
        if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
        $jsonPath = Join-Path $OutputDir 'audit-report.json'
        $report | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding utf8
    }

    $report
}

function Get-ContentWithChanges {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string[]]$RemovePatterns,
        [string[]]$AppendBlock
    )
    $lines = Get-Content -Path $Path
    $newLines = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        $remove = $false
        foreach ($pat in $RemovePatterns) {
            if ($line -match $pat) { $remove = $true; break }
        }
        if (-not $remove) { $newLines.Add($line) | Out-Null }
    }
    if ($AppendBlock -and $AppendBlock.Count -gt 0) {
        $newLines.Add('') | Out-Null
        foreach ($l in $AppendBlock) { $newLines.Add($l) | Out-Null }
    }
    [string]::Join([Environment]::NewLine, $newLines)
}

function Get-TextDiff {
    param(
        [Parameter(Mandatory)][string]$OldText,
        [Parameter(Mandatory)][string]$NewText,
        [Parameter(Mandatory)][string]$Label
    )
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) { return "----- $Label (git not available, diff omitted) -----" }

    $tmp1 = [IO.Path]::GetTempFileName()
    $tmp2 = [IO.Path]::GetTempFileName()
    try {
        Set-Content -Path $tmp1 -Value $OldText -Encoding utf8
        Set-Content -Path $tmp2 -Value $NewText -Encoding utf8
        $diff = & git --no-pager diff --no-index -- $tmp1 $tmp2 2>$null
        if (-not $diff) { $diff = @("No changes for $Label") }
        ($diff -join [Environment]::NewLine)
    } finally {
        Remove-Item $tmp1,$tmp2 -ErrorAction SilentlyContinue
    }
}

function Invoke-DotfilesDoctorFix {
    [CmdletBinding()]
    param(
        [string]$RootPath,
        [string]$BootstrapProfilePath,
        [string]$Distro = 'Ubuntu',
        [switch]$Apply,
        [string]$ConfirmToken,
        [string]$OutputDir
    )

    $audit = Invoke-DotfilesDoctorAudit -RootPath $RootPath -BootstrapProfilePath $BootstrapProfilePath -Distro $Distro -OutputDir $OutputDir
    $bootstrap = $audit.BootstrapProfile
    $repoProfile = $audit.RepoProfile

    $removePatterns = @(
        'Import-Module\s+Terminal-Icons',
        'Import-Module\s+PSReadLine',
        'oh-my-posh.+init\s+pwsh'
    )
    $bootstrapBlock = @(
        '# Dotfiles Doctor: Windows-only module imports',
        'if ($IsWindows -and $PSVersionTable.PSEdition -eq ''Core'') {',
        '    if (Get-Module -ListAvailable -Name Terminal-Icons -ErrorAction SilentlyContinue) {',
        '        Import-Module Terminal-Icons -ErrorAction SilentlyContinue',
        '    }',
        '    if (Get-Module -ListAvailable -Name PSReadLine -ErrorAction SilentlyContinue) {',
        '        Import-Module PSReadLine -ErrorAction SilentlyContinue',
        '    }',
        '    $ompApp = Get-Command -Name oh-my-posh -CommandType Application -ErrorAction SilentlyContinue',
        '    if ($ompApp) {',
        '        & $ompApp.Source init pwsh | Invoke-Expression',
        '    }',
        '}'
    )

    $changes = @()

    if (Test-Path $repoProfile) {
        $old = Get-Content -Raw -Path $repoProfile
        $new = Get-ContentWithChanges -Path $repoProfile -RemovePatterns $removePatterns
        if ($old -ne $new) {
            $changes += [pscustomobject]@{
                Path = $repoProfile
                Old  = $old
                New  = $new
                Diff = Get-TextDiff -OldText $old -NewText $new -Label $repoProfile
            }
        }
    }

    if (Test-Path $bootstrap) {
        $bOld = Get-Content -Raw -Path $bootstrap
        $append = @()
        if ($bOld -notmatch 'Import-Module\s+Terminal-Icons') { $append = $bootstrapBlock }
        $bNew = if ($append.Count -gt 0) { ($bOld.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + ($append -join [Environment]::NewLine)) } else { $bOld }
        if ($bOld -ne $bNew) {
            $changes += [pscustomobject]@{
                Path = $bootstrap
                Old  = $bOld
                New  = $bNew
                Diff = Get-TextDiff -OldText $bOld -NewText $bNew -Label $bootstrap
            }
        }
    }

    foreach ($c in $changes) {
        Write-Host ''
        Write-Host "=== Proposed diff: $($c.Path) ===" -ForegroundColor Cyan
        Write-Host $c.Diff
    }

    if (-not $Apply) {
        Write-Host ''
        Write-Host 'Preview only. No files modified. Re-run with -Apply -ConfirmToken APPLY to write changes.' -ForegroundColor Yellow
        return [pscustomobject]@{ Apply = $false; Changes = $changes; Count = $changes.Count }
    }
    if ($ConfirmToken -ne 'APPLY') {
        throw 'Refusing to modify files. Explicit confirmation required: -Apply -ConfirmToken APPLY'
    }

    foreach ($c in $changes) {
        $backup = "$($c.Path).bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
        Copy-Item -Path $c.Path -Destination $backup -Force
        Set-Content -Path $c.Path -Value $c.New -Encoding utf8
    }

    $testReport = Invoke-DotfilesDoctorTest -RootPath $audit.RootPath -BootstrapProfilePath $bootstrap -Distro $Distro -OutputDir $OutputDir
    [pscustomobject]@{ Apply = $true; Changes = $changes; Test = $testReport }
}

function Invoke-DotfilesDoctorDocument {
    [CmdletBinding()]
    param(
        [string]$RootPath,
        [string]$BootstrapProfilePath,
        [string]$Distro = 'Ubuntu',
        [string]$OutputPath
    )

    $audit = Invoke-DotfilesDoctorAudit -RootPath $RootPath -BootstrapProfilePath $BootstrapProfilePath -Distro $Distro
    if (-not $OutputPath) { $OutputPath = Join-Path $audit.RootPath '.doctor\DOTFILES_DOCTOR_ARCHITECTURE.md' }
    $outDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

    $edgeLines = @()
    foreach ($e in $audit.Dag.Edges | Where-Object { $_.Target }) {
        $src = (Split-Path $e.Source -Leaf) -replace '[^A-Za-z0-9_]','_'
        $dst = (Split-Path $e.Target -Leaf) -replace '[^A-Za-z0-9_]','_'
        $edgeLines += "    $src --> $dst"
    }

    $md = @"
# Dotfiles Doctor Architecture Report

Generated: $(Get-Date -Format s)

## Architecture
- Windows bootstrap profile: `$($audit.BootstrapProfile)`
- WSL-side profile: `$($audit.RepoProfile)`
- Dotfiles root: `$($audit.RootPath)`

## Loader and Integration Pipeline
1. Windows bootstrap resolves `DOTFILES_ROOT` over UNC.
2. Windows bootstrap loads Windows-only modules.
3. Bootstrap dot-sources repo profile.
4. Repo profile calls `shell/integration.ps1`.
5. Integration invokes `shell/loader.ps1`.

## Host-Aware Branching
- Guard Windows behavior with `$IsWindows`.
- Do not load Windows-only modules from WSL profile.
- Prefer `DOTFILES_ROOT`-relative paths.

## Module-Loading Rules
- `Terminal-Icons` in bootstrap only.
- `PSReadLine` and `oh-my-posh` must be host-guarded.
- No hard-coded `C:\` module paths from WSL-side profile.

## Provisioning Rules
- Bootstrap profile generated by Windows setup flow.
- Repo profile owned by dotfiles repository.
- Keep installation and load ownership host-specific.

## Safe Modification Rules
1. Run `Invoke-DotfilesDoctor -Action Audit`.
2. Run `Invoke-DotfilesDoctor -Action Fix` for preview.
3. Apply only with explicit confirmation token.
4. Run `Invoke-DotfilesDoctor -Action Test`.

## Module DAG
```mermaid
graph TD
$($edgeLines -join "`n")
```

## Provisioning Flow
```mermaid
flowchart TD
    A[Windows pwsh starts] --> B[Bootstrap profile]
    B --> C[Set DOTFILES_ROOT]
    C --> D[Windows-only imports]
    D --> E[Dot-source repo profile]
    E --> F[integration.ps1]
    F --> G[loader.ps1]
```
"@

    Set-Content -Path $OutputPath -Value $md -Encoding utf8
    [pscustomobject]@{ OutputPath = $OutputPath; Audit = $audit }
}

function Invoke-DotfilesDoctorTest {
    [CmdletBinding()]
    param(
        [string]$RootPath,
        [string]$BootstrapProfilePath,
        [string]$Distro = 'Ubuntu',
        [string]$OutputDir
    )

    $root = Resolve-DotfilesRoot -RootPath $RootPath -Distro $Distro
    $bootstrap = Resolve-WindowsBootstrapProfilePath -BootstrapProfilePath $BootstrapProfilePath
    $repoProfile = Get-DdRepoProfilePath -RootPath $root
    $linuxRepoProfile = Convert-UncToLinuxPath -Path $repoProfile

    $winCmd = @"
`$Error.Clear()
. '$bootstrap'
`$mods = Get-Module | Select-Object -ExpandProperty Name
`$errs = `$Error | Select-Object -First 10 | ForEach-Object { `$_.Exception.Message }
[pscustomobject]@{ Modules=`$mods; Errors=`$errs } | ConvertTo-Json -Depth 5
"@
    $winJson = & pwsh -NoProfile -NonInteractive -Command $winCmd 2>$null
    try { $winResult = $winJson | ConvertFrom-Json } catch { $winResult = [pscustomobject]@{ Modules=@(); Errors=@('Windows sandbox parse failure') } }

    $wslResult = [pscustomobject]@{ Modules=@(); Errors=@(); Skipped=$false }
    $wslCmd = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if ($wslCmd) {
        $wslScript = @"
`$Error.Clear()
. '$linuxRepoProfile'
`$mods = Get-Module | Select-Object -ExpandProperty Name
`$errs = `$Error | Select-Object -First 10 | ForEach-Object { `$_.Exception.Message }
[pscustomobject]@{ Modules=`$mods; Errors=`$errs } | ConvertTo-Json -Depth 5
"@
        $wslJson = & wsl.exe -d $Distro -- pwsh -NoProfile -NonInteractive -Command $wslScript 2>$null
        try { $wslResult = $wslJson | ConvertFrom-Json } catch { $wslResult = [pscustomobject]@{ Modules=@(); Errors=@('WSL sandbox parse failure'); Skipped=$false } }
    } else {
        $wslResult = [pscustomobject]@{ Modules=@(); Errors=@('wsl.exe unavailable'); Skipped=$true }
    }

    $audit = Invoke-DotfilesDoctorAudit -RootPath $root -BootstrapProfilePath $bootstrap -Distro $Distro
    $checks = @(
        [pscustomobject]@{ Name='RecursionCycles'; Pass=(($audit.Issues | Where-Object Id -eq 'dag.cycle').Count -eq 0) },
        [pscustomobject]@{ Name='NoUNCInWslProfile'; Pass=(($audit.Issues | Where-Object Id -eq 'repo.unc-load').Count -eq 0) },
        [pscustomobject]@{ Name='NoTerminalIconsInWSL'; Pass=(-not ($wslResult.Modules -contains 'Terminal-Icons')) },
        [pscustomobject]@{ Name='WindowsStartupNoErrors'; Pass=($winResult.Errors.Count -eq 0) },
        [pscustomobject]@{ Name='WslStartupNoErrors'; Pass=($wslResult.Errors.Count -eq 0 -or $wslResult.Skipped) }
    )

    $report = [pscustomobject]@{
        Timestamp = (Get-Date).ToString('s')
        RootPath  = $root
        Checks    = $checks
        Windows   = $winResult
        WSL       = $wslResult
        Pass      = (($checks | Where-Object { -not $_.Pass }).Count -eq 0)
    }

    if ($OutputDir) {
        if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
        $json = Join-Path $OutputDir 'test-report.json'
        $md = Join-Path $OutputDir 'test-report.md'
        $report | ConvertTo-Json -Depth 8 | Set-Content -Path $json -Encoding utf8
        @"
# Dotfiles Doctor Test Report
Generated: $(Get-Date -Format s)

Overall: $(if ($report.Pass) { 'PASS' } else { 'FAIL' })

## Checks
$(
    ($report.Checks | ForEach-Object { "- $($_.Name): $(if ($_.Pass) { 'PASS' } else { 'FAIL' })" }) -join "`n"
)
"@ | Set-Content -Path $md -Encoding utf8
    }

    $report
}

function Invoke-DotfilesDoctor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Audit','Fix','Document','Test')][string]$Action,
        [string]$RootPath,
        [string]$BootstrapProfilePath,
        [string]$Distro = 'Ubuntu',
        [string]$OutputDir = '.doctor',
        [string]$OutputPath,
        [switch]$Apply,
        [string]$ConfirmToken
    )

    switch ($Action) {
        'Audit'    { Invoke-DotfilesDoctorAudit -RootPath $RootPath -BootstrapProfilePath $BootstrapProfilePath -Distro $Distro -OutputDir $OutputDir; break }
        'Fix'      { Invoke-DotfilesDoctorFix -RootPath $RootPath -BootstrapProfilePath $BootstrapProfilePath -Distro $Distro -Apply:$Apply -ConfirmToken $ConfirmToken -OutputDir $OutputDir; break }
        'Document' { Invoke-DotfilesDoctorDocument -RootPath $RootPath -BootstrapProfilePath $BootstrapProfilePath -Distro $Distro -OutputPath $OutputPath; break }
        'Test'     { Invoke-DotfilesDoctorTest -RootPath $RootPath -BootstrapProfilePath $BootstrapProfilePath -Distro $Distro -OutputDir $OutputDir; break }
    }
}

