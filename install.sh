#!/bin/bash
# shotsmash installer — sets up auto screenshot shrinking on macOS.
#
# One-line install:
#   curl -fsSL https://raw.githubusercontent.com/<user>/shotsmash/main/install.sh | bash
#
# Or after `git clone`:
#   ./install.sh

set -euo pipefail

REPO_RAW="${SHOTSMASH_REPO_RAW:-https://raw.githubusercontent.com/Taewoong1378/shotsmash/main}"
PREFIX="${SHOTSMASH_PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"
BIN_PATH="$BIN_DIR/shotsmash"
CLIP_BIN_PATH="$BIN_DIR/shotsmash-clip"
PLIST_PATH="$HOME/Library/LaunchAgents/com.shotsmash.plist"
CLIP_PLIST_PATH="$HOME/Library/LaunchAgents/com.shotsmash.clip.plist"
WATCH_DIR_DEFAULT="$HOME/Pictures/Screenshots"
CONFIG_DIR="$HOME/.config/shotsmash"

red()    { printf "\033[31m%s\033[0m\n" "$*"; }
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
info()   { printf "\033[36m▸\033[0m %s\n" "$*"; }

[[ "$(uname)" == "Darwin" ]] || { red "shotsmash is macOS-only."; exit 1; }

info "Installing shotsmash to $BIN_PATH"

# --- 1. Ensure Homebrew + cwebp ---
if ! command -v brew >/dev/null 2>&1; then
  red "Homebrew not found. Install from https://brew.sh first."
  exit 1
fi
if ! command -v cwebp >/dev/null 2>&1; then
  info "Installing webp (cwebp) via Homebrew…"
  brew install webp
fi
if ! command -v pngpaste >/dev/null 2>&1; then
  info "Installing pngpaste via Homebrew (for clipboard mode)…"
  brew install pngpaste
fi

# --- 2. Locate source (running from clone or curl) ---
SCRIPT_SRC=""
CLIP_SCRIPT_SRC=""
PLIST_SRC=""
CLIP_PLIST_SRC=""
if [[ -f "$(dirname "$0")/bin/shotsmash" ]]; then
  HERE="$(cd "$(dirname "$0")" && pwd)"
  SCRIPT_SRC="$HERE/bin/shotsmash"
  CLIP_SCRIPT_SRC="$HERE/bin/shotsmash-clip"
  PLIST_SRC="$HERE/launchd/com.shotsmash.plist.tmpl"
  CLIP_PLIST_SRC="$HERE/launchd/com.shotsmash.clip.plist.tmpl"
else
  info "Downloading shotsmash files…"
  TMP=$(mktemp -d)
  curl -fsSL "$REPO_RAW/bin/shotsmash"      -o "$TMP/shotsmash"
  curl -fsSL "$REPO_RAW/bin/shotsmash-clip" -o "$TMP/shotsmash-clip"
  curl -fsSL "$REPO_RAW/launchd/com.shotsmash.plist.tmpl"      -o "$TMP/com.shotsmash.plist.tmpl"
  curl -fsSL "$REPO_RAW/launchd/com.shotsmash.clip.plist.tmpl" -o "$TMP/com.shotsmash.clip.plist.tmpl"
  SCRIPT_SRC="$TMP/shotsmash"
  CLIP_SCRIPT_SRC="$TMP/shotsmash-clip"
  PLIST_SRC="$TMP/com.shotsmash.plist.tmpl"
  CLIP_PLIST_SRC="$TMP/com.shotsmash.clip.plist.tmpl"
fi

# --- 3. Install scripts ---
mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$HOME/Library/Logs" "$WATCH_DIR_DEFAULT"
install -m 0755 "$SCRIPT_SRC"      "$BIN_PATH"
install -m 0755 "$CLIP_SCRIPT_SRC" "$CLIP_BIN_PATH"

# --- 4. Set screencapture location (idempotent) ---
CURRENT_LOC=$(defaults read com.apple.screencapture location 2>/dev/null || echo "")
if [[ "$CURRENT_LOC" != "$WATCH_DIR_DEFAULT" ]]; then
  info "Setting screenshot save location → $WATCH_DIR_DEFAULT"
  defaults write com.apple.screencapture location "$WATCH_DIR_DEFAULT"
  killall SystemUIServer 2>/dev/null || true
else
  info "Screenshot location already set."
fi

# --- 5. Render LaunchAgents ---
info "Installing LaunchAgent → $PLIST_PATH"
mkdir -p "$(dirname "$PLIST_PATH")"
sed \
  -e "s|__SHOTSMASH_BIN__|$BIN_PATH|g" \
  -e "s|__WATCH_DIR__|$WATCH_DIR_DEFAULT|g" \
  -e "s|__HOME__|$HOME|g" \
  "$PLIST_SRC" > "$PLIST_PATH"

info "Installing clipboard LaunchAgent → $CLIP_PLIST_PATH"
sed \
  -e "s|__SHOTSMASH_CLIP_BIN__|$CLIP_BIN_PATH|g" \
  -e "s|__HOME__|$HOME|g" \
  "$CLIP_PLIST_SRC" > "$CLIP_PLIST_PATH"

# --- 6. (Re)load agents ---
launchctl bootout "gui/$(id -u)/com.shotsmash"      2>/dev/null || true
launchctl bootout "gui/$(id -u)/com.shotsmash.clip" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"
launchctl bootstrap "gui/$(id -u)" "$CLIP_PLIST_PATH"

# --- 7. Drop a config stub if absent ---
if [[ ! -f "$CONFIG_DIR/config.sh" ]]; then
  cat > "$CONFIG_DIR/config.sh" <<'EOF'
# shotsmash config — uncomment to override defaults.

# --- File mode (shrinks saved screenshots → WebP on disk) ---
# WATCH_DIR="$HOME/Pictures/Screenshots"
# MAX_DIM=1400
# QUALITY=78
# OUTPUT_FORMAT="webp"          # or "jpg"
# KEEP_ORIGINALS=true
# ORIGINAL_RETENTION_DAYS=7

# --- Clipboard mode (resizes large images on the clipboard) ---
# CLIP_MAX_DIM=1400               # Long-side cap for clipboard images
# CLIP_POLL_INTERVAL=1.0          # Seconds between clipboard checks
EOF
fi

green "✓ shotsmash installed."
echo
echo "Two modes now running in the background:"
echo "  • File mode      → screenshots in ~/Pictures/Screenshots auto-convert to WebP"
echo "  • Clipboard mode → large images on the clipboard (from screenshot thumbnail,"
echo "                     Figma copy, browser copy-image, etc.) auto-resize to 1400px"
echo
echo "Logs:       tail -f ~/Library/Logs/shotsmash.log"
echo "            tail -f ~/Library/Logs/shotsmash-clip.log"
echo "Originals:  ~/.shotsmash/originals  (kept for 7 days)"
echo "Config:     $CONFIG_DIR/config.sh"
echo "Uninstall:  curl -fsSL $REPO_RAW/uninstall.sh | bash"
