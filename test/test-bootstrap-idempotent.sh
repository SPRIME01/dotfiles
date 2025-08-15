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
	echo "FAIL: bootstrap not idempotent (hash mismatch)"
	exit 1
fi

echo "PASS: bootstrap idempotent"
