#!/usr/bin/env bash
# common.sh — Shared helpers for ssh-agent-bridge scripts
# Safe to source multiple times.
# Provides:
#   detect_windows_user
#   to_wsl_path <path>
#   read_manifest_field <manifest_path> <json_field>
#   state_summary_tsv <state_file>
#   state_list_failures_tsv <state_file>
#   ssh_bridge_log <level> <message>
#   ssh_bridge_dbg <message>
# Controls:
#   SSH_BRIDGE_VERBOSE=1 enables DEBUG logs
#   SSH_BRIDGE_QUIET=1 suppresses INFO (errors still print)

set -euo pipefail

ssh_bridge_log() {
  local level="$1"; shift || true
  local msg="$*"
  if [[ "${SSH_BRIDGE_QUIET:-0}" == "1" && "$level" == "INFO" ]]; then return 0; fi
  local ts; ts=$(date -Is)
  printf '[%s] [%s] %s\n' "$ts" "$level" "$msg"
}

ssh_bridge_dbg() { [[ "${SSH_BRIDGE_VERBOSE:-0}" == "1" ]] && ssh_bridge_log DEBUG "$*" || true; }

# Attempt to detect the Windows username when running inside WSL.
detect_windows_user() {
  local u="";
  if command -v powershell.exe >/dev/null 2>&1; then
    u=$(powershell.exe -NoProfile -NonInteractive -Command '$env:UserName' 2>/dev/null | tr -d '\r' | tail -n1 || true)
  fi
  if [[ -z "$u" ]]; then
    # Fallback heuristic: prefer directory matching current $USER
    if [[ -d "/mnt/c/Users/${USER}" ]]; then
      u="$USER"
    else
      while IFS= read -r d; do
        case "$d" in
          'All Users'|'Default'|'Default User'|'Public'|'WDAGUtilityAccount') continue;;
        esac
        if [[ -d "/mnt/c/Users/$d" ]]; then u="$d"; break; fi
      done < <(ls -1 /mnt/c/Users 2>/dev/null || true)
    fi
  fi
  [[ -n "$u" ]] && printf '%s\n' "$u"
}

to_wsl_path() { # convert C:\path to /mnt/c/path
  local p="$1"
  if [[ "$p" =~ ^[A-Za-z]:\\\\ ]]; then
    local d="${p:0:1}"; d="${d,,}"
    local rest="${p:2}"; rest="${rest//\\/\/}"
    printf '/mnt/%s/%s\n' "$d" "$rest"
  else
    printf '%s\n' "$p"
  fi
}

read_manifest_field() { # manifest, field
  local manifest="$1" field="$2"
  [[ -f "$manifest" ]] || return 1
  local val=""
  if command -v jq >/dev/null 2>&1; then
    val=$(jq -r --arg f "$field" '.[$f] // empty' "$manifest" 2>/dev/null || true)
  else
    # crude grep fallback
    val=$(grep -oE '"'"$field"'": *"([^"]*)"' "$manifest" 2>/dev/null | sed -E 's/.*: *"([^"]*)"/\1/' || true)
  fi
  printf '%s\n' "$val"
}

state_summary_tsv() { # file.tsv -> prints counts
  local f="$1"; [[ -f "$f" ]] || return 0
  local total completed failed
  total=$(awk 'NF>0{c++} END{print c+0}' "$f")
  completed=$(awk '$2=="complete"{c++} END{print c+0}' "$f")
  failed=$(awk '$2 ~ /^failed_/{c++} END{print c+0}' "$f")
  printf 'Summary: total=%s completed=%s failed=%s\n' "$total" "$completed" "$failed"
}

state_list_failures_tsv() { # file.tsv -> list of failed hosts
  local f="$1"; [[ -f "$f" ]] || return 0
  awk '$2 ~ /^failed_/{print $1"\t"$2}' "$f" | sort -u
}

