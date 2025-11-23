# tmux-quick-copy

⚡ A fast tmux copy plugin - optimized for instant pattern matching and copying.

## Features

- **Fast**: Optimized for speed with minimal pattern matching
- **Focused Patterns**: URLs, paths, git SHAs, IPs
- **Visible Content Only**: Processes only what you see on screen
- **Simple Hints**: Single-character homerow-optimized hints

## Installation

### Requirements

- tmux 2.1+
- Rust 1.70+
- cargo

### Build

```bash
cargo build --release
```

### tmux Plugin Manager (TPM)

Add to your `.tmux.conf`:

```tmux
set -g @plugin 'tapthaker/tmux-quick-copy'
```

Then press `prefix + I` to install.

### Manual Installation

1. Clone this repository:
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

## Usage

1. Press `prefix + Space` (default binding)
2. See hints overlaid on URLs, paths, and other patterns
3. Press the hint character to copy instantly
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

## License

MIT

## Credits

Inspired by [tmux-thumbs](https://github.com/fcsonline/tmux-thumbs).
