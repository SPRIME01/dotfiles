# Vault Integration with direnv (How‑To)

This guide shows two robust patterns to bring HashiCorp Vault secrets into your shell using direnv, working across Bash, Zsh, and PowerShell.

## Why This Setup

- Per‑repo scoping via direnv (secrets only active in this directory)
- No secrets committed; files have strict perms
- Plays nicely with existing global loader; you can set `DOTFILES_SKIP_SECRET_FILES=1` to avoid global secret export

## Pattern A — Vault Agent Sink (Recommended)

Run a Vault Agent that writes an env file for direnv to consume.

- Default sink path on Linux/macOS: `~/.cache/vault/dotfiles.env`
- Suggested Windows path (PowerShell agent): `$env:LOCALAPPDATA\vault\dotfiles.env`

Example `vault-agent.hcl` (adjust for your auth/backends):

```
auto_auth {
  method "oidc" {
    mount_path = "auth/oidc"
    config = { role = "dev-shell" }
  }
  sink "file" {
    config = {
      path = "~/.cache/vault/dotfiles.env"
      format = "env"
    }
  }
}

vault {
  address = "https://vault.example.com"
}
```

Permissions:

```bash
mkdir -p ~/.cache/vault
chmod 700 ~/.cache/vault
# Agent writes with 600; verify
stat -c %a ~/.cache/vault/dotfiles.env 2>/dev/null || true
```

direnv hookup (already in `.envrc` here):

```bash
# in .envrc
VAULT_SINK_PATH=${VAULT_SINK_PATH:-"$HOME/.cache/vault/dotfiles.env"}
watch_file "$VAULT_SINK_PATH"
dotenv_if_exists "$VAULT_SINK_PATH"
```

To use a custom path, set `VAULT_SINK_PATH` in `.envrc.local` or your shell before entering the directory.

## Pattern B — CLI Fetch (Fallback)

When an Agent isn’t available, fetch on demand. Keep this in `.envrc.local` so you can customize paths and mounts safely.

Requirements: `vault`, `jq` available and logged in (`vault login` or OIDC flow).

```bash
# .envrc.local (example)
if command -v vault >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  if vault token lookup >/dev/null 2>&1; then
    direnv_load bash -c '
      set -euo pipefail
      vault kv get -format=json kv/data/myapp \
        | jq -r '.data.data | to_entries[] | "export \(.key)=\(.value)"'
    '
  else
    echo "direnv: Vault not logged in; run: vault login" >&2
  fi
fi
```

Notes:
- This runs only on directory enter or `direnv reload`.
- For Windows PowerShell shells, prefer the Agent sink; the above snippet assumes a bash-compatible environment is available.

## Security Considerations

- Secrets are scoped to this repo; leaving the directory clears them from the active environment.
- Keep sink files out of the repo and under `600` perms.
- Prefer file-based consumption when tools support it to avoid populating env vars broadly.

## Quick Start

1) Enable direnv here (already wired):

```bash
cd ~/dotfiles
export DOTFILES_SKIP_SECRET_FILES=1   # optional: avoid global secret export
direnv allow
```

2) Choose a pattern:
- Agent sink: run Vault Agent with the file sink and confirm the sink path; direnv auto-loads it.
- CLI fallback: copy the example snippet into `.envrc.local` and adjust the KV path.

That’s it—consistent, cross‑shell secrets with minimal friction.

## Windows (PowerShell) Notes

- Recommended sink path: `$env:LOCALAPPDATA\vault\dotfiles.env`
- Create the directory once:

```powershell
New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\vault" | Out-Null
```

- Example Agent HCL (Windows absolute path required):

```
auto_auth {
  method "oidc" {
    mount_path = "auth/oidc"
    config = { role = "dev-shell" }
  }
  sink "file" {
    config = {
      path = "C:\\Users\\YourUser\\AppData\\Local\\vault\\dotfiles.env"
      format = "env"
    }
  }
}

vault {
  address = "https://vault.example.com"
}
```

- Runner script included: `tools/vault/run-agent.ps1`
  - Usage:
    ```powershell
    $env:VAULT_ADDR = 'https://vault.example.com'
    # Optional overrides: $env:VAULT_ROLE, $env:VAULT_AUTH_METHOD, $env:VAULT_SINK_PATH
    pwsh -NoProfile -File tools/vault/run-agent.ps1
    ```

- direnv hookup: `.envrc` already tries `VAULT_SINK_PATH` first; set it in PowerShell if you don’t use the default:

```powershell
$env:VAULT_SINK_PATH = "$env:LOCALAPPDATA\vault\dotfiles.env"
direnv reload
```
