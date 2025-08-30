\
#!/usr/bin/env bash
# uninstall-wsl-bridge.sh — Cleanly remove WSL bridge edits
set -euo pipefail
begin="# >>> WSL→Windows SSH agent bridge (BEGIN) >>>"
end="# <<< WSL→Windows SSH agent bridge (END) <<<"

clean_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  awk -v b="$begin" -v e="$end" '
    BEGIN{p=1}
    $0 ~ b {p=0; next}
    $0 ~ e {p=1; next}
    {if(p) print}
  ' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
  echo "Cleaned: $file"
}

clean_file "$HOME/.bashrc"
[[ -n "${ZDOTDIR:-}" ]] && clean_file "$ZDOTDIR/.zshrc" || clean_file "$HOME/.zshrc"
rm -f "$HOME/.local/bin/win-ssh-agent-bridge" "$HOME/.ssh/agent.sock"
echo "WSL bridge uninstalled."
