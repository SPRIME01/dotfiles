#!/usr/bin/env bash
set -e

# Automatically determine the dotfiles directory based on where this script lives
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

echo "⚙️ Setting up Unix shell..."

DOTFILES=~/dotfiles

ln -sf "$DOTFILES/.bashrc" ~/.bashrc
ln -sf "$DOTFILES/.zshrc" ~/.zshrc
ln -sf "$DOTFILES/.shell_common" ~/.shell_common
ln -sf "$DOTFILES/.shell_theme_common" ~/.shell_theme_common

if ! command -v oh-my-posh &> /dev/null; then
    curl -s https://ohmyposh.dev/install.sh | bash -s
fi
