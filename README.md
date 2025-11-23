# tmux-quick-copy

⚡ A fast tmux copy plugin - optimized for instant pattern matching and copying.

## Features

- **Fast**: Optimized for speed with minimal pattern matching
- **Focused Patterns**: URLs, paths, git SHAs, IPs
- **Visible Content Only**: Processes only what you see on screen
- **Simple Hints**: Single-character homerow-optimized hints

## Installation

### Quick Install (Recommended)

Install with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/tapthaker/tmux-quick-copy/main/install.sh | bash
```

Then add to your `.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-quick-copy/tmux-quick-copy.tmux
```

Reload tmux config:
```bash
tmux source-file ~/.tmux.conf
```

### tmux Plugin Manager (TPM)

Add to your `.tmux.conf`:

```tmux
set -g @plugin 'tapthaker/tmux-quick-copy'
```

Then press `prefix + I` to install.

### Manual Installation (Building from Source)

Requirements:
- Rust 1.70+
- cargo

1. Clone and build:
   ```bash
   git clone https://github.com/tapthaker/tmux-quick-copy.git ~/.tmux/plugins/tmux-quick-copy
   cd ~/.tmux/plugins/tmux-quick-copy
   cargo build --release
   ```

2. Add to your `.tmux.conf`:
   ```tmux
   run-shell ~/.tmux/plugins/tmux-quick-copy/tmux-quick-copy.tmux
   ```

3. Reload tmux config:
   ```bash
   tmux source-file ~/.tmux.conf
   ```

### Supported Platforms

Pre-built binaries are available for:
- Linux x86_64 (amd64)
- Linux ARM64 (aarch64)
- macOS ARM64 (Apple Silicon)

## Usage

1. Press `prefix + Space` (default binding)
2. See hints overlaid on URLs, paths, and other patterns
3. Press the hint character to copy:
   - **lowercase** letter: copy to tmux buffer and show message
   - **UPPERCASE** letter: copy to tmux buffer and paste immediately
4. Press `q` or `Esc` to cancel

## Configuration

### Change Key Binding

```tmux
set -g @quick-copy-key 'C-s'
```

## Patterns Detected

- HTTP/HTTPS URLs
- File paths (absolute, relative, ~)
- Git commit SHAs (7-40 chars)
- IPv4 addresses
- Git status output
- Process IDs from ps output

## Development

### Building for Multiple Platforms

The project includes a build script to create release binaries for all supported platforms:

```bash
./build-release.sh
```

This will create binaries in the `release/` directory for:
- x86_64-unknown-linux-gnu
- aarch64-unknown-linux-gnu
- aarch64-apple-darwin

**Note**: Cross-compilation requires either:
- [cross](https://github.com/cross-rs/cross): `cargo install cross`
- Or proper Rust toolchains installed for each target

### Binary Modes

The `tmux-quick-copy` binary has two modes:

1. **tmux mode** (`tmux-quick-copy tmux`): Full integration mode that captures pane content, shows selector, and handles tmux buffer operations
2. **selector mode** (default): Reads content from stdin, shows selector, outputs selection to stdout

## License

MIT

## Credits

Inspired by [tmux-thumbs](https://github.com/fcsonline/tmux-thumbs).
