# Redirect zsh to use a safe ZDOTDIR wrapper
# Soften startup so system files can't kill login shells
unset NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S
unset NODE_REPL_TRUSTED_CODE_PATHS
unset NODE_TLS_REJECT_UNAUTHORIZED

# Make mise-managed CLIs available to interactive and non-interactive agents.
if [[ -d "$HOME/.local/share/mise/shims" ]]; then
  export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

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
