#!/bin/bash
# Common functions for all shells and platforms
# Part of the modular dotfiles configuration system

# Create directory and cd into it
mkcd() {
	if [[ $# -ne 1 ]]; then
		echo "Usage: mkcd <directory>"
		return 1
	fi
	mkdir -p "$1" && cd "$1" || return
}

# Extract various archive formats
extract() {
	if [[ $# -ne 1 ]]; then
		echo "Usage: extract <archive>"
		return 1
	fi

	if [[ ! -f "$1" ]]; then
		echo "Error: '$1' is not a valid file"
		return 1
	fi

	case "$1" in
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
	*) echo "Error: '$1' cannot be extracted via extract()" ;;
	esac
}

# Find files by name
ff() {
	if [[ $# -eq 0 ]]; then
		echo "Usage: ff <filename>"
		return 1
	fi
	find . -type f -iname "*$1*" 2>/dev/null
}

# Find directories by name
fd() {
	if [[ $# -eq 0 ]]; then
		echo "Usage: fd <dirname>"
		return 1
	fi
	find . -type d -iname "*$1*" 2>/dev/null
}

# Quick grep with color and line numbers
grepf() {
	if [[ $# -lt 2 ]]; then
		echo "Usage: grepf <pattern> <file>"
		return 1
	fi
	grep -n --color=always "$1" "$2"
}

# Get weather information
weather() {
	local city="${1:-}"
	if [[ -n "$city" ]]; then
		curl -s "wttr.in/$city"
	else
		curl -s "wttr.in"
	fi
}

# Get public IP address
myip() {
	curl -s ifconfig.me
	echo
}

# Create backup of file
backup() {
	if [[ $# -ne 1 ]]; then
		echo "Usage: backup <file>"
		return 1
	fi

	if [[ ! -f "$1" ]]; then
		echo "Error: '$1' is not a valid file"
		return 1
	fi

	local backup_name
	backup_name="${1}.bak.$(date +%Y%m%d_%H%M%S)"
	cp "$1" "$backup_name"
	echo "Backup created: $backup_name"
}

# Quick note taking
note() {
	local note_file
	note_file="$HOME/.notes/$(date +%Y-%m-%d).md"
	mkdir -p "$(dirname "$note_file")"

	if [[ $# -eq 0 ]]; then
		# Open today's note file
		${EDITOR:-vim} "$note_file"
	else
		# Add note with timestamp
		echo "$(date '+%H:%M') - $*" >>"$note_file"
		echo "Note added to $note_file"
	fi
}

# Process management helpers
psg() {
	if [[ $# -eq 0 ]]; then
		echo "Usage: psg <process_name>"
		return 1
	fi
	ps aux | grep -i "$1" | grep -v grep
}

# Memory usage by process
memuse() {
	if [[ $# -eq 0 ]]; then
		echo "Usage: memuse <process_name>"
		return 1
	fi
	ps aux | grep -i "$1" | grep -v grep | awk '{print $4 "% " $11}'
}

# Disk usage in human readable format
usage() {
	if [[ $# -eq 0 ]]; then
		df -h
	else
		du -sh "$1"
	fi
}

# Path manipulation
path_add() {
	if [[ $# -ne 1 ]]; then
		echo "Usage: path_add <directory>"
		return 1
	fi

	if [[ -d "$1" && ":$PATH:" != *":$1:"* ]]; then
		export PATH="$1:$PATH"
		echo "Added $1 to PATH"
	fi
}

path_remove() {
	if [[ $# -ne 1 ]]; then
		echo "Usage: path_remove <directory>"
		return 1
	fi

	local new_path
	new_path=$(echo "$PATH" | sed -e "s|:$1||g" -e "s|$1:||g" -e "s|$1||g")
	export PATH="$new_path"
	echo "Removed $1 from PATH"
}

# Show PATH in readable format
path_show() {
	echo "$PATH" | tr ':' '\n' | nl
}
