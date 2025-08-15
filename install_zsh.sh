#!/bin/bash
# dotfiles/install_zsh.sh
# Install Oh My Zsh and plugins for WSL2/Linux
# Version: 1.0
# Last Modified: July 20, 2025

set -e

echo "🐚 Installing Oh My Zsh and plugins..."

# Function to check if command exists
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Install Zsh if not already installed
if ! command_exists zsh; then
	# Ensure required tools are available
	for tool in curl git; do
	  if ! command_exists "$tool"; then
	    echo "📦 Installing missing dependency: $tool..."
	    if command_exists apt; then
	      sudo apt update && sudo apt install -y "$tool"
	    elif command_exists yum; then
	      sudo yum install -y "$tool"
	    elif command_exists dnf; then
	      sudo dnf install -y "$tool"
	    elif command_exists pacman; then
	      sudo pacman -Sy --noconfirm && sudo pacman -S --noconfirm --needed "$tool"
	    else
	      echo "❌ Missing $tool and no supported package manager found." >&2
	      exit 1
	    fi
	  fi
	done

	echo "📦 Installing Zsh..."
	if command_exists apt; then
		sudo apt update && sudo apt install -y zsh curl git
	elif command_exists yum; then
		sudo yum install -y zsh curl git
	elif command_exists dnf; then
		sudo dnf install -y zsh curl git
	elif command_exists pacman; then
		# Ensure package database is up to date and avoid prompts
		sudo pacman -Sy --noconfirm
		sudo pacman -S --noconfirm --needed zsh curl git
	else
		echo "❌ Could not detect package manager. Please install zsh manually."
		exit 1
	fi
fi

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
	echo "📦 Installing Oh My Zsh..."
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
	echo "✅ Oh My Zsh already installed"
fi

# Set ZSH_CUSTOM directory
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

# Install Powerlevel10k theme
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
	echo "🎨 Installing Powerlevel10k theme..."
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
else
	echo "✅ Powerlevel10k theme already installed"
fi

# Install zsh-autosuggestions plugin
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
	echo "💡 Installing zsh-autosuggestions..."
	git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
	echo "✅ zsh-autosuggestions already installed"
fi

# Install zsh-syntax-highlighting plugin
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
	echo "🌈 Installing zsh-syntax-highlighting..."
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
	echo "✅ zsh-syntax-highlighting already installed"
fi

# Install zsh-history-substring-search plugin
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
	echo "🔍 Installing zsh-history-substring-search..."
	git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
else
	echo "✅ zsh-history-substring-search already installed"
fi

# Backup existing .zshrc if it exists and is not a symlink
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
	echo "💾 Backing up existing .zshrc to .zshrc.backup"
	mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi

# Create symlink to our .zshrc
echo "🔗 Creating symlink for .zshrc..."
ln -sf "$HOME/dotfiles/.zshrc" "$HOME/.zshrc"

# Install recommended fonts for Powerlevel10k
echo "🔤 Installing recommended fonts..."
if [ -d "$HOME/.local/share/fonts" ] || mkdir -p "$HOME/.local/share/fonts"; then
	cd "$HOME/.local/share/fonts"

	# Download MesloLGS NF fonts (recommended by Powerlevel10k)
	fonts=(
		"MesloLGS%20NF%20Regular.ttf"
		"MesloLGS%20NF%20Bold.ttf"
		"MesloLGS%20NF%20Italic.ttf"
		"MesloLGS%20NF%20Bold%20Italic.ttf"
	)

	for font in "${fonts[@]}"; do
		font_name=$(echo "$font" | sed 's/%20/ /g')
		if [ ! -f "$font_name" ]; then
			echo "📥 Downloading $font_name..."
			curl -fLo "$font_name" "https://github.com/romkatv/powerlevel10k-media/raw/master/$font"
		fi
	done

	# Refresh font cache
	if command_exists fc-cache; then
		fc-cache -fv
		echo "✅ Font cache refreshed"
	fi
fi

# Set Zsh as default shell if not already set
if [ "$SHELL" != "$(which zsh)" ]; then
	echo "🔧 Setting Zsh as default shell..."
	if chsh -s "$(which zsh)"; then
		echo "✅ Default shell changed to Zsh"
	else
		echo "⚠️  Could not change default shell. You may need to run 'chsh -s $(which zsh)' manually"
	fi
fi

echo ""
echo "✅ Oh My Zsh installation complete!"
echo ""
echo "📋 Next steps:"
echo "   1. 🔄 Restart your terminal or run 'exec zsh'"
echo "   2. ⚡ Run 'p10k configure' to configure Powerlevel10k theme"
echo "   3. 🔤 Set your terminal font to 'MesloLGS NF' for best experience"
echo "   4. 🎨 Customize your .zshrc as needed"
echo ""
echo "💡 Tips:"
echo "   - Use Ctrl+Space for autocompletion"
echo "   - Use Up/Down arrows for history substring search"
echo "   - Type 'take <dirname>' to create and enter a directory"
echo "   - Use 'gst' for git status, 'gco' for git checkout, etc."
