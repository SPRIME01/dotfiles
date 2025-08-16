# .env Schema

Canonical reference for supported environment variables consumed by dotfiles scripts across shells.

| Variable | Required | Default | Description | Used In |
|----------|----------|---------|-------------|---------|
| DOTFILES_ROOT | true | (repo root at install) | Absolute path to the dotfiles repo root; set/exported by loaders | `lib/env-loader.sh`, shell startup |
| DOTFILES_DEBUG | false | (empty) | When "true" enables verbose debug output from helper libs | `lib/platform-detection.sh` |
| DOTFILES_PLATFORM | false | auto-detect | Override platform detection (linux/macos/wsl/windows) | `lib/platform-detection.sh` |
| DOTFILES_SHELL | false | auto-detect | Force shell name for diagnostics | `lib/platform-detection.sh` |
| DOTFILES_STATE_FILE | false | `$HOME/.dotfiles-state` | Path to state tracking file for setup wizard | `lib/state-management.sh`, `scripts/setup-wizard.sh` |
| PROJECTS_ROOT | false | `$HOME/projects` | Root directory for user projects | `scripts/setup-projects-idempotent.sh` |
| SSH_AUTH_SOCK | false | system default | Points to active SSH agent socket (bridge may override) | shell startup files |
| MCP_SERVERS_CONFIG | false | `mcp/servers.json` | Path to MCP servers configuration | mcp integration scripts |
| P10K_CONFIG | false | `.p10k.zsh` | Powerlevel10k theme configuration path override | zsh startup |
| EDITOR | false | `code` or `vi` | Preferred default editor | shell functions |
| GIT_AUTHOR_NAME | false | (empty) | Git author name if not set globally | git setup helpers |
| GIT_AUTHOR_EMAIL | false | (empty) | Git author email if not set globally | git setup helpers |
| LOG_LEVEL | false | `20` | Numeric log threshold: 10=DEBUG, 20=INFO, 30=WARN, 40=ERROR | `lib/log.sh` |
| LOG_LEVEL_NAME | false | (empty) | Case-insensitive alias for LOG_LEVEL (DEBUG/INFO/WARN/ERROR) | `lib/log.sh` |
| GEMINI_API_KEY | false | (empty) | Example of secret loaded from private .env for AI tooling | loaders, tests (`test/test-environment*.sh`) |

## Notes
- Variables not present fall back to safe defaults; add only those you need to customize.
- Secrets should never be placed directly in this repository. Maintain private overrides outside version control.
- Update this file when introducing new environment-driven behaviors.
- Defaults that look like relative paths (e.g., `mcp/servers.json`, `.p10k.zsh`) are resolved relative to `DOTFILES_ROOT` unless otherwise stated.
- EDITOR selection typically prefers `code` when available, otherwise falls back to `vi`.
## Notes
- Variables not present fall back to safe defaults; add only those you need to customize.
- Secrets should never be placed directly in this repository. Maintain private overrides outside version control.
- Update this file when introducing new environment-driven behaviors.
