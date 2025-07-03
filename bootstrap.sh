#!/usr/bin/env bash
set -e

# Automatically determine the dotfiles directory based on where this script lives
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

echo "⚙️ Setting up Unix shell..."

DOTFILES=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

ln -sf "$DOTFILES/.bashrc" ~/.bashrc
ln -sf "$DOTFILES/.zshrc" ~/.zshrc
ln -sf "$DOTFILES/.shell_common.sh" ~/.shell_common
ln -sf "$DOTFILES/.shell_theme_common.ps1" ~/.shell_theme_common

echo "🐍 Installing pyenv (Python version manager)..."
if ! command -v pyenv &> /dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install pyenv pyenv-virtualenv
            echo "✅ pyenv installed via Homebrew"
        else
            curl https://pyenv.run | bash
            echo "✅ pyenv installed via pyenv installer"
        fi
    else
        # Linux
        curl https://pyenv.run | bash
        echo "✅ pyenv installed via pyenv installer"
    fi
else
    echo "✅ pyenv already installed"
fi

if ! command -v oh-my-posh &> /dev/null; then
    curl -s https://ohmyposh.dev/install.sh | bash -s
fi
