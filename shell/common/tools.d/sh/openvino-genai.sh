# shellcheck shell=bash
# OpenVINO GenAI helpers that keep activation optional while staying consistent
# across bash, zsh, and non-interactive runners.

# Allow overrides via OPENVINO_GENAI_VENV; fall back to the canonical install.
if [[ -z ${OPENVINO_GENAI_VENV:-} ]]; then
	OPENVINO_GENAI_VENV="/opt/openvino-genai/venv"
fi

# Default model/cache directories can also be overridden per host.
if [[ -z ${OPENVINO_GENAI_MODELS_DIR:-} && -d /opt/openvino-genai/models ]]; then
	OPENVINO_GENAI_MODELS_DIR="/opt/openvino-genai/models"
fi
if [[ -z ${HUGGINGFACE_HUB_CACHE:-} && -d /opt/openvino-genai/cache ]]; then
	export HUGGINGFACE_HUB_CACHE="/opt/openvino-genai/cache"
fi

# Export the discovered values so child shells inherit them.
export OPENVINO_GENAI_VENV
if [[ -n ${OPENVINO_GENAI_MODELS_DIR:-} ]]; then
	export OPENVINO_GENAI_MODELS_DIR
fi

OPENVINO_GENAI_DEFAULT_OLLAMA_HOST="${OPENVINO_GENAI_DEFAULT_OLLAMA_HOST:-http://127.0.0.1:11434}"

openvino_genai_refresh_ollama_status() {
	local status="missing"
	if command -v ollama >/dev/null 2>&1; then
		if ollama list >/dev/null 2>&1; then
			status="running"
		else
			status="installed"
		fi
	fi
	OPENVINO_GENAI_OLLAMA_STATUS="$status"
	export OPENVINO_GENAI_OLLAMA_STATUS
}

openvino_genai_maybe_set_ollama_host() {
	if [[ ${OPENVINO_GENAI_OLLAMA_STATUS:-missing} == "running" && -z ${OLLAMA_HOST:-} ]]; then
		export OLLAMA_HOST="$OPENVINO_GENAI_DEFAULT_OLLAMA_HOST"
	fi
}

openvino_genai_validate_runtime() {
	if [[ -n ${__OPENVINO_GENAI_IMPORT_CHECKED:-} ]]; then
		return 0
	fi
	__OPENVINO_GENAI_IMPORT_CHECKED=1
	python - <<'PY' >/dev/null 2>&1
import importlib
import sys

for module in ("openvino_genai", "transformers", "huggingface_hub"):
    try:
        importlib.import_module(module)
    except ModuleNotFoundError:
        sys.exit(1)
sys.exit(0)
PY
	if [[ $? -ne 0 ]]; then
		echo "⚠️  OpenVINO GenAI environment is missing packages. Run 'just openvino-setup' to provision." >&2
	fi
}

openvino_genai_venv_path() {
	printf '%s\n' "${OPENVINO_GENAI_VENV:-/opt/openvino-genai/venv}"
}

openvino_genai_activate() {
	local venv activate
	venv="$(openvino_genai_venv_path)" || return 1
	activate="$venv/bin/activate"
	if [[ ! -f "$activate" ]]; then
		echo "OpenVINO GenAI activate script not found: $activate" >&2
		return 1
	fi
	if [[ ${VIRTUAL_ENV:-} == "$venv" ]]; then
		return 0
	fi
	# shellcheck disable=SC1091
	source "$activate"
	openvino_genai_refresh_ollama_status
	openvino_genai_maybe_set_ollama_host
	openvino_genai_validate_runtime
}

openvino_genai_deactivate() {
	if [[ -n ${VIRTUAL_ENV:-} ]]; then
		deactivate 2>/dev/null || true
	fi
}

openvino_genai_python() {
	openvino_genai_activate || return $?
	python "$@"
}

openvino_genai_pip() {
	openvino_genai_activate || return $?
	pip "$@"
}

openvino_genai_info() {
	local venv
	venv="$(openvino_genai_venv_path)" || return 1
	echo "🔍 OpenVINO GenAI environment"
	echo "  • venv: $venv"
	if [[ -f "$venv/bin/python" ]]; then
		local py_version
		py_version=$("$venv/bin/python" --version 2>&1 || true)
		echo "  • python: ${py_version:-unavailable}"
	else
		echo "  • python: missing" >&2
	fi
	openvino_genai_refresh_ollama_status
	case "${OPENVINO_GENAI_OLLAMA_STATUS:-missing}" in
		running)
			echo "  • ollama: running (host: ${OLLAMA_HOST:-$OPENVINO_GENAI_DEFAULT_OLLAMA_HOST})"
			;;
		installed)
			echo "  • ollama: installed (service not responding)"
			;;
		*)
			echo "  • ollama: not installed"
			;;
	esac
	if command -v ovc_info >/dev/null 2>&1; then
		echo "  • ovc_info: $(ovc_info --version)"
	fi
	if [[ -n ${OPENVINO_GENAI_MODELS_DIR:-} ]]; then
		echo "  • models dir: $OPENVINO_GENAI_MODELS_DIR"
	fi
	if [[ -n ${HUGGINGFACE_HUB_CACHE:-} ]]; then
		echo "  • HF cache: $HUGGINGFACE_HUB_CACHE"
	fi
}
