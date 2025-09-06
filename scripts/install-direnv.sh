#!/usr/bin/env bash
set -euo pipefail
#!/usr/bin/env bash
set -euo pipefail

# Privilege helper: use sudo if present and needed
SUDO=()
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO=(sudo)
  else
    echo "⚠️ Running as non-root and sudo not found; attempting installs without elevation." >&2
  fi
fi

# …rest of install-direnv.sh…
# Simple cross-platform installer for direnv used by the justfile.
# Mirrors behavior of the previous inline command: idempotent, prints helpful hints.

echo "🌱 Installing direnv..."
if command -v direnv >/dev/null 2>&1; then
	echo "✅ direnv already installed: $(command -v direnv)"
	direnv version || true
	exit 0
fi

OS="$(uname -s || true)"

# record which PM we used for possible post-install messaging
USED_PM="unknown"

if command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; then
	echo "📦 Using apt"
	USED_PM="apt"
	${SUDO[@]} apt-get update -qq
	DEBIAN_FRONTEND=noninteractive ${SUDO[@]} apt-get install -yq direnv
elif command -v brew >/dev/null 2>&1; then
	echo "🍺 Using Homebrew"
	USED_PM="brew"
	brew install direnv
elif command -v dnf >/dev/null 2>&1; then
	echo "📦 Using dnf"
	USED_PM="dnf"
	${SUDO[@]} dnf install -y direnv
elif command -v pacman >/dev/null 2>&1; then
	echo "📦 Using pacman"
	USED_PM="pacman"
	${SUDO[@]} pacman -S --noconfirm --needed direnv
elif command -v zypper >/dev/null 2>&1; then
	echo "📦 Using zypper"
	USED_PM="zypper"
	${SUDO[@]} zypper -n install -y direnv
elif command -v scoop >/dev/null 2>&1; then
	echo "🪟 Using scoop (Windows)"
	USED_PM="scoop"
	scoop install direnv
elif command -v choco >/dev/null 2>&1; then
	echo "🪟 Using choco (Windows)"
	USED_PM="choco"
	choco install direnv -y
else
	echo "❌ No supported package manager found. Install manually from https://direnv.net"
	exit 1
fi

if command -v direnv >/dev/null 2>&1; then
	echo "🎉 direnv installed: $(direnv version || true)"
	echo "💡 Create a .envrc in a project and run: direnv allow"
	echo "💡 To disable temporarily: export DISABLE_DIRENV=1"
else
	echo "❌ direnv installation appears to have failed"
	exit 1
fi
