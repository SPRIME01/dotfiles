#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit && pwd)"
TMP_HOME=$(mktemp -d)
export HOME="$TMP_HOME"

trap 'rm -rf "$TMP_HOME"' EXIT
run_bootstrap() { ZSH= NO_NETWORK=1 OMP_VERSION=skip bash "$ROOT/bootstrap.sh" >/dev/null 2>&1; }

HELPER="$ROOT/test/helpers/state_snapshot.sh"
if [[ ! -x $HELPER ]]; then
	echo "FAIL: snapshot helper missing"
	exit 1
fi

if ! run_bootstrap; then
	echo "FAIL: bootstrap first run failed"
	exit 1
fi
if ! "$HELPER" "$HOME" 3 >"$TMP_HOME/snapshot1.txt"; then
	echo "FAIL: snapshot helper failed (first run)"
	exit 1
fi
snapshot1="$(<"$TMP_HOME/snapshot1.txt")"
if [[ ! "$snapshot1" =~ ^[[:xdigit:]]{64}$ ]]; then
	echo "FAIL: invalid snapshot hash (first run)"
	exit 1
fi
if ! run_bootstrap; then
	echo "FAIL: bootstrap second run failed"
	exit 1
fi
if ! "$HELPER" "$HOME" 3 >"$TMP_HOME/snapshot2.txt"; then
	echo "FAIL: snapshot helper failed (second run)"
	exit 1
fi
snapshot2="$(<"$TMP_HOME/snapshot2.txt")"
if [[ ! "$snapshot2" =~ ^[[:xdigit:]]{64}$ ]]; then
	echo "FAIL: invalid snapshot hash (second run)"
	exit 1
fi

if [[ "$snapshot1" != "$snapshot2" ]]; then
	# Debug: show the file listings that produced each hash
	list1="$TMP_HOME/list1.txt"
	list2="$TMP_HOME/list2.txt"
	find "$HOME" -maxdepth 3 \( -name '*.log' -o -name '*.cache' -o -name 'history' -o -name '.zcompdump*' \) -prune -o \( -type f -o -type l -o -type d \) -print | sed -e "s#^$HOME/*##" | LC_ALL=C sort >"$list1"
	# Re-run second snapshot listing explicitly to capture state
	find "$HOME" -maxdepth 3 \( -name '*.log' -o -name '*.cache' -o -name 'history' -o -name '.zcompdump*' \) -prune -o \( -type f -o -type l -o -type d \) -print | sed -e "s#^$HOME/*##" | LC_ALL=C sort >"$list2"
	echo "FAIL: bootstrap not idempotent (hash mismatch)"
	echo "  snapshot1=$snapshot1"
	echo "  snapshot2=$snapshot2"
	echo "  diff (list1 vs list2):"
	diff -u "$list1" "$list2" || true
	exit 1
fi

echo "PASS: bootstrap idempotent"
