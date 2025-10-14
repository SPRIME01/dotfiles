# VS Code Environment Variables Guide

## The Problem

VS Code and its MCP servers don't automatically inherit environment variables from your shell config files (`.zshrc`, `.bashrc`). This means variables defined in `~/.dotfiles/.env` are available in your terminal but not in GUI applications like VS Code.

## The Solution: Systemd User Environment

We export environment variables to systemd's user environment, making them available to ALL applications (including VS Code and MCP servers).

## How It Works

### Automatic Sync (Recommended)

Your shell now automatically detects when `.env` has changed and syncs it to systemd:

1. Edit `~/.dotfiles/.env` to add/change variables
2. Open a new terminal (the auto-sync runs on shell startup)
3. Restart VS Code to pick up the changes

### Manual Sync

If you need to sync immediately without opening a new terminal:

```bash
sync-env
```

Then restart VS Code (or reload window: `Ctrl+Shift+P` → "Developer: Reload Window")

## Scripts Available

### `sync-env-to-systemd.sh`

Main script that exports all variables from `.env` to systemd user environment.

- **Alias:** `sync-env`
- **When to use:** After editing `.env` when you need immediate sync

### `auto-sync-env.sh`

Automatically runs on shell startup to sync `.env` if it has been modified.

- **Runs:** Automatically when you open a new terminal
- **Smart:** Only syncs if `.env` has changed since last sync

### `export-to-systemd-env.sh`

Low-level script that does the actual systemd export.

- **Used by:** Other sync scripts
- **Direct use:** Rarely needed

### `export-to-pam-env.sh`

Alternative approach using `.pam_environment` (for older systems).

- **When to use:** If systemd approach doesn't work
- **Note:** Requires logout/login instead of just restart

## Verification

Check if variables are in systemd environment:

```bash
systemctl --user show-environment | grep SMITHERY
```

Check if VS Code can see them:

1. Open VS Code
2. Open Terminal in VS Code
3. Run: `echo $SMITHERY_API_KEY`

## Using in MCP Servers

### Option 1: Environment Variable (Works Now)

In your MCP server config, use the `env` section:

```json
{
  "mcpServers": {
    "ref-tools": {
      "command": "node",
      "args": ["/path/to/server.js"],
      "env": {
        "SMITHERY_API_KEY": "${env:SMITHERY_API_KEY}"
      }
    }
  }
}
```

### Option 2: Direct Value (Simplest)

```json
{
  "mcpServers": {
    "ref-tools": {
      "command": "node",
      "args": ["/path/to/server.js"],
      "env": {
        "SMITHERY_API_KEY": "cc369a4a-eaf7-47a4-b6ba-61fae9e9e628"
      }
    }
  }
}
```

### Note on URL Parameters

The syntax `https://server.url?api_key=${env:SMITHERY_API_KEY}` in URLs may not work in all MCP implementations. Use the `env` section instead.

## Workflow

### Adding New API Keys

1. **Edit the env file:**

   ```bash
   code ~/.dotfiles/.env
   # Add: NEW_API_KEY=your_key_here
   ```

2. **Sync to systemd:**
   - Automatic: Open a new terminal
   - Manual: Run `sync-env`

3. **Restart VS Code:**
   - Close and reopen VS Code, OR
   - `Ctrl+Shift+P` → "Developer: Reload Window"

4. **Verify:**

   ```bash
   systemctl --user show-environment | grep NEW_API_KEY
   ```

### Troubleshooting

**Variables not showing in VS Code?**

- Verify systemd has them: `systemctl --user show-environment | grep YOUR_VAR`
- Make sure you restarted VS Code completely
- Try: `systemctl --user restart graphical.target` (restarts all GUI apps)

**Auto-sync not working?**

- Check `~/.cache/dotfiles-env-sync` exists and has timestamp
- Run manually: `bash ~/.dotfiles/scripts/auto-sync-env.sh`
- Verify script runs on shell startup: `echo "Test" >> ~/.dotfiles/.env` then open new terminal

**Still not working?**

- Try the PAM environment approach: `bash ~/dotfiles/scripts/export-to-pam-env.sh`
- Logout and login again
- Or put the values directly in your MCP config's `env` section

## Files Modified

- `~/.dotfiles/.shell_common.sh` - Added auto-sync on shell startup
- `~/.dotfiles/scripts/sync-env-to-systemd.sh` - User-friendly sync command
- `~/.dotfiles/scripts/auto-sync-env.sh` - Automatic sync logic
- `~/.dotfiles/scripts/export-to-systemd-env.sh` - Core systemd export
- `~/.dotfiles/scripts/export-to-pam-env.sh` - Alternative PAM approach
