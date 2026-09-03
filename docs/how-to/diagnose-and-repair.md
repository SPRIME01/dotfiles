# How-To: Diagnose and Repair Shell Startup Issues

> **Type:** Diátaxis How-To Guide (Goal-oriented, practical task)  
> **Goal:** Identify and fix startup delays, missing dependencies, or corrupted dotfiles configurations  
> **Prerequisites:** Terminal access to the repository  

---

## 1. Quick Diagnostic: Run Doctor

The repository includes an automated environment health checker:
```bash
bash scripts/doctor.sh
```
Or via just:
```bash
just doctor
```

### For Strict Verification:
```bash
bash scripts/doctor.sh --strict
```
If any permission is insecure (`.env` not `0600`) or a required tool is missing, `doctor.sh` will exit with a non-zero status code and print actionable remediation steps.

---

## 2. Profiling Shell Startup Time

If your shell feels sluggish when opening a new tab:

### Step 1: Measure Login & Interactive Startup
Run the automated timing benchmark:
```bash
bash tools/measure-startup.sh
```
*Expected baseline:* Average startup time should be between **150ms and 300ms**.

### Step 2: Deep Profiling with `zprof` (Zsh)
Launch an interactive Zsh session with profiling enabled:
```bash
DOTFILES_PROFILE=1 zsh
```
Zsh will immediately print a detailed function-by-function execution cost table:
```
num  calls                time                       self            name
-------------------------------------------------------------------------
 1)    1         124.50   124.50   58.20%    124.50   124.50   58.20%  compinit
 2)    1          35.20    35.20   16.45%     35.20    35.20   16.45%  p10k
```

### Step 3: Resolving Common Bottlenecks
- **`compinit` running multiple times:** Ensure `skip_global_compinit=1` is present in your `.zshrc`.
- **Heavy functions running at startup:** Move on-demand scripts (like `scripts/auto-sync-env.sh`) out of `.zshrc` and into `just` recipes.

---

## 3. Repairing Insecure File Permissions

If `doctor.sh` warns about loose `.env` permissions:
```bash
just env-fix-perms
```
Or manually:
```bash
chmod 600 .env
chmod 600 ~/.dotfiles-state 2>/dev/null || true
```

---

## 4. Resetting and Re-applying Templates with Chezmoi

If your `~/.zshrc` or `~/.bashrc` was edited accidentally outside Chezmoi:
```bash
# Preview what will change
chezmoi diff

# Re-apply repository templates to home directory
chezmoi apply --force
```

---

## 5. Source Trail
- `scripts/doctor.sh`
- `tools/measure-startup.sh`
- `scripts/fix-env-perms.sh`
- `docs/work_summaries/SHELL_MIGRATION.md`
