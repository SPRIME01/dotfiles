#!/usr/bin/env bash
# fix-wsl-ssh-config.sh
# Make ~/.ssh/config OpenSSH-safe on WSL: local ext4 file, LF endings, strict perms, clean ACLs.
# Prints before/after report. Idempotent. Safe. Optional --dry-run and --no-acl.

set -euo pipefail

DRY_RUN=0
DO_ACL=1

usage() {
  cat <<'USAGE'
Usage: bash fix-wsl-ssh-config.sh [--dry-run] [--no-acl]

  --dry-run   Show what would be changed, but do nothing.
  --no-acl    Do not modify extended ACLs (skip setfacl -b step).

This script:
  • Ensures ~/.ssh exists and is owned by you
  • Replaces ~/.ssh/config symlink (or drvfs-backed file) with a real ext4 file
  • Converts CRLF -> LF and trims trailing/leading spaces
  • Sets perms: ~/.ssh = 700, config = 600, known_hosts/pubkeys = 644
  • Home dir not group/other writable
  • Optionally removes extended ACLs (setfacl -b) if tool is present
  • Prints a before/after report for transparency
USAGE
}

# ---- parse args
while (( "$#" )); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --no-acl)  DO_ACL=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

ME="$USER"
HOME_DIR="$HOME"
SSH_DIR="$HOME/.ssh"
CFG="$SSH_DIR/config"
NOW="$(date +%Y%m%d_%H%M%S)"

run() {
  if (( DRY_RUN )); then
    echo "DRY-RUN: $*"
  else
    eval "$@"
  fi
}

line() { printf '%s\n' "------------------------------------------------------------"; }
hdr()  { printf '\n## %s\n' "$*"; }
kval() { printf '%-22s %s\n' "$1:" "$2"; }

report_path() {
  local p="$1"
  if [ -e "$p" ]; then
    local fs; fs=$(df -T "$p" | awk 'NR==2{print $2}')
    local st; st=$(stat -c "%A %U:%G" "$p")
    kval "Path" "$p"
    kval "Filesystem" "$fs"
    kval "Mode/Owner" "$st"
  else
    kval "Path" "$p (missing)" ""
  fi
}

report_before() {
  hdr "Before"
  report_path "$HOME_DIR"
  report_path "$SSH_DIR"
  report_path "$CFG"
  line
}

report_after() {
  hdr "After"
  report_path "$HOME_DIR"
  report_path "$SSH_DIR"
  report_path "$CFG"
  line
}

echo
line
echo "WSL SSH Config Fix • $(date -Is)"
line

report_before

# 1) Ensure ~/.ssh exists
hdr "Ensure ~/.ssh exists & owned by you"
if [ ! -d "$SSH_DIR" ]; then
  run "mkdir -p '$SSH_DIR'"
fi
run "sudo chown -R '$ME:$ME' '$SSH_DIR'"

# 2) If config is a symlink or lives on a Windows mount (drvfs/9p), replace with real file
NEEDS_REWRITE=0
if [ -L "$CFG" ]; then
  echo "Detected symlink: $CFG"
  NEEDS_REWRITE=1
elif [ -f "$CFG" ]; then
  fs=$(df -T "$CFG" | awk 'NR==2{print $2}')
  case "$fs" in
    drvfs|9p) echo "Detected Windows/9p filesystem for $CFG ($fs)"; NEEDS_REWRITE=1 ;;
    *) : ;;
  esac
fi

if (( NEEDS_REWRITE )); then
  hdr "Replacing with a real ext4 file (backup first)"
  [ -f "$CFG" ] && run "cp -f '$CFG' '$CFG.bak_${NOW}'"
  # resolve symlink if present, then copy contents; if missing, start minimal
  SRC=""
  if [ -L "$CFG" ]; then SRC="$(readlink -f "$CFG" || true)"; fi
  if [ -n "${SRC:-}" ] && [ -f "$SRC" ]; then
    run "cp -f '$SRC' '$CFG.new'"
  elif [ -f "$CFG" ]; then
    run "cp -f '$CFG' '$CFG.new'"
  else
    cat > "$CFG.new" <<'CFGEOF'
Host *
  IdentityAgent ~/.ssh/agent.sock
  IdentitiesOnly yes
  PubkeyAuthentication yes
CFGEOF
    if (( DRY_RUN )); then echo "DRY-RUN: wrote minimal ~/.ssh/config.new"; fi
  fi
  run "rm -f '$CFG'"
  run "mv '$CFG.new' '$CFG'"
fi

# 3) Normalize newlines & whitespace (CRLF→LF; trim edges)
hdr "Normalize line endings & whitespace"
if [ -f "$CFG" ]; then
  # CRLF -> LF
  run "sed -i 's/\r$//' '$CFG'"
  # trim leading/trailing spaces
  run "sed -i -E 's/^[[:space:]]+|[[:space:]]+\$//g' '$CFG'"
fi

# 4) Tighten permissions
hdr "Tighten permissions"
# home must not be group/other writable
run "chmod go-w '$HOME_DIR' || true"
# .ssh strict, config strict
run "chmod 700 '$SSH_DIR'"
[ -f "$CFG" ] && run "chmod 600 '$CFG'"
# common files
[ -f "$SSH_DIR/authorized_keys" ] && run "chmod 600 '$SSH_DIR/authorized_keys'"
for f in "$SSH_DIR"/*.pub "$SSH_DIR/known_hosts"; do
  [ -f "$f" ] && run "chmod 644 '$f'"
done

# 5) Optionally strip extended ACLs (if tool present)
if (( DO_ACL )); then
  if command -v setfacl >/dev/null 2>&1; then
    hdr "Strip extended ACLs (setfacl -b)"
    for p in "$HOME_DIR" "$SSH_DIR" "$CFG"; do
      [ -e "$p" ] && run "setfacl -b '$p' || true"
    done
  else
    echo "Note: 'setfacl' not found; skipping ACL cleanup. (Install with: sudo apt-get update && sudo apt-get install -y acl)"
  fi
else
  echo "Skipping ACL cleanup by request (--no-acl)."
fi

report_after

echo "Done."
if (( DRY_RUN )); then
  echo "DRY RUN ONLY — no changes were made."
else
  echo "Tip: test with  'ssh -T git@github.com'  and  'ssh -G <HostAlias>'"
fi