# Return WSL path to bridge manifest (stdout) or nothing if not found.
ssh_bridge_manifest_path() {
  local user="${1:-}"
  [[ -z "$user" ]] && user="$(detect_windows_user || true)"
  [[ -n "$user" ]] || return 1
  local p="/mnt/c/Users/${user}/.ssh/bridge-manifest.json"
  [[ -f "$p" ]] || return 1
  printf '%s\n' "$p"
}

# Derive public key path from manifest (ssh_key_path + .pub) or fallbacks.
ssh_bridge_public_key() {
  local manifest="${1:-}" pub priv
  if [[ -n "$manifest" && -f "$manifest" ]]; then
    priv="$(read_manifest_field "$manifest" ssh_key_path 2>/dev/null || true)"
    if [[ -n "$priv" ]]; then
      priv="$(to_wsl_path "$priv")"
      pub="${priv}.pub"
      if [[ -f "$pub" ]]; then
        printf '%s\n' "$pub"; return 0
      elif [[ -f "$priv" ]]; then
        # regenerate pub (side-effect only if writable)
        if ssh-keygen -y -f "$priv" >"${pub}" 2>/dev/null; then
          printf '%s\n' "$pub"; return 0
        fi
      fi
    fi
  fi
  # Fallbacks
  if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then printf '%s\n' "$HOME/.ssh/id_ed25519.pub"; return 0; fi
  if [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then printf '%s\n' "$HOME/.ssh/id_rsa.pub"; return 0; fi
  return 1
}

# Ensure jq exists or emit guidance and fail.
require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    ssh_bridge_log ERROR "jq is required for robust JSON parsing. Install with: sudo apt-get update && sudo apt-get install -y jq"
    return 1
  fi
  return 0
}

# Normalize Windows path (C:\.. or \\?\C:\..) to WSL path (/mnt/c/..),
# collapse duplicate slashes, and avoid trailing spaces.
normalize_win_path() {
  local p="$1"
  # Strip optional UNC prefix like \\?\
  p="${p#\\\\?\\}"
  if [[ "$p" =~ ^[A-Za-z]:\\\\ ]]; then
    local d="${p:0:1}"; d="${d,,}"
    local rest="${p:2}"
    rest="${rest//\\/\/}"
    # Remove potential leading slash in rest
    [[ "$rest" == /* ]] && rest="${rest:1}"
    # Collapse duplicate slashes
    rest="$(printf '%s' "$rest" | sed -E 's#/+#/#g')"
    printf '/mnt/%s/%s\n' "$d" "$rest"
  else
    # Already a WSL path or something else; collapse duplicate slashes
    printf '%s\n' "$p" | sed -E 's#/+#/#g'
  fi
}

# Resolve npiperelay path from manifest with robust fallback chain:
# npiperelay_wsl -> npiperelay_path -> npiperelay_win (converted)
# Prints resolved path (WSL view) or nothing; returns non-zero on failure.
resolve_npiperelay_from_manifest() {
  local manifest="$1"
  [[ -f "$manifest" ]] || return 1
  require_jq || return 2
  local np_wsl np_path np_win guess
  np_wsl=$(jq -r '.npiperelay_wsl // empty' "$manifest" 2>/dev/null)
  if [[ -n "$np_wsl" ]]; then
    np_wsl="$(normalize_win_path "$np_wsl")"
    if [[ -f "$np_wsl" ]]; then printf '%s\n' "$np_wsl"; return 0; fi
  fi
  np_path=$(jq -r '.npiperelay_path // empty' "$manifest" 2>/dev/null)
  if [[ -n "$np_path" ]]; then
    guess="$(normalize_win_path "$np_path")"
    if [[ -f "$guess" ]]; then printf '%s\n' "$guess"; return 0; fi
  fi
  np_win=$(jq -r '.npiperelay_win // empty' "$manifest" 2>/dev/null)
  if [[ -n "$np_win" ]]; then
    guess="$(normalize_win_path "$np_win")"
    if [[ -f "$guess" ]]; then printf '%s\n' "$guess"; return 0; fi
  fi
  return 3
}
