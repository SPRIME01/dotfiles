#!/usr/bin/env bash
set -euo pipefail
mkdir -p ~/.ssh/backup
find ~/.ssh -maxdepth 1 -type f -name 'id_*' ! -name '*.pub' -print -exec mv -v {} ~/.ssh/backup/ \;
sudo chown -R "$USER:$USER" ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config 2>/dev/null || true
chmod 600 ~/.ssh/authorized_keys 2>/dev/null || true
chmod 644 ~/.ssh/*.pub 2>/dev/null || true
chmod 644 ~/.ssh/known_hosts 2>/dev/null || true
echo "WSL SSH folder cleaned. Make sure ~/.ssh/config uses IdentityAgent ~/.ssh/agent.sock and has no IdentityFile pointing to WSL private keys."
