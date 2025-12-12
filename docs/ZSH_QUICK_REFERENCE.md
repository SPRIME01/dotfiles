# Zsh Quick Reference - New Features

## 🎯 Keyboard Shortcuts

| Shortcut  | Action                                   |
| --------- | ---------------------------------------- |
| `Ctrl+R`  | Fuzzy search command history (fzf)       |
| `Ctrl+T`  | Fuzzy search files and insert path (fzf) |
| `Alt+C`   | Fuzzy search directories and cd (fzf)    |
| `ESC ESC` | Add sudo to current command              |
| `→`       | Accept autosuggestion                    |
| `Ctrl+→`  | Accept one word of suggestion            |
| `↑` / `↓` | Search history matching typed text       |

## 🔍 Smart Navigation

```bash
z <keyword>       # Jump to directory matching keyword
z -           # Go back to previous directory
zi            # Interactive directory selection (fzf)
cd <partial>      # Now uses zoxide (smart jumping)
```

## 📁 File Listing (eza)

```bash
ls            # Modern ls with icons
ll            # Long format with git status
la            # Show all (including hidden)
lt            # Tree view (2 levels)
llt           # Tree with details
```

## 🐙 Git Shortcuts

```bash
g             # git
gs            # git status -sb (short, branch)
gd            # git diff
gdc           # git diff --cached
glog          # Pretty git log graph
gp            # git pull
gpu           # git push
gcm "msg"     # git commit -m
gca           # git commit --amend
gco <branch>  # git checkout
gcb <name>    # git checkout -b (new branch)
```

## 🐳 Docker Shortcuts

```bash
dc            # docker compose
dcu           # docker compose up -d
dcd           # docker compose down
dcl           # docker compose logs -f
dcr           # docker compose restart
```

## 🛠️ Utilities

```bash
extract <archive>     # Universal extractor (zip, tar, etc.)
h <pattern>           # Search command history
ports                 # Show network ports
take <dir>            # Make directory and cd into it
backup <file>         # Create timestamped backup
```

## 💡 Pro Tips

1. **Building zoxide database**: Use `cd` normally for a few days, then `z` becomes smart
2. **fzf preview**: Add `--preview 'cat {}'` to see file contents
3. **History search**: Type `git` then ↑ to see only git commands
4. **Autosuggestions**: Keep typing if suggestion is wrong, or press → to accept
5. **Tab completion**: Use TAB for interactive menus (arrow keys to navigate)

## 🔧 Configuration

- Main config: `~/.zshrc`
- Enhancements: `~/dotfiles/.zsh_enhancements.zsh`
- P10k theme: `~/.p10k.zsh`
- Local overrides: `~/.zshrc.local` (create if needed)

## 📊 Check Status

```bash
echo $plugins         # Loaded plugins
alias | grep eza      # Check eza aliases
which fzf zoxide eza  # Tool locations
echo $HISTSIZE        # History size (50000)
```
