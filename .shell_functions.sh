#!/bin/bash
# dotfiles/.shell_functions.sh
# Shared shell functions for both bash and zsh
# Version: 1.0
# Last Modified: July 20, 2025

# Create and enter directory
take() {
	mkdir -p "$1" && cd "$1" || return
}

# Quick git commit with message
qcommit() {
	if [ -z "$1" ]; then
		echo "Usage: qcommit 'commit message'"
		return 1
	fi
	git add . && git commit -m "$1"
}

# Quick project navigation
proj() {
	if [ -z "$1" ]; then
		cd "$PROJECTS_ROOT" && ls || return
	else
		cd "$PROJECTS_ROOT/$1" || return
	fi
}

# Find and kill process by port
killport() {
	if [ -z "$1" ]; then
		echo "Usage: killport <port>"
		return 1
	fi
	local pid
	pid="$(lsof -t -i:"$1" 2>/dev/null || true)"
	if [ -n "$pid" ]; then
		kill -9 "$pid"
		echo "Killed process $pid running on port $1"
	else
		echo "No process found running on port $1"
	fi
}

# Extract various archive formats
extract() {
	if [ -f "$1" ]; then
		case $1 in
		*.tar.bz2) tar xjf "$1" ;;
		*.tar.gz) tar xzf "$1" ;;
		*.bz2) bunzip2 "$1" ;;
		*.rar) unrar x "$1" ;;
		*.gz) gunzip "$1" ;;
		*.tar) tar xf "$1" ;;
		*.tbz2) tar xjf "$1" ;;
		*.tgz) tar xzf "$1" ;;
		*.zip) unzip "$1" ;;
		*.Z) uncompress "$1" ;;
		*.7z) 7z x "$1" ;;
		*) echo "'$1' cannot be extracted via extract()" ;;
		esac
	else
		echo "'$1' is not a valid file"
	fi
}

# Get current public IP
myip() {
	curl -s ifconfig.me
}

# Quick weather check
weather() {
	local city="${1:-}"
	curl -s "wttr.in/${city}?format=3"
}

# Create a backup of a file with timestamp
backup() {
	if [ -z "$1" ]; then
		echo "Usage: backup <filename>"
		return 1
	fi
	cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
}

# Quick directory size
dirsize() {
	du -sh "${1:-.}" | cut -f1
}

# Find large files
findlarge() {
	local size="${1:-100M}"
	local path="${2:-.}"
	find "$path" -type f -size +"$size" -exec ls -lh {} \; | awk '{ print $9 ": " $5 }'
}

# Quick grep with common options
qgrep() {
	if [ -z "$1" ]; then
		echo "Usage: qgrep <pattern> [path]"
		return 1
	fi
	local pattern="$1"
	local path="${2:-.}"
	grep -r --include="*.js" --include="*.ts" --include="*.py" --include="*.sh" --include="*.md" --include="*.txt" -n "$pattern" "$path"
}

# Docker helper functions
# Unalias dps if it exists (from Oh My Zsh docker plugin)
unalias dps 2>/dev/null
dps() {
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

dlogs() {
	if [ -z "$1" ]; then
		echo "Usage: dlogs <container_name>"
		return 1
	fi
	docker logs -f "$1"
}

dexec() {
	if [ -z "$1" ]; then
		echo "Usage: dexec <container_name> [command]"
		return 1
	fi
	local cmd="${2:-bash}"
	docker exec -it "$1" "$cmd"
}

# Git helper functions
# Unalias gclean if it exists (from Oh My Zsh git plugin)
unalias gclean 2>/dev/null
gclean() {
gclean() {
	echo "Cleaning up Git repository..."
	git fetch --prune
	# Remove fully merged local branches, excluding primary branches
	git branch --merged \
		| grep -Ev '^\*| (main|master|develop)$' \
		| sed 's/^[[:space:]]*//' \
		| while read -r b; do git branch -d "$b"; done
	git gc --aggressive --prune=now
}

gundo() {
	git reset --soft HEAD~1
}

# NPM/Node helper functions
npmglobal() {
	npm list -g --depth=0
}

nodecheck() {
	echo "Node version: $(node --version)"
	echo "NPM version: $(npm --version)"
	if command -v yarn >/dev/null; then
		echo "Yarn version: $(yarn --version)"
	fi
	if command -v pnpm >/dev/null; then
		echo "PNPM version: $(pnpm --version)"
	fi
}

# System information
sysinfo() {
	echo "=== System Information ==="
	echo "OS: $(uname -s)"
	echo "Kernel: $(uname -r)"
	echo "Architecture: $(uname -m)"
	echo "Hostname: $(hostname)"
	echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
	echo "Memory: $(free -h 2>/dev/null | grep Mem | awk '{print $3 "/" $2}' || echo 'N/A')"
	echo "Disk: $(df -h . | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
	echo "Shell: $SHELL"
	echo "User: $USER"
}

# MCP helper functions
mcpstatus() {
	if [ -f "$DOTFILES_ROOT/mcp/servers.json" ]; then
		echo "🔧 MCP Servers Configuration:"
		jq '.' "$DOTFILES_ROOT/mcp/servers.json" 2>/dev/null || cat "$DOTFILES_ROOT/mcp/servers.json"
	else
		echo "⚠️  MCP servers.json not found"
	fi
}

mcpenv() {
	echo "🌍 MCP Environment Variables:"
	env | grep -i mcp | sort
}

# VS Code helper
codehere() {
	code "${1:-.}"
}

# Quick note taking
note() {
	local note_file
	note_file="$HOME/notes/$(date +%Y-%m-%d).md"
	mkdir -p "$(dirname "$note_file")"
	if [ -z "$1" ]; then
		${EDITOR:-vim} "$note_file"
	else
		echo "$(date '+%H:%M:%S') - $*" >>"$note_file"
		echo "Note added to $note_file"
	fi
}
