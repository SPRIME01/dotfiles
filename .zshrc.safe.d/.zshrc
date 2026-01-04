# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.safe.d/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Safe zshrc wrapper to prevent startup crashes

# Be tolerant during interactive init
setopt no_errexit 2>/dev/null
set +e 2>/dev/null || true

# Note: SSH agent access in WSL2 is handled via Tailscale SSH (tailscale up --ssh).
# The old npiperelay/socat bridge to Windows ssh-agent has been removed.
# For remote access, run: just install-tailscale && just setup-wsl2-remote

# Source original config under protection (always, non-fatal)
if [ -r "$HOME/.zshrc" ]; then
  function exit() { builtin echo "[zshrc] suppressed exit $*" >&2; return 0; }
  emulate -L zsh
  setopt no_errexit
  set +e
  { source "$HOME/.zshrc"; } || true
  unfunction exit 2>/dev/null
fi

# Cleanup init guards
unset ZSH_SAFE_INIT
unfunction exit 2>/dev/null || true

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# bun completions
[ -s "/home/sprime01/.bun/_bun" ] && source "/home/sprime01/.bun/_bun"
