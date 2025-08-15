#!/usr/bin/env bash
# Simple test for reading .env file

set -euo pipefail

echo "Testing simple read of .env file..."

# Always use a temp file to avoid leaking real secrets
env_file="$(mktemp -t env.XXXXXX)"
cat > "$env_file" <<'EOF'
FOO=bar
BAR=baz value
EMPTY=
# comment
EOF

# Handle: CRLF values, comments, and final line without trailing newline
line_num=0
while IFS='=' read -r key value || [[ -n "$key" ]]; do
  # normalize Windows line endings
  value="${value%$'\r'}"
  # skip blank and comment lines
  [[ -z "${key// /}" || "${key:0:1}" == "#" ]] && continue
  ((line_num++))
  echo "Line $line_num: Key: '$key', Value: '$value'"
done < "$env_file"

rm -f "$env_file"
echo "PASS: simple-read-test"
