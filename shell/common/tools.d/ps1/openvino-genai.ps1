# OpenVINO GenAI helpers for PowerShell sessions.
# Keeps activation optional but readily available across Windows terminals.

if (-not $env:OPENVINO_GENAI_VENV) {
    $env:OPENVINO_GENAI_VENV = '/opt/openvino-genai/venv'
}

if (-not $env:OPENVINO_GENAI_MODELS_DIR) {
    $modelsPath = '/opt/openvino-genai/models'
    if (Test-Path -LiteralPath $modelsPath) {
        $env:OPENVINO_GENAI_MODELS_DIR = $modelsPath
    }
}

if (-not $env:HUGGINGFACE_HUB_CACHE) {
    $cachePath = '/opt/openvino-genai/cache'
    if (Test-Path -LiteralPath $cachePath) {
        $env:HUGGINGFACE_HUB_CACHE = $cachePath
    }
}

$env:OPENVINO_GENAI_DEFAULT_OLLAMA_HOST = $env:OPENVINO_GENAI_DEFAULT_OLLAMA_HOST ?? 'http://127.0.0.1:11434'

function Get-OpenvinoGenaiOllamaStatus {
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        return 'missing'
    }
    try {
        ollama list | Out-Null
        return 'running'
    } catch {
        return 'installed'
    }
}

function Set-OpenvinoGenaiOllamaHost {
    param(
        [string]$Status
    )

    if ($Status -eq 'running' -and [string]::IsNullOrEmpty($env:OLLAMA_HOST)) {
        $env:OLLAMA_HOST = $env:OPENVINO_GENAI_DEFAULT_OLLAMA_HOST
    }
}

function Test-OpenvinoGenaiRuntime {
    if ($script:OpenvinoGenaiRuntimeChecked) {
        return
    }
    $script:OpenvinoGenaiRuntimeChecked = $true

    $check = @"
import importlib.util, sys
modules = (
    'openvino_genai',
    'transformers',
    'huggingface_hub',
)
missing = [m for m in modules if importlib.util.find_spec(m) is None]
sys.exit(1 if missing else 0)
"@

    try {
        python -c $check | Out-Null
    } catch {
        Write-Warning "OpenVINO GenAI Python packages missing. Run 'just openvino-setup' to provision them."
    }
}

function Enter-OpenvinoGenai {
    $venv = $env:OPENVINO_GENAI_VENV
    if (-not $venv) {
        Write-Warning 'OPENVINO_GENAI_VENV is not set.'
        return
    }

    $activate = Join-Path $venv 'bin/activate.ps1'
    if (-not (Test-Path -LiteralPath $activate)) {
        Write-Warning "Activate script not found at $activate"
        return
    }

    if ($env:VIRTUAL_ENV -eq $venv) {
        return
    }

    . $activate

    $status = Get-OpenvinoGenaiOllamaStatus
    Set-OpenvinoGenaiOllamaHost -Status $status
    $env:OPENVINO_GENAI_OLLAMA_STATUS = $status
    Test-OpenvinoGenaiRuntime
}

function Exit-OpenvinoGenai {
    if (Get-Command -Name deactivate -ErrorAction SilentlyContinue) {
        deactivate
    }
}

function Invoke-OpenvinoGenaiPython {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    Enter-OpenvinoGenai
    if (-not $?) { return }
    & python @Args
}

if (-not (Get-Command ovg -ErrorAction SilentlyContinue)) {
    Set-Alias -Name ovg -Value Enter-OpenvinoGenai
}
