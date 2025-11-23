#!/usr/bin/env bash
set -e

# tmux-quick-copy installer
# Usage: curl -fsSL https://raw.githubusercontent.com/tapthaker/tmux-quick-copy/main/install.sh | bash

REPO="tapthaker/tmux-quick-copy"
INSTALL_DIR="${TMUX_PLUGIN_MANAGER_PATH:-$HOME/.tmux/plugins}/tmux-quick-copy"
BIN_DIR="${INSTALL_DIR}"

echo "Installing tmux-quick-copy..."

# Detect platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
    linux)
        OS_NAME="linux"
        ;;
    darwin)
        OS_NAME="darwin"
        ;;
    *)
        echo "Unsupported operating system: $OS"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64)
        if [ "$OS_NAME" = "linux" ]; then
            PLATFORM="x86_64-unknown-linux-gnu"
        else
            echo "Unsupported architecture for macOS: $ARCH (only arm64 is supported)"
            exit 1
        fi
        ;;
    arm64|aarch64)
        if [ "$OS_NAME" = "linux" ]; then
            PLATFORM="aarch64-unknown-linux-gnu"
        else
            PLATFORM="aarch64-apple-darwin"
        fi
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Detected platform: $PLATFORM"

# Get latest release version
echo "Fetching latest release..."
VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
    echo "Failed to fetch latest version"
    exit 1
fi

echo "Latest version: $VERSION"

# Download binary
BINARY_NAME="tmux-quick-copy-${VERSION}-${PLATFORM}"
DOWNLOAD_URL="https://github.com/$REPO/releases/download/v${VERSION}/${BINARY_NAME}"

echo "Downloading from $DOWNLOAD_URL..."

# Create installation directory
mkdir -p "$BIN_DIR"

# Download binary
if ! curl -fsSL "$DOWNLOAD_URL" -o "$BIN_DIR/tmux-quick-copy"; then
    echo "Failed to download binary"
    exit 1
fi

# Make it executable
chmod +x "$BIN_DIR/tmux-quick-copy"

# Download plugin file
echo "Downloading plugin file..."
curl -fsSL "https://raw.githubusercontent.com/$REPO/main/tmux-quick-copy.tmux" -o "$INSTALL_DIR/tmux-quick-copy.tmux"
chmod +x "$INSTALL_DIR/tmux-quick-copy.tmux"

echo ""
echo "✓ tmux-quick-copy installed successfully to $INSTALL_DIR"
echo ""
echo "To use it, add this to your ~/.tmux.conf:"
echo ""
echo "  run-shell $INSTALL_DIR/tmux-quick-copy.tmux"
echo ""
echo "Or if using TPM, add:"
echo ""
echo "  set -g @plugin 'tapthaker/tmux-quick-copy'"
echo ""
echo "Default key binding: prefix + Space"
echo "Customize with: set -g @quick-copy-key 'Space'"
echo ""
