# Locale handling in dotfiles

This repository includes a small "locale sanitizer" and an audit tool to make
locale-related configuration predictable across Linux, WSL, and desktop sessions.

## Files

- `scripts/locale-sanitizer.sh` - ensures a UTF-8 fallback (`C.UTF-8`) and sets
  `LC_ALL` only if not already set. Supports `DRY_RUN=true` for safe testing.

- `scripts/locale-audit.sh` - scans the repo and common system/user files for
  `en_US.UTF-8`, `C.UTF-8`, `LC_ALL`, or `LANG` occurrences.

## Install / Enable

To enable the sanitizer automatically on shell startup, set the environment
variable in your dotfiles or system profile:

```bash
# enable auto-sanitizer
export DOTFILES_ENABLE_LOCALE_SANITIZER=1
```

Then open a new terminal to have it run. It will skip if `LC_ALL` is already set.

## Usage

Dry-run the sanitizer:

```bash
DRY_RUN=true bash ~/dotfiles/scripts/locale-sanitizer.sh
```

Apply now in the current shell (will set `LC_ALL` in this session only):

```bash
bash ~/dotfiles/scripts/locale-sanitizer.sh
```

Audit the repo for locale strings:

```bash
bash ~/dotfiles/scripts/locale-audit.sh --repo
```

## Verification

- Check available locales:

```bash
locale -a | sed -n '1,200p'
```

- Check current shell locale:

```bash
echo "LC_ALL=$LC_ALL"; echo "LANG=$LANG"; locale
```

- Check systemd user environment (for GUI apps like VS Code):

```bash
systemctl --user show-environment | rg 'LC_ALL|LANG' || true
```

## Notes

- `LC_ALL` is a temporary override and should not normally be set permanently in
  system config; prefer setting `LANG` in systemd or login profile.

- The sanitizer is intentionally conservative: it won't overwrite an existing
  `LC_ALL` set by the user or another script.
