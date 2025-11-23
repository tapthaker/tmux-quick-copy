#!/usr/bin/env bash
set -e

VERSION=${1:-$(grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/')}
echo "Building tmux-quick-copy v$VERSION for multiple platforms..."

# Create release directory
RELEASE_DIR="release"
mkdir -p "$RELEASE_DIR"

# Platforms to build for
PLATFORMS=(
    "x86_64-unknown-linux-gnu"
    "aarch64-unknown-linux-gnu"
    "aarch64-apple-darwin"
)

# Check if cross is installed, otherwise use cargo
if command -v cross &> /dev/null; then
    BUILD_CMD="cross"
    echo "Using cross for cross-compilation"
else
    BUILD_CMD="cargo"
    echo "Using cargo (some platforms may not build without proper toolchains)"
fi

# Build for each platform
for platform in "${PLATFORMS[@]}"; do
    echo ""
    echo "Building for $platform..."

    if [ "$BUILD_CMD" = "cargo" ] && [ "$platform" != "$(rustc -vV | grep host | cut -d' ' -f2)" ]; then
        echo "Adding target $platform..."
        rustup target add "$platform" 2>/dev/null || true
    fi

    $BUILD_CMD build --release --target "$platform"

    # Copy binary to release directory with platform suffix
    BINARY_NAME="tmux-quick-copy"
    if [[ "$platform" == *"darwin"* ]]; then
        RELEASE_NAME="${BINARY_NAME}-${VERSION}-${platform}"
    else
        RELEASE_NAME="${BINARY_NAME}-${VERSION}-${platform}"
    fi

    cp "target/$platform/release/$BINARY_NAME" "$RELEASE_DIR/$RELEASE_NAME"
    echo "Created: $RELEASE_DIR/$RELEASE_NAME"
done

echo ""
echo "Build complete! Binaries are in the $RELEASE_DIR directory:"
ls -lh "$RELEASE_DIR"
