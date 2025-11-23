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

# Get pane position and dimensions
PANE_LEFT=$(tmux display-message -p '#{pane_left}')
PANE_TOP=$(tmux display-message -p '#{pane_top}')
PANE_WIDTH=$(tmux display-message -p '#{pane_width}')
PANE_HEIGHT=$(tmux display-message -p '#{pane_height}')
echo "PANE: left=$PANE_LEFT top=$PANE_TOP width=$PANE_WIDTH height=$PANE_HEIGHT" >&2

# Capture visible pane content
tmux capture-pane -p -t "$PANE_ID" > "$CONTENT_FILE"
echo "Content captured: $(wc -l < "$CONTENT_FILE") lines" >&2

# Run binary in popup positioned exactly over the current pane
echo "Running binary in popup over current pane" >&2
# Get current working directory to exclude from matches (often in prompt)
CURRENT_PWD=$(tmux display-message -p '#{pane_current_path}')
RUN_CMD="cat '$CONTENT_FILE' | PWD='$CURRENT_PWD' '$BINARY' > '$RESULT_FILE' 2>>'$LOG_FILE' || true"
tmux display-popup -E -x "$PANE_LEFT" -y "$PANE_TOP" -w "$PANE_WIDTH" -h "$PANE_HEIGHT" "$RUN_CMD"
echo "Binary completed" >&2

# Read result
if [ -f "$RESULT_FILE" ] && [ -s "$RESULT_FILE" ]; then
    RESULT=$(cat "$RESULT_FILE")
    echo "RESULT: $RESULT" >&2

    # Check if result starts with "PASTE:" prefix
    if [[ "$RESULT" == PASTE:* ]]; then
        # Remove "PASTE:" prefix
        SELECTED="${RESULT#PASTE:}"
        echo "SELECTED (paste mode): $SELECTED" >&2
        printf '%s' "$SELECTED" | tmux load-buffer -
        tmux paste-buffer
    else
        # Just copy to buffer
        echo "SELECTED (copy mode): $RESULT" >&2
        printf '%s' "$RESULT" | tmux load-buffer -
        tmux display-message "Copied: $RESULT"
    fi
else
    echo "No selection (dismissed)" >&2
fi

echo "=== End of log ===" >&2
