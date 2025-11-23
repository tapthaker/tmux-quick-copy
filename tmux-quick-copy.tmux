#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default key binding: prefix + Space
KEY_BINDING=$(tmux show-option -gqv @quick-copy-key)
KEY_BINDING=${KEY_BINDING:-Space}

# Bind the key
tmux bind-key "$KEY_BINDING" run-shell "$CURRENT_DIR/tmux-quick-copy.sh"
