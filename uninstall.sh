#!/bin/bash
# shotsmash uninstaller

set -u

PREFIX="${SHOTSMASH_PREFIX:-$HOME/.local}"
BIN_PATH="$PREFIX/bin/shotsmash"
CLIP_BIN_PATH="$PREFIX/bin/shotsmash-clip"
PLIST_PATH="$HOME/Library/LaunchAgents/com.shotsmash.plist"
CLIP_PLIST_PATH="$HOME/Library/LaunchAgents/com.shotsmash.clip.plist"

echo "▸ Unloading LaunchAgents…"
launchctl bootout "gui/$(id -u)/com.shotsmash"      2>/dev/null || true
launchctl bootout "gui/$(id -u)/com.shotsmash.clip" 2>/dev/null || true

echo "▸ Removing plists"
rm -f "$PLIST_PATH" "$CLIP_PLIST_PATH"

echo "▸ Removing binaries"
rm -f "$BIN_PATH" "$CLIP_BIN_PATH"

echo
echo "Kept (delete manually if desired):"
echo "  ~/.config/shotsmash/             — your config"
echo "  ~/.shotsmash/originals/          — original screenshots backup"
echo "  ~/Library/Logs/shotsmash.log     — file mode log"
echo "  ~/Library/Logs/shotsmash-clip.log — clipboard mode log"
echo "  ~/Pictures/Screenshots/          — your screenshots"
echo
echo "Restore default screenshot location with:"
echo "  defaults write com.apple.screencapture location ~/Desktop && killall SystemUIServer"
echo
echo "✓ shotsmash uninstalled."
