#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default key binding: prefix + Space
KEY_BINDING=$(tmux show-option -gqv @quick-copy-key)
KEY_BINDING=${KEY_BINDING:-Space}

# Function to auto-install binary
auto_install_binary() {
    # Detect platform
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case "$OS" in
        linux) OS_NAME="linux" ;;
        darwin) OS_NAME="darwin" ;;
        *) return 1 ;;
    esac

    case "$ARCH" in
        x86_64|amd64)
            [ "$OS_NAME" = "linux" ] && PLATFORM="x86_64-unknown-linux-gnu" || return 1
            ;;
        arm64|aarch64)
            [ "$OS_NAME" = "linux" ] && PLATFORM="aarch64-unknown-linux-gnu" || PLATFORM="aarch64-apple-darwin"
            ;;
        *) return 1 ;;
    esac

    # Get latest release
    REPO="tapthaker/tmux-quick-copy"
    VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')

    [ -z "$VERSION" ] && return 1

    # Download binary
    BINARY_NAME="tmux-quick-copy-${VERSION}-${PLATFORM}"
    DOWNLOAD_URL="https://github.com/$REPO/releases/download/v${VERSION}/${BINARY_NAME}"

    if curl -fsSL "$DOWNLOAD_URL" -o "$CURRENT_DIR/tmux-quick-copy" 2>/dev/null; then
        chmod +x "$CURRENT_DIR/tmux-quick-copy"
        return 0
    fi

    return 1
}

# Find the binary (prefer system-installed, fallback to local build)
if command -v tmux-quick-copy &> /dev/null; then
    BINARY="tmux-quick-copy"
elif [ -f "$CURRENT_DIR/tmux-quick-copy" ]; then
    BINARY="$CURRENT_DIR/tmux-quick-copy"
elif [ -f "$CURRENT_DIR/target/release/tmux-quick-copy" ]; then
    BINARY="$CURRENT_DIR/target/release/tmux-quick-copy"
else
    # Try to auto-install
    tmux display-message "tmux-quick-copy: Binary not found, attempting auto-install..."
    if auto_install_binary; then
        BINARY="$CURRENT_DIR/tmux-quick-copy"
        tmux display-message "tmux-quick-copy: Successfully installed!"
    else
        tmux display-message "tmux-quick-copy: Auto-install failed. Please run: curl -fsSL https://raw.githubusercontent.com/tapthaker/tmux-quick-copy/main/install.sh | bash"
        exit 1
    fi
fi

# Bind the key to run binary in tmux mode
tmux bind-key "$KEY_BINDING" run-shell "$BINARY tmux"
