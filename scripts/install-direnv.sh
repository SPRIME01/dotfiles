#!/usr/bin/env bash
set -euo pipefail

# Simple cross-platform installer for direnv used by the justfile.
# Mirrors behavior of the previous inline command: idempotent, prints helpful hints.

echo "🌱 Installing direnv..."
if command -v direnv >/dev/null 2>&1; then
	echo "✅ direnv already installed: $(command -v direnv)"
	direnv version || true
	exit 0
fi

OS="$(uname -s || true)"

if command -v apt >/dev/null 2>&1; then
	echo "📦 Using apt"
	sudo apt update -y >/dev/null 2>&1 || true
	sudo apt install -y direnv
elif command -v brew >/dev/null 2>&1; then
	echo "🍺 Using Homebrew"
	brew install direnv
elif command -v dnf >/dev/null 2>&1; then
	echo "📦 Using dnf"
	sudo dnf install -y direnv
elif command -v pacman >/dev/null 2>&1; then
	echo "📦 Using pacman"
	sudo pacman -Sy --noconfirm direnv
elif command -v zypper >/dev/null 2>&1; then
	echo "📦 Using zypper"
	sudo zypper install -y direnv
elif command -v scoop >/dev/null 2>&1; then
	echo "🪟 Using scoop (Windows)"
	scoop install direnv
elif command -v choco >/dev/null 2>&1; then
	echo "🪟 Using choco (Windows)"
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
