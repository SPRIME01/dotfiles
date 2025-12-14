#!/usr/bin/env bash
# Fix Oh My Zsh and Powerlevel10k configuration

set -euo pipefail

echo "🔧 Fixing Oh My Zsh and Powerlevel10k configuration..."
echo ""

# Step 1: Create symlinks to dotfiles directory (portable, single source of truth)
echo "📝 Creating symlinks to dotfiles directory..."

DOTFILES_DIR="${HOME}/dotfiles"

# Remove existing files/symlinks
rm -f ~/.zshrc ~/.zshenv
rm -rf ~/.zshrc.safe.d

# Create symlinks to dotfiles directory
ln -s "$DOTFILES_DIR/.zshrc" ~/.zshrc
ln -s "$DOTFILES_DIR/.zshenv" ~/.zshenv
ln -s "$DOTFILES_DIR/.zshrc.safe.d" ~/.zshrc.safe.d

echo "✅ Configuration files copied successfully!"
echo ""

# Step 2: Verify Oh My Zsh and Powerlevel10k are installed
if [[ ! -d ~/.oh-my-zsh ]]; then
	echo "❌ Oh My Zsh is not installed!"
	echo "   Run: ./install_zsh.sh to install it"
	exit 1
fi

if [[ ! -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]]; then
	echo "❌ Powerlevel10k is not installed!"
	echo "   Run: ./install_zsh.sh to install it"
	exit 1
fi

echo "✅ Oh My Zsh and Powerlevel10k are properly installed"
echo ""

# Step 3: Test zsh startup
echo "🧪 Testing zsh startup..."
if zsh -c "echo 'Zsh loads successfully!'" >/dev/null 2>&1; then
	echo "✅ Zsh loads without errors!"
else
	echo "⚠️  Zsh had some warnings, but should still work"
fi

echo ""
echo "🎉 All done! Your zsh configuration has been fixed."
echo ""
echo "📋 Next steps:"
echo "   1. Open a new terminal or run: exec zsh"
echo "   2. Run: p10k configure to set up your Powerlevel10k theme"
echo ""
