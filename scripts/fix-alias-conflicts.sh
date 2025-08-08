#!/usr/bin/env bash
# Check for and fix alias/function conflicts in dotfiles
set -euo pipefail

echo "🔍 Checking for alias/function conflicts..."

# Check for duplicate aliases in .shell_common.sh
if grep -E '^alias ' "$HOME/dotfiles/.shell_common.sh" | sort | uniq -d | grep .; then
  echo "❌ Duplicate aliases found in .shell_common.sh. Please resolve manually."
else
  echo "✅ No duplicate aliases in .shell_common.sh."
fi

# Check for duplicate function names in .shell_functions.sh
if grep -E '^([a-zA-Z0-9_]+)\(\) *{' "$HOME/dotfiles/.shell_functions.sh" | awk '{print $1}' | sort | uniq -d | grep .; then
  echo "❌ Duplicate functions found in .shell_functions.sh. Please resolve manually."
else
  echo "✅ No duplicate functions in .shell_functions.sh."
fi

echo "Alias/function conflict check complete."
