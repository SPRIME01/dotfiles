#!/bin/bash
# Migration helper script for transitioning to the new modular dotfiles system
# This script helps identify and update any custom scripts or configurations
# that might be using the old system

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}Dotfiles Migration Helper${NC}"
echo "============================================"
echo

# Check for old system usage
echo -e "${YELLOW}Checking for old system usage...${NC}"

# Search for references to old files (targeted search)
OLD_REFERENCES=()

# Function to safely search with timeout
safe_search() {
    local pattern="$1"
    local search_paths="$2"
    local description="$3"

    echo "  Searching for $description..."

    # Use timeout and limit search to common shell config files
    if timeout 10s grep -r "$pattern" $search_paths 2>/dev/null | grep -v "$DOTFILES_ROOT" | head -3 >/dev/null 2>&1; then
        OLD_REFERENCES+=("Found $description")
    fi
}

# Check common shell configuration files only (much faster)
SHELL_CONFIG_PATHS="$HOME/.bashrc $HOME/.zshrc $HOME/.profile $HOME/.bash_profile"

# Check for source commands pointing to old files
safe_search "source.*scripts/load_env.sh" "$SHELL_CONFIG_PATHS" "references to scripts/load_env.sh"

# Check for old function calls
safe_search "load_env_file" "$SHELL_CONFIG_PATHS" "usage of deprecated load_env_file function"

# Check for old directory structure references
safe_search "\\.shell_common" "$SHELL_CONFIG_PATHS" "references to .shell_common.sh"

if [[ ${#OLD_REFERENCES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Found potential migration items:${NC}"
    for ref in "${OLD_REFERENCES[@]}"; do
        echo "  - $ref"
    done
    echo
else
    echo -e "${GREEN}No old system references found in home directory${NC}"
    echo
fi

# Check current system status
echo -e "${YELLOW}Checking current system status...${NC}"

# Check if new system files exist
NEW_SYSTEM_FILES=(
    "lib/env-loader.sh"
    "lib/error-handling.sh"
    "lib/platform-detection.sh"
    "lib/validation.sh"
    "shell/loader.sh"
    "shell/common/aliases.sh"
    "shell/common/functions.sh"
    "shell/common/environment.sh"
)

MISSING_FILES=()
for file in "${NEW_SYSTEM_FILES[@]}"; do
    if [[ ! -f "$DOTFILES_ROOT/$file" ]]; then
        MISSING_FILES+=("$file")
    fi
done

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
    echo -e "${RED}Missing new system files:${NC}"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    echo
    echo -e "${RED}Error: New modular system is not complete. Please run the setup process.${NC}"
    exit 1
else
    echo -e "${GREEN}All new system files are present${NC}"
fi

# Test new system
echo -e "${YELLOW}Testing new system...${NC}"

# Test environment loading
if bash -c "cd '$DOTFILES_ROOT' && source lib/env-loader.sh && load_dotfiles_environment '$DOTFILES_ROOT'" 2>/dev/null; then
    echo -e "${GREEN}Environment loading system: OK${NC}"
else
    echo -e "${RED}Environment loading system: FAILED${NC}"
fi

# Test modular configuration
if bash -c "cd '$DOTFILES_ROOT' && source shell/loader.sh" 2>/dev/null; then
    echo -e "${GREEN}Modular configuration system: OK${NC}"
else
    echo -e "${RED}Modular configuration system: FAILED${NC}"
fi

# Test complete integration
if bash -c "cd '$DOTFILES_ROOT' && source .shell_common.sh" 2>/dev/null; then
    echo -e "${GREEN}Complete integration: OK${NC}"
else
    echo -e "${RED}Complete integration: FAILED${NC}"
fi

echo
echo -e "${BLUE}Migration Recommendations:${NC}"
echo "============================================"

# Provide migration recommendations
echo "1. Update any custom scripts to use the new system:"
echo "   OLD: source scripts/load_env.sh"
echo "   NEW: source lib/env-loader.sh && load_dotfiles_environment \"\$DOTFILES_ROOT\""
echo

echo "2. Update any direct function calls:"
echo "   OLD: load_env_file \"\$file\""
echo "   NEW: load_env_file_secure \"\$file\""
echo

echo "3. Use the new modular configuration:"
echo "   - Common settings: shell/common/"
echo "   - Platform-specific: shell/platform-specific/"
echo "   - Shell-specific: shell/bash/ or shell/zsh/"
echo

echo "4. Test your configuration:"
echo "   bash -c \"cd '$DOTFILES_ROOT' && source .shell_common.sh\""
echo "   zsh -c \"cd '$DOTFILES_ROOT' && source .shell_common.sh\""
echo

# Check shell integration
echo -e "${YELLOW}Checking shell integration...${NC}"

# Check if .bashrc or .zshrc source the dotfiles
SHELL_INTEGRATION=()

if [[ -f "$HOME/.bashrc" ]] && grep -q "\.shell_common\|dotfiles" "$HOME/.bashrc"; then
    SHELL_INTEGRATION+=("bash: Integrated")
elif [[ -f "$HOME/.bashrc" ]]; then
    SHELL_INTEGRATION+=("bash: NOT integrated")
fi

if [[ -f "$HOME/.zshrc" ]] && grep -q "\.shell_common\|dotfiles" "$HOME/.zshrc"; then
    SHELL_INTEGRATION+=("zsh: Integrated")
elif [[ -f "$HOME/.zshrc" ]]; then
    SHELL_INTEGRATION+=("zsh: NOT integrated")
fi

for integration in "${SHELL_INTEGRATION[@]}"; do
    if [[ "$integration" == *"NOT integrated"* ]]; then
        echo -e "${YELLOW}$integration${NC}"
    else
        echo -e "${GREEN}$integration${NC}"
    fi
done

echo
echo -e "${GREEN}Migration check complete!${NC}"

# Offer to run a test
echo
read -p "Would you like to run a test of the new system? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Running test...${NC}"
    echo "Testing environment loading:"
    bash -c "cd '$DOTFILES_ROOT' && source .shell_common.sh && echo 'DOTFILES_ROOT:' \$DOTFILES_ROOT && echo 'GEMINI_API_KEY:' \${GEMINI_API_KEY:0:20}..."
    echo
    echo -e "${GREEN}Test complete!${NC}"
fi
