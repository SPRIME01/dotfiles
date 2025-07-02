#!/usr/bin/env bash

echo "⚙️ Setting up Unix shell..."

DOTFILES=~/dotfiles

ln -sf "$DOTFILES/.bashrc" ~/.bashrc
ln -sf "$DOTFILES/.zshrc" ~/.zshrc
ln -sf "$DOTFILES/.shell_common" ~/.shell_common
ln -sf "$DOTFILES/.shell_theme_common" ~/.shell_theme_common

if ! command -v oh-my-posh &> /dev/null; then
    curl -s https://ohmyposh.dev/install.sh | bash -s
fi
