# WSL2 ↔ Windows SSH Agent Bridge — Justfile Cheatsheet

This guide summarizes the Just recipes for the SSH agent bridge in `ssh-agent-bridge/` and common workflows. Run `just ssh-bridge-help` to list commands.

## Quick Setup

- Install on Windows (creates manifest and loads key):
  - `just ssh-bridge-install-windows`
  - Dry run: `just ssh-bridge-install-windows-dry-run`

- Install bridge in WSL (creates helper and rc block):
  - `just ssh-bridge-install-wsl`
  - Dry run: `just ssh-bridge-install-wsl-dry-run`

- Verify everything looks good:
  - `just ssh-bridge-preflight`

## Daily Use

- Deploy key to all hosts from `~/.ssh/config` (verify auth, cleanup old keys):
  - `just ssh-bridge-deploy`
  - Dry run: `just ssh-bridge-deploy-dry-run`

- Bootstrap LAN hosts from `ssh-agent-bridge/hosts.txt` (first-time trust):
  - `just ssh-bridge-lan-bootstrap`
  - Dry run: `just ssh-bridge-lan-bootstrap-dry-run`

- Cleanup/Uninstall:
  - Perms and config: `just ssh-bridge-fix-perms`, `just ssh-bridge-fix-config`, `just ssh-bridge-fix-config-dry-run`
  - Remove bridge: `just ssh-bridge-uninstall`

## Parameterized Variants

Use these when you need to filter targets, increase parallelism, set timeouts, or pass custom flags. Quote patterns/paths that contain spaces.

### Deploy (custom parameters)

```
just ssh-bridge-deploy-custom \
  only="prod-*,db-*" \
  exclude="*-test*" \
  jobs="8" \
  timeout="10" \
  resume="1" \
  old_keys_dir="/mnt/c/Users/you/.ssh/backup-20240831" \
  dry_run="0" \
  verbose="1"
```

Flags map to `ssh-agent-bridge/deploy-ssh-key-to-hosts.sh`:
- `only`: `--only "PATTERN[,PATTERN...]"`
- `exclude`: `--exclude "PATTERN[,PATTERN...]"`
- `jobs`: `--jobs N`
- `timeout`: `--timeout N`
- `resume=1`: adds `--resume`
- `old_keys_dir`: `--old-keys-dir PATH`
- `dry_run=1`: adds `--dry-run`
- `verbose=1`: adds `--verbose`

Passthrough alternative (write flags exactly as the script expects):

```
just ssh-bridge-deploy-args \
  --verbose --jobs 8 --timeout 10 \
  --only "prod-*,db-*" --exclude "*-test*" \
  --resume --old-keys-dir "/mnt/c/Users/you/.ssh/backup-20240831"
```

### LAN Bootstrap (custom parameters)

```
just ssh-bridge-lan-bootstrap-custom \
  hosts="ssh-agent-bridge/hosts.txt" \
  pubkey="/mnt/c/Users/you/.ssh/id_ed25519.pub" \
  only="prime@192.168.0.50" \
  exclude="" \
  jobs="4" \
  timeout="8" \
  resume="0" \
  disable_pw_auth="0" \
  dry_run="0" \
  verbose="1"
```

Passthrough alternative:

```
just ssh-bridge-lan-bootstrap-args \
  --verbose --jobs 4 --hosts ssh-agent-bridge/hosts.txt \
  --only "prime@192.168.0.50" --timeout 8 --resume
```

### Rotate + Deploy

Rotate SSH key on Windows, ensure the bridge, then deploy to hosts:

- Quick: `just ssh-bridge-rotate-deploy`
- Passthrough: `just ssh-bridge-rotate-deploy-args --dry-run --skip-bridge --only "prod-*"`

## Notes

- Most recipes require running from WSL (they check `WSL_DISTRO_NAME`).
- Logs are written under `~/.ssh/logs` by the underlying scripts.
- `ssh-bridge-list-hosts` shows expanded `Host` entries parsed from `~/.ssh/config`.
- For Windows steps, you’ll be prompted to allow PowerShell to run elevated actions where needed.

