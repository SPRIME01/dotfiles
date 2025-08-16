#!/usr/bin/env bash
# Diagnose shell startup issues for dotfiles
set -euo pipefail

echo "🔍 Diagnosing shell startup..."

# Check for common files
for f in ~/.bashrc ~/.zshrc ~/.shell_common ~/.shell_functions ~/.shell_theme_common; do
	if [[ -f "$f" ]]; then
		echo "✅ Found $f"
	else
		echo "❌ Missing $f"
	fi
done

echo "---"
# Check for Oh My Zsh and Oh My Posh
if command -v omz >/dev/null 2>&1 || [[ -d ~/.oh-my-zsh ]]; then
	echo "✅ Oh My Zsh installed"
else
	echo "❌ Oh My Zsh not found"
fi
if command -v oh-my-posh >/dev/null 2>&1; then
	echo "✅ Oh My Posh installed"
else
	echo "❌ Oh My Posh not found"
fi

echo "---"
# Check for errors in last shell session
if [[ -f ~/.zsh_history ]]; then
	tail -n 20 ~/.zsh_history | grep -i error || echo "No recent errors in zsh history."
fi

echo "---"
echo "Shell diagnosis complete."
