# Redirect zsh to use a safe ZDOTDIR wrapper
# Soften startup so system files can't kill login shells
setopt no_errexit 2>/dev/null || true
set +e 2>/dev/null || true

# Temporarily intercept exit during init; wrapper will undo this
export ZSH_SAFE_INIT=1
function exit() {
  if [ -n "$ZSH_SAFE_INIT" ]; then
    echo "[zshenv] suppressed exit $*" >&2
    return 0
  fi
  builtin exit "$@"
}

# Redirect zsh to use a safe ZDOTDIR wrapper
export ZDOTDIR="$HOME/.zshrc.safe.d"
