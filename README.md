# shotsmash

> Stop wasting Claude/GPT vision tokens on 5MB screenshots. Every macOS screenshot you take is auto-converted to a small WebP — typically **80–95% smaller**, identical visual quality.

```
5,177 KB PNG  →  350 KB WebP   (-94%)
  487 KB PNG  →   54 KB WebP   (-89%)
  127 KB PNG  →   46 KB WebP   (-64%)
```

No new shortcut to learn. Press `Cmd+Shift+4` like always. shotsmash handles the rest in the background.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/Taewoong1378/shotsmash/main/install.sh | bash
```

That's it. It will:

1. Install `webp` via Homebrew if missing
2. Move your screenshot save location to `~/Pictures/Screenshots/` (avoids macOS Full Disk Access prompts)
3. Install a launchd agent that watches the folder + polls every 30 s
4. Drop a config stub at `~/.config/shotsmash/config.sh`

Then take a screenshot. Check `~/Pictures/Screenshots/` — your `.png` becomes `.webp` within a second.

## Why this exists

Pasting screenshots into Claude/ChatGPT is the fastest way to ask a question. But a full-res Retina screenshot is **3024×1890 PNG ≈ 5 MB**. That blows up your upload time and your token bill.

| | Pixels | Tokens (Claude) | File size |
|---|---|---|---|
| Raw Retina PNG | 3024×1890 | ~7,620 | ~5 MB |
| shotsmash WebP | 1400×875 | ~1,633 | ~50 KB |
| **Savings** | | **~79%** | **~99%** |

(Token count formula: `(w × h) / 750` for Claude vision models.)

## How it compares

| | shotsmash | [LLM Image Optimizer](https://www.image-optimizer.app/) | CleanShot X | ImageOptim | Folder Action scripts |
|---|:-:|:-:|:-:|:-:|:-:|
| Auto-process every screenshot | ✅ | ✅ (own shortcut) | ❌ | ❌ | ✅ |
| Keep native `Cmd+Shift+4` | ✅ | ❌ | ✅ | n/a | ✅ |
| WebP output | ✅ | ✅ | ❌ | ❌ | ❌ |
| Resize | ✅ | ✅ | ✅ | partial | ❌ |
| AI-token-aware defaults | ✅ | ✅ | ❌ | ❌ | ❌ |
| Native macOS (no Electron) | ✅ | ❌ | ✅ | ✅ | ✅ |
| Free / open source | ✅ | $ | $$ | ✅ | ✅ |

## Configuration

Edit `~/.config/shotsmash/config.sh`:

```sh
MAX_DIM=1400              # Long-side max in pixels
QUALITY=78                # WebP quality (1-100)
OUTPUT_FORMAT="webp"      # "webp" or "jpg"
KEEP_ORIGINALS=true       # Back up originals before processing
ORIGINAL_RETENTION_DAYS=7
```

Or set the env vars in the LaunchAgent plist if you want them to apply to the background process.

## Safety

- Originals are copied to `~/.shotsmash/originals/` before any change (kept 7 days, configurable).
- Each processed file gets a `com.shotsmash.processed` xattr so it's never reprocessed.
- The agent only touches files matching macOS screenshot naming patterns. Other images in the folder are untouched.

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/Taewoong1378/shotsmash/main/uninstall.sh | bash
```

## License

MIT
