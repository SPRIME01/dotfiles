#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Defaults that mirror the shared shell helpers but allow overrides.
DEFAULT_VENV="${OPENVINO_GENAI_VENV:-/opt/openvino-genai/venv}"
DEFAULT_MODELS_DIR="${OPENVINO_GENAI_MODELS_DIR:-/opt/openvino-genai/models}"
DEFAULT_CACHE_DIR="${HUGGINGFACE_HUB_CACHE:-/opt/openvino-genai/cache}"
DEFAULT_REQUIREMENTS="${REPO_ROOT}/docs/reference/openvino-genai/requirements.lock"

TORCH_VERSION="2.4.1"
TORCH_INDEX_URL="https://download.pytorch.org/whl/cpu"

PACKAGES=(
	"numpy==1.26.4"
	"openvino==2024.6.0"
	"openvino-dev==2024.6.0"
	"openvino-genai==2024.6.0.0"
	"openvino-tokenizers==2024.6.0.0"
	"optimum-intel==1.15.0"
	"optimum==1.27.0"
	"transformers==4.56.2"
	"accelerate==1.10.1"
	"huggingface-hub==0.35.1"
	"pillow==11.3.0"
	"fastapi==0.117.1"
	"uvicorn==0.37.0"
	"rich==14.1.0"
	"ollama==0.6.0"
	"datasets==4.1.1"
	"scipy==1.16.2"
	"psutil==7.1.0"
	"sentencepiece==0.2.1"
)

DRY_RUN=0
NO_FREEZE=0
SKIP_OLLAMA=0
CUSTOM_VENV=""
CUSTOM_MODELS=""
CUSTOM_CACHE=""

print_usage() {
	cat <<'EOF'
Usage: scripts/setup-openvino-genai.sh [options]

Options:
  --venv PATH           Override the virtualenv location (default /opt/openvino-genai/venv)
  --models PATH         Override the models directory (default /opt/openvino-genai/models)
  --cache PATH          Override the Hugging Face cache directory (default /opt/openvino-genai/cache)
  --dry-run             Show planned actions without making changes
  --no-freeze           Skip writing docs/reference/openvino-genai/requirements.lock
  --skip-ollama-check   Do not attempt to detect or verify Ollama service state
  -h, --help            Show this message

Examples:
  scripts/setup-openvino-genai.sh
  scripts/setup-openvino-genai.sh --dry-run
  scripts/setup-openvino-genai.sh --venv "$HOME/.virtualenvs/openvino"
EOF
}

action() {
	local icon="$1"
	shift
	printf '%b %s\n' "$icon" "$*"
}

warn() {
	action "⚠️" "$*" >&2
}

ensure_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		warn "Missing required command: $1"
		warn "Install the command or adjust your PATH, then re-run this setup"
		exit 1
	fi
}

run_or_print() {
	if ((DRY_RUN)); then
		printf '[dry-run] %s\n' "$*"
		return 0
	fi
	"$@"
}

maybe_sudo() {
	if "$@" 2>/dev/null; then
		return 0
	fi
	if command -v sudo >/dev/null 2>&1; then
		if ((DRY_RUN)); then
			printf '[dry-run] sudo %s\n' "$*"
			return 0
		fi
		sudo "$@"
	else
		warn "Need elevated privileges for: $*"
		warn "Please re-run this script with sufficient permissions."
		exit 1
	fi
}

ensure_directory() {
	local path="$1"
	if ((DRY_RUN)); then
		printf '[dry-run] mkdir -p %s\n' "$path"
		printf '[dry-run] chown %s:%s %s\n' "$USER" "$USER" "$path"
		return 0
	fi
	if [[ ! -d "$path" ]]; then
		maybe_sudo mkdir -p "$path"
	fi
	maybe_sudo chown "$USER":"$USER" "$path"
}

ensure_venv_permissions() {
	local path="$1"
	if [[ -z "$path" ]]; then
		return
	fi
	if ((DRY_RUN)); then
		printf '[dry-run] chown -R %s:%s %s\n' "$USER" "$USER" "$path"
		return
	fi
	maybe_sudo chown -R "$USER":"$USER" "$path"
}

prune_gpu_wheels() {
	if ((DRY_RUN)); then
		printf '[dry-run] pip list --format=freeze | grep "^nvidia-" | cut -d= -f1 | xargs -r pip uninstall -y\n'
		printf '[dry-run] pip uninstall -y triton || true\n'
		return
	fi
	local gpu_packages
	gpu_packages="$(pip list --format=freeze | grep '^nvidia-' | cut -d= -f1 | tr '\n' ' ' || true)"
	if [[ -n "${gpu_packages// /}" ]]; then
		# shellcheck disable=SC2086 # intentional word splitting for package list
		pip uninstall -y ${gpu_packages}
	fi
	pip uninstall -y triton >/dev/null 2>&1 || true
}

