#!/usr/bin/env bash
# Description: Simple logging abstraction with levels.
# Category: library
# Usage: source then use log_debug/log_info/log_warn/log_error
# Levels: DEBUG(10) INFO(20) WARN(30) ERROR(40)

: "${LOG_LEVEL:=20}" # default INFO

# Ensure numeric LOG_LEVEL; fallback to INFO
if ! [[ "${LOG_LEVEL}" =~ ^[0-9]+$ ]]; then
	LOG_LEVEL=20
fi

_ts() { date +'%Y-%m-%dT%H:%M:%S'; }

_should_log() {
	local level="$1"
	((level >= LOG_LEVEL))
}

log_debug() { _should_log 10 && echo "[$(_ts)] [DEBUG] $*" >&2; }
log_info() { _should_log 20 && echo "[$(_ts)] [INFO ] $*" >&2; }
log_warn() { _should_log 30 && echo "[$(_ts)] [WARN ] $*" >&2; }
log_error() { _should_log 40 && echo "[$(_ts)] [ERROR] $*" >&2; }

# Map human names to numeric levels if LOG_LEVEL_NAME is exported
if [[ -n "${LOG_LEVEL_NAME:-}" ]]; then
	case "${LOG_LEVEL_NAME^^}" in
	DEBUG) LOG_LEVEL=10 ;;
	INFO) LOG_LEVEL=20 ;;
	WARN) LOG_LEVEL=30 ;;
	ERROR) LOG_LEVEL=40 ;;
	*) echo "[$(_ts)] [WARN ] Unknown LOG_LEVEL_NAME: ${LOG_LEVEL_NAME}" >&2 ;;
	esac
fi
