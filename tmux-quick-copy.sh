#!/usr/bin/env bash

# Enable logging
LOG_FILE="/tmp/tmux-quick-copy.log"
exec 2>"$LOG_FILE"
set -x

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="${CURRENT_DIR}/target/release/tmux-quick-copy"
CONTENT_FILE="/tmp/tmux-quick-copy-content-$$"
RESULT_FILE="/tmp/tmux-quick-copy-result-$$"

echo "=== tmux-quick-copy debug log ===" >&2
echo "Timestamp: $(date)" >&2

# Cleanup function
cleanup() {
    rm -f "$CONTENT_FILE" "$RESULT_FILE"
}
trap cleanup EXIT

# Check if binary exists
if [ ! -f "$BINARY" ]; then
    echo "Error: Binary not found at $BINARY" >&2
    tmux display-message "Error: Binary not found"
    exit 1
fi

# Get the active pane
PANE_ID=$(tmux display-message -p '#{pane_id}')
echo "PANE_ID: $PANE_ID" >&2

# Capture visible pane content
tmux capture-pane -p -t "$PANE_ID" > "$CONTENT_FILE"
echo "Content captured: $(wc -l < "$CONTENT_FILE") lines" >&2

# Check tmux version for popup support (3.2+)
TMUX_VERSION=$(tmux -V | cut -d' ' -f2 | tr -d '[:alpha:]')
echo "TMUX_VERSION: $TMUX_VERSION" >&2

# Run command in popup or new window
RUN_CMD="cat '$CONTENT_FILE' | '$BINARY' > '$RESULT_FILE' 2>>'$LOG_FILE' || true"

if awk -v ver="$TMUX_VERSION" 'BEGIN {exit !(ver >= 3.2)}'; then
    # Use popup for seamless overlay (tmux 3.2+)
    echo "Using popup approach" >&2
    tmux display-popup -E -w 100% -h 100% "$RUN_CMD"
else
    # Use pane swap for older tmux versions
    echo "Using swap-pane approach" >&2

    # Create new window
    tmux new-window -d -n "tmux-quick-copy" "$RUN_CMD"
    TEMP_PANE=$(tmux display-message -p -t "tmux-quick-copy" '#{pane_id}')
    echo "TEMP_PANE: $TEMP_PANE" >&2

    # Swap with current pane for seamless appearance
    tmux swap-pane -s "$TEMP_PANE" -t "$PANE_ID"

    # Wait for completion
    while tmux list-panes -t "tmux-quick-copy" 2>/dev/null | grep -q .; do
        sleep 0.1
    done

    # Swap back (window already closed, pane returns to original position)
    echo "Binary completed" >&2
fi

# Read result
if [ -f "$RESULT_FILE" ] && [ -s "$RESULT_FILE" ]; then
    SELECTED=$(cat "$RESULT_FILE")
    echo "SELECTED: $SELECTED" >&2
    echo "$SELECTED" | tmux load-buffer -
    tmux display-message "Copied: $SELECTED"
else
    echo "No selection" >&2
    tmux display-message "No selection"
fi

echo "=== End of log ===" >&2
