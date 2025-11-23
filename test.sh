#!/usr/bin/env bash

# Simple test script to verify the binary works
# This should be run from within a tmux session

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="${CURRENT_DIR}/target/release/tmux-quick-copy"

if [ ! -f "$BINARY" ]; then
    echo "Binary not found. Building..."
    cargo build --release
fi

echo "Testing pattern matching..."
echo ""
echo "Sample content:"
echo "  URL: https://github.com/tapthaker/tmux-quick-copy"
echo "  Path: /home/user/config.txt"
echo "  IP: 192.168.1.100"
echo "  SHA: a1b2c3d4e5f67890123456"
echo ""
echo "To test in tmux:"
echo "1. Add to .tmux.conf: run-shell $CURRENT_DIR/tmux-quick-copy.tmux"
echo "2. Reload: tmux source-file ~/.tmux.conf"
echo "3. Press: prefix + Space"
