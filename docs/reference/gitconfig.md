

Recommended global defaults
- pull.rebase = true
- rebase.autoStash = true
- pull.ff = only
- fetch.prune = true
- init.defaultBranch = main
- rebase.updateRefs = true

Apply globally (Linux/WSL/Windows shells)
````bash
# Rebase by default on pull (cleaner history)
git config --global pull.rebase true

# Auto-stash local changes before rebase/pull, then pop
git config --global rebase.autoStash true

# Only fast-forward merges on pull (prevents unintended merge commits)
git config --global pull.ff only

# Prune remote-tracking branches that were deleted on the remote
git config --global fetch.prune true

# New repos use 'main' as the default branch
git config --global init.defaultBranch main

# Update other branch refs during rebase (Git 2.38+)
git config --global rebase.updateRefs true
````

Verify current global settings
````bash
git config --global --get pull.rebase
git config --global --get rebase.autoStash
git config --global --get pull.ff
git config --global --get fetch.prune
git config --global --get init.defaultBranch
git config --global --get rebase.updateRefs

# Or list all globals
git config --global -l
````

Global ignore file
````bash
# Use the global ignore installed by chezmoi
git config --global core.excludesfile "$HOME/.gitignore_global"

# Verify
git config --global --get core.excludesfile
````

Per-repo override (run inside a repo)
````bash
# Example: use merge instead of rebase for just this repo
git config pull.rebase false

# Example: allow non-FF merges on pull for this repo only
git config pull.ff false
````

Revert a global setting
````bash
# Example: disable autoStash globally
git config --global --unset rebase.autoStash
````

Notes
- Ensure Git ≥ 2.38 for rebase.updateRefs. Check with: git --version
- You can always override per invocation: git pull --rebase, git pull --no-rebase, or git pull --ff-only
- For this repo, you can also use the provided helper: bash update.sh (auto-stash, pull, reapply bootstrap, pop)
