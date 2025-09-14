#!/usr/bin/env bash
set -euo pipefail

# Optional: --file <path> to override the target .env file
ENV_FILE=""
if [[ "${1:-}" == "--file" || "${1:-}" == "-f" ]]; then
  shift
  ENV_FILE="${1:-}"
  shift || true
fi

# Default to repo .env (based on this script's location)
if [[ -z "${ENV_FILE}" ]]; then
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  ENV_FILE="$ROOT/.env"
fi

usage() {
  cat <<EOF
Usage:
  envctl.sh [ENV_FILE] add KEY VALUE     # Add or update key
  envctl.sh [ENV_FILE] add KEY=VALUE     # Alternative form
  envctl.sh [ENV_FILE] add KEY:VALUE     # Alternative form
  envctl.sh [ENV_FILE] remove KEY        # Remove key
  envctl.sh [ENV_FILE] get KEY           # Print value (if set)
  envctl.sh [ENV_FILE] list              # List all key=value pairs

Notes:
  - Creates ENV_FILE if it doesn't exist (0600 perms)
  - Lines starting with # are preserved and ignored
  - Keys must match ^[A-Za-z_][A-Za-z0-9_]*$
EOF
}

ensure_file() {
  if [[ ! -f "$ENV_FILE" ]]; then
    umask 077
    printf "# Dotfiles environment\n# Managed with scripts/envctl.sh\n" >"$ENV_FILE"
  fi
  # Enforce secure permissions (600) to avoid leaking secrets
  if command -v stat >/dev/null 2>&1; then
    perms=$(stat -c '%a' "$ENV_FILE" 2>/dev/null || stat -f '%Lp' "$ENV_FILE" 2>/dev/null || echo '')
    if [[ -n "$perms" && "$perms" != "600" ]]; then
      chmod 600 "$ENV_FILE" 2>/dev/null || true
    fi
  else
    chmod 600 "$ENV_FILE" 2>/dev/null || true
  fi
}

valid_key() {
  [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]
}

parse_kv() {
  local rawK="$1" rawV="${2:-}"
  if [[ "$rawK" == *"="* ]]; then
    KEY_OUT="${rawK%%=*}"; VAL_OUT="${rawK#*=}"
  elif [[ "$rawK" == *":"* && -z "$rawV" ]]; then
    KEY_OUT="${rawK%%:*}"; VAL_OUT="${rawK#*:}"
  else
    KEY_OUT="$rawK"; VAL_OUT="$rawV"
  fi
}

cmd="${1:-}"; shift || true
case "$cmd" in
  add)
    ensure_file
    parse_kv "${1:-}" "${2:-}"
    key="$KEY_OUT"; value="$VAL_OUT"
    if [[ -z "${key:-}" || -z "${value:-}" ]]; then echo "❌ Usage: add KEY VALUE|KEY=VALUE|KEY:VALUE" >&2; exit 2; fi
    if ! valid_key "$key"; then echo "❌ Invalid key: $key" >&2; exit 2; fi
    value="$(printf '%s' "$value" | sed -e 's/^\s*//' -e 's/\s*$//')"
    tmp="${ENV_FILE}.tmp.$$"
    awk -v K="$key" -v V="$value" '
      BEGIN{updated=0}
      /^[[:space:]]*#/ { print; next }
      /^[[:space:]]*$/ { print; next }
      { if ($0 ~ "^"K"=") { if (!updated) { print K"="V; updated=1 } } else { print } }
      END { if (!updated) print K"="V }
    ' "$ENV_FILE" > "$tmp"
    mv "$tmp" "$ENV_FILE"
    echo "✅ Set $key"
    ;;
  remove)
    ensure_file
    key="${1:-}"; if [[ -z "$key" ]]; then echo "❌ Usage: remove KEY" >&2; exit 2; fi
    if ! valid_key "$key"; then echo "❌ Invalid key: $key" >&2; exit 2; fi
    tmp="${ENV_FILE}.tmp.$$"
    awk -v K="$key" '
      /^[[:space:]]*#/ { print; next }
      !($0 ~ "^"K"=") { print }
    ' "$ENV_FILE" > "$tmp"
    mv "$tmp" "$ENV_FILE"
    echo "🗑️  Removed $key (if present)"
    ;;
  get)
    ensure_file
    key="${1:-}"; if [[ -z "$key" ]]; then echo "❌ Usage: get KEY" >&2; exit 2; fi
    if ! valid_key "$key"; then echo "❌ Invalid key: $key" >&2; exit 2; fi
    grep -E "^${key}=" "$ENV_FILE" | sed -E "s/^${key}=//" || true
    ;;
  list)
    ensure_file
    # List only key=value non-comment lines
    grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$ENV_FILE" || true
    ;;
  ""|-h|--help|help)
    usage; exit 0 ;;
  *)
    echo "❌ Unknown command: $cmd" >&2
    usage; exit 2 ;;
esac

# Trigger direnv reload if available and we are in the repo root
if command -v direnv >/dev/null 2>&1; then
  # Best-effort: only reload if PWD contains the env file to avoid noisy reloads
  if [[ "$(cd "$(dirname "$ENV_FILE")" && pwd)" == "$(pwd)" ]]; then
    direnv reload >/dev/null 2>&1 || true
  fi
fi
