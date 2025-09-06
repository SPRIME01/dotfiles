# How to Use direnv (Task‑oriented)

What it is

- direnv loads environment variables and paths when you cd into a directory that has an `.envrc`, and unloads them when you leave. It is opt‑in (via `direnv allow`).

Install

- From inside this repo, choose one:
  ```bash
  just install-direnv          # project recipe
  # or
  bash scripts/install-direnv.sh
  direnv version
  ```

Shell integration

- Bash/Zsh: this repo injects direnv hooks via templates and common loaders:
  - Zsh: `dot_zshrc.tmpl` renders `eval "$(direnv hook zsh)"` and silences logs by default.
  - Bash: `shell/common/direnv.sh` safely hooks `eval "$(direnv hook bash)"` and quiets logs.
- PowerShell (optional): you can add a hook to your profile if you use direnv there:
  ```powershell
  # Add to your PowerShell profile if desired
  Invoke-Expression (direnv hook pwsh)
  ```

Security model

- direnv ignores `.envrc` until you explicitly trust it with `direnv allow`.
- This repo’s `.envrc` is committed with secure defaults: silent logs, `umask 077`, dotenv files watched, optional `mise` integration.
- TIP: toggle logs at runtime
  ```bash
  direnv_quiet
  direnv_verbose
  ```

Workflow in this repo

1) Enable once per machine (install + shell hook is templated).
2) Trust the repo’s `.envrc`:
   ```bash
   direnv allow     # in repo root
   direnv status
   ```
3) Use dotenv files if needed (all are safe to ignore in git):
   - `.env.defaults` → baseline values
   - `.env` → personal (ignored)
   - `mcp/.env` → optional MCP integration (ignored)

Verification

```bash
direnv status | sed -e 's/^/direnv: /'
echo "$DOTFILES_ROOT"  # should point at this repo when in the directory
```

Troubleshooting

- No change on cd: ensure your shell started with the new profile (open a new terminal).
- Noisy logs: use `direnv_quiet` or set `export DIRENV_LOG_FORMAT=""`.
- Windows PowerShell: hook is optional; if you add it, Validate with `direnv status`.

See also

- docs/reference/commands.md (command reference)
- `.envrc`, `.envrc.example` in repo root for patterns and comments

