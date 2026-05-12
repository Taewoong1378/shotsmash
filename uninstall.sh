#!/bin/bash
# shotsmash uninstaller

set -u

PREFIX="${SHOTSMASH_PREFIX:-$HOME/.local}"
BIN_PATH="$PREFIX/bin/shotsmash"
PLIST_PATH="$HOME/Library/LaunchAgents/com.shotsmash.plist"

echo "▸ Unloading LaunchAgent…"
launchctl bootout "gui/$(id -u)/com.shotsmash" 2>/dev/null || true

echo "▸ Removing $PLIST_PATH"
rm -f "$PLIST_PATH"

echo "▸ Removing $BIN_PATH"
rm -f "$BIN_PATH"

echo
echo "Kept (delete manually if desired):"
echo "  ~/.config/shotsmash/      — your config"
echo "  ~/.shotsmash/originals/   — original screenshots backup"
echo "  ~/Library/Logs/shotsmash.log"
echo "  ~/Pictures/Screenshots/   — your screenshots"
echo
echo "Restore default screenshot location with:"
echo "  defaults write com.apple.screencapture location ~/Desktop && killall SystemUIServer"
echo
echo "✓ shotsmash uninstalled."
