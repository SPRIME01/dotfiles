# Path configuration for zsh
#
# This file adds Volta and PNPM to the PATH.  Paths are computed from
# environment variables or default locations relative to $HOME.

# Local bin directory (for oh-my-posh and other user-installed tools)
if [[ -d "$HOME/.local/bin" ]]; then
	case ":$PATH:" in
	*":$HOME/.local/bin:"*) ;;
	*) export PATH="$HOME/.local/bin:$PATH" ;;
	esac
fi

# Volta (Node version manager) - PATH injection deprecated in favor of Mise
if [[ -d "$HOME/.volta" ]]; then
	export VOLTA_HOME="$HOME/.volta"
fi

# Pulumi (Infrastructure as Code)
if [[ -d "$HOME/.pulumi/bin" ]]; then
	case ":$PATH:" in
	*":$HOME/.pulumi/bin:"*) ;;
	*) export PATH="$HOME/.pulumi/bin:$PATH" ;;
	esac
fi

# PNPM
# Set PNPM_HOME to the default location if not already set.
export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
# Add PNPM_HOME to PATH so that the pnpm binary is available
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

# If the PNPM global bin directory exists, add it to PATH (higher priority)
if [[ -d "$PNPM_HOME/global" ]]; then
	# Find the first nested node_modules/.bin directory under the global folder
	pnpm_bin_dir=$(find "$PNPM_HOME/global" -type d -path "*/node_modules/.bin" -print -quit 2>/dev/null)
	if [[ -n "$pnpm_bin_dir" ]]; then
		case ":$PATH:" in
		*":$pnpm_bin_dir:"*) ;;
		*) export PATH="$pnpm_bin_dir:$PATH" ;;
		esac
	fi
fi
