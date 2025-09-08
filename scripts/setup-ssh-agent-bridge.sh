#!/usr/bin/env bash
# NOTE: This file can be sourced from interactive shells (bash/zsh).
# It must never terminate the parent shell. Avoid `exit` on error paths.
# Be defensive and quietly no-op when prerequisites aren't met.

# Try to enable safer mode when executed directly, but keep it gentle when sourced.
# Detect if sourced (bash or zsh) and current shell type.
_is_sourced=0
if [ "${BASH_SOURCE:-$0}" != "$0" ]; then _is_sourced=1; fi
if [ -n "${ZSH_EVAL_CONTEXT:-}" ] && [[ $ZSH_EVAL_CONTEXT == *:file* ]]; then _is_sourced=1; fi

# In direct execution, prefer strict mode. When sourced, do not modify shell options.
if [ $_is_sourced -eq 0 ]; then
  set -euo pipefail
fi

# Hardened WSL SSH agent bridge launcher.
# - Avoids reliance on current working directory
# - Uses a stable UNIX socket path
# - Waits for /mnt/c to be available
# - Allows overriding npiperelay.exe path via $NPIPERELAY_PATH

_log_prefix="[ssh-agent-bridge]"

# Only run in WSL2/WSL environments. Otherwise, silently return.
_is_wsl=0
if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then _is_wsl=1; fi
if [ $_is_wsl -ne 1 ]; then
  # Not WSL — nothing to do.
  return 0 2>/dev/null || exit 0
fi

# Choose socket base: XDG runtime if available, else ~/.ssh. Do not export yet.
if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
  _sock_base="$XDG_RUNTIME_DIR"
else
  _sock_base="$HOME/.ssh"
fi

_target_sock="${SSH_AUTH_SOCK:-${_sock_base}/ssh-agent-bridge.sock}"
_target_dir="$(dirname "$_target_sock")"
mkdir -p "$_target_dir" 2>/dev/null || true

# Ensure /mnt/c is available (WSL DrvFS) before attempting to call npiperelay
for _i in $(seq 1 30); do
  if [[ -d /mnt/c/Windows ]]; then
    break
  fi
  sleep 0.2
done

if [[ ! -d /mnt/c/Windows ]]; then
  echo "$_log_prefix /mnt/c is not available. Skipping bridge startup." >&2
  return 0 2>/dev/null || exit 0
fi

# Locate npiperelay.exe (prefer local manifest, then env, then known locations)

# Try local WSL manifest first (written by install-wsl-agent-bridge.sh)
_wsl_manifest="$HOME/.ssh/bridge-manifest.wsl.json"
if [[ -z "${NPIPERELAY_PATH:-}" && -f "$_wsl_manifest" ]]; then
  if command -v jq >/dev/null 2>&1; then
    _np_from_manifest=$(jq -r '.npiperelay_wsl // empty' "$_wsl_manifest" 2>/dev/null || true)
    _sock_from_manifest=$(jq -r '.agent_sock // empty' "$_wsl_manifest" 2>/dev/null || true)
  else
    _np_from_manifest=$(grep -oE '"npiperelay_wsl"\s*:\s*"[^"]+"' "$_wsl_manifest" | sed -E 's/.*:"([^"]+)"/\1/' )
    _sock_from_manifest=$(grep -oE '"agent_sock"\s*:\s*"[^"]+"' "$_wsl_manifest" | sed -E 's/.*:"([^"]+)"/\1/' )
  fi
  if [[ -n "${_np_from_manifest:-}" ]]; then NPIPERELAY_PATH="$_np_from_manifest"; fi
  if [[ -n "${_sock_from_manifest:-}" ]]; then _target_sock="$_sock_from_manifest"; fi
fi

# Fallbacks: env overrides (support NPIPERELAY and NPIPERELAY_PATH)
if [[ -z "${NPIPERELAY_PATH:-}" && -n "${NPIPERELAY:-}" ]]; then
  NPIPERELAY_PATH="$NPIPERELAY"
fi

# Known installation paths last
_npipercand=( )
if [[ -n "${NPIPERELAY_PATH:-}" ]]; then _npipercand+=("$NPIPERELAY_PATH"); fi
_npipercand+=('/mnt/c/ProgramData/chocolatey/bin/npiperelay.exe')
_npipercand+=('/mnt/c/tools/npiperelay/npiperelay.exe')
_npipercand+=('/mnt/c/Windows/System32/npiperelay.exe')
_npipercand+=('/mnt/c/Users/'"${WINUSER:-}"'/scoop/shims/npiperelay.exe')
_npipercand+=('/mnt/c/Users/'"$(whoami)"'/scoop/shims/npiperelay.exe')

for p in "${_npipercand[@]}"; do
  if [[ -f "$p" ]]; then NPIPERELAY_PATH="$p"; break; fi
done

if [[ -z "$NPIPERELAY_PATH" ]]; then
  echo "$_log_prefix npiperelay.exe not found. Set NPIPERELAY_PATH or install npiperelay. Skipping bridge startup." >&2
  return 0 2>/dev/null || exit 0
fi

# Require socat
if ! command -v socat >/dev/null 2>&1; then
  echo "$_log_prefix socat not found. Install socat to enable SSH agent bridge." >&2
  return 0 2>/dev/null || exit 0
fi

# If a socket already exists at target and is a UNIX socket, trust it and export.
if [[ -S "$_target_sock" ]]; then
  export SSH_AUTH_SOCK="$_target_sock"
  return 0 2>/dev/null || exit 0
fi

# Remove any stale non-socket file before creating listener
rm -f "$_target_sock" 2>/dev/null || true

# Start the bridge: UNIX socket <-> Windows OpenSSH agent named pipe
# Use unlink-close and restricted umask
setsid nohup \
  socat UNIX-LISTEN:"$_target_sock",fork,unlink-close,umask=007 \
        EXEC:"\"$NPIPERELAY_PATH\" -ei -s //./pipe/openssh-ssh-agent" \
  >/dev/null 2>&1 &

export SSH_AUTH_SOCK="$_target_sock"
echo "$_log_prefix started at $SSH_AUTH_SOCK"
