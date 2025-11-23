# Release Checklist

## Prerequisites
- GitHub repository created at `github.com/tapthaker/tmux-quick-copy`
- All code pushed to `main` branch

## Release Steps

### 1. Verify everything works locally
```bash
cargo build --release
./target/release/tmux-quick-copy tmux  # Test tmux mode
```

### 2. Commit and push all changes
```bash
git add .
git commit -m "Release v0.1.0"
git push origin main
```

### 3. Create and push a release tag
```bash
git tag v0.1.0
git push origin v0.1.0
```

### 4. GitHub Actions automatically:
- Builds binaries for all platforms (x86_64-linux, aarch64-linux, aarch64-macos)
- Creates GitHub release at `https://github.com/tapthaker/tmux-quick-copy/releases`
- Uploads all binaries to the release

### 5. Verify the release
- Check `https://github.com/tapthaker/tmux-quick-copy/releases/latest`
- Verify all 3 binaries are attached

### 6. Test the curl install
```bash
curl -fsSL https://raw.githubusercontent.com/tapthaker/tmux-quick-copy/main/install.sh | bash
```

## Installation Methods (for users)

### Standalone Install
```bash
curl -fsSL https://raw.githubusercontent.com/tapthaker/tmux-quick-copy/main/install.sh | bash
```

Add to `~/.tmux.conf`:
```tmux
run-shell ~/.tmux/plugins/tmux-quick-copy/tmux-quick-copy.tmux
```

### TPM Install
Add to `~/.tmux.conf`:
```tmux
set -g @plugin 'tapthaker/tmux-quick-copy'
```

Press `prefix + I` to install.

## What Happens Automatically

1. **curl install**: Downloads pre-built binary + plugin file → ready to use
2. **TPM install**: Clones repo → `.tmux` file auto-downloads binary on first load → ready to use

No manual building required for users!