ollama_status() {
	if ((SKIP_OLLAMA)); then
		echo "skipped"
		return 0
	fi
	if ! command -v ollama >/dev/null 2>&1; then
		echo "missing"
		return 0
	fi
	if ollama list >/dev/null 2>&1; then
		echo "running"
	else
		echo "installed"
	fi
}

# -------- argument parsing --------
while [[ $# -gt 0 ]]; do
	case "$1" in
	--venv)
		CUSTOM_VENV="$2"
		shift 2 || true
		;;
	--models)
		CUSTOM_MODELS="$2"
		shift 2 || true
		;;
	--cache)
		CUSTOM_CACHE="$2"
		shift 2 || true
		;;
	--dry-run)
		DRY_RUN=1
		shift
		;;
	--no-freeze)
		NO_FREEZE=1
		shift
		;;
	--skip-ollama-check)
		SKIP_OLLAMA=1
		shift
		;;
	-h | --help)
		print_usage
		exit 0
		;;
	*)
		warn "Unknown option: $1"
		print_usage
		exit 2
		;;
	esac
done

VENV_PATH="${CUSTOM_VENV:-$DEFAULT_VENV}"
MODELS_DIR="${CUSTOM_MODELS:-$DEFAULT_MODELS_DIR}"
CACHE_DIR="${CUSTOM_CACHE:-$DEFAULT_CACHE_DIR}"

ensure_command python3
ensure_command bash

if ((!DRY_RUN)); then
	mkdir -p "${REPO_ROOT}/docs/reference/openvino-genai" 2>/dev/null || true
fi

action "🚀" "Preparing OpenVINO GenAI environment"
action "•" "Virtualenv: $VENV_PATH"
action "•" "Models dir: ${MODELS_DIR}"
action "•" "Cache dir: ${CACHE_DIR}"

ensure_directory "${MODELS_DIR}"
ensure_directory "${CACHE_DIR}"

if [[ ! -d "$VENV_PATH" ]]; then
	action "⚙️" "Creating virtualenv at $VENV_PATH"
	run_or_print python3 -m venv "$VENV_PATH"
else
	action "ℹ️" "Using existing virtualenv at $VENV_PATH"
fi

ensure_venv_permissions "$VENV_PATH"

if ((!DRY_RUN)); then
	# shellcheck source=/dev/null
	source "$VENV_PATH/bin/activate"
fi

if ((DRY_RUN)); then
	printf '[dry-run] source %s/bin/activate\n' "$VENV_PATH"
fi

action "📦" "Installing/updating Python packages"
if ((DRY_RUN)); then
	printf '[dry-run] pip install --upgrade pip setuptools wheel\n'
	printf '[dry-run] # Remove CUDA wheels left from older installs\n'
	prune_gpu_wheels
	printf '[dry-run] pip install --index-url %s "torch==%s"\n' "$TORCH_INDEX_URL" "$TORCH_VERSION"
	printf '[dry-run] pip install %s\n' "${PACKAGES[*]}"
else
	pip install --upgrade pip setuptools wheel
	prune_gpu_wheels
	pip install --index-url "$TORCH_INDEX_URL" "torch==${TORCH_VERSION}"
	pip install "${PACKAGES[@]}"
fi

if ((!NO_FREEZE)); then
	action "📝" "Writing requirements snapshot to ${DEFAULT_REQUIREMENTS}"
	if ((DRY_RUN)); then
		printf '[dry-run] pip list --format=freeze > %s\n' "$DEFAULT_REQUIREMENTS"
	else
		pip list --format=freeze >"$DEFAULT_REQUIREMENTS"
	fi
else
	action "⏭️" "Skipping requirements snapshot (--no-freeze supplied)"
fi

OLLAMA_STATE="$(ollama_status)"
case "$OLLAMA_STATE" in
running)
	action "✅" "Ollama service detected and responding"
	;;
installed)
	action "ℹ️" "Ollama CLI found but service is not responding"
	warn "Start the Ollama service (e.g. 'ollama serve' or via systemctl) so clients can connect."
	;;
missing)
	action "ℹ️" "Ollama CLI not found"
	warn "Install Ollama on the host (https://ollama.com/download) and re-run if you plan to orchestrate models through it."
	;;
skipped)
	action "ℹ️" "Ollama detection skipped"
	;;
esac

if ((!DRY_RUN)); then
	cat <<EOF

✨ OpenVINO GenAI environment is ready.
- Activate:   source "${VENV_PATH}/bin/activate"  (or run 'openvino_genai_activate')
- Python:     openvino_genai_python my_script.py
- Pip:        openvino_genai_pip install <package>
- Snapshot:   just openvino-freeze-reqs

Pro tip: run 'just openvino-info' to view a live status report.
EOF
else
	action "👀" "Dry-run complete. Re-run without --dry-run to apply changes."
fi
