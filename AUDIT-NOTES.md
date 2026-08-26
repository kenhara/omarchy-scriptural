# Scriptural 0.1.5 — audit fix map

Fixes from [AUDIT.md](AUDIT.md) against v0.1.3 @ `7a4f382`. No marketplace submit.

| ID | Severity | Fix |
|----|----------|-----|
| **DB-01** | P2 | `barWidget.category` **Widgets → Info**. README Discoverability + PRE-SHIP: `keywords` / `aliases` are for marketplace/docs filing drafts only; **bar-widget loader ignores them**. Keywords kept for filing drafts. |
| **DB-02** | P2 | `ensureCacheDir()` runs `mkdir -p ~/.cache/scriptural` on bootstrap and before persist. `persistToDisk` logs `console.log` + sets `lastError` on failure (no empty catch). `printErrors` stays false; loadFailed also logs. |
| **DB-03** | P2 | `versionChosen` signal → `BarWidget.mirrorVersion` writes `settings.version`. Panel chips expanded to web/kjv/esv/niv/**nkjv/nlt/msg**. Dropped single-option `language` schema enum; `language=en` remains in code + `defaults`. |
| **DB-04** | P3 | Synced non-changelog surfaces to **0.1.5** (README layout, Panel comment, preview banner/title, `preview.svg`, DESIGN, PRE-SHIP, votd fallback). Changelog keeps 0.1.2 history. |
| **DB-05** | P3 | `votd.py` maps Portuguese Midvash errors (`Versão não encontrada` → `Version not found: …`). Toast shows English `error`; optional raw in `error_detail` / `lastError`. |
| **DB-06** | P3 | `shortReference`: multi-word book regex + `bookAbbrevMap` (Song of Solomon → Song, 1 John → 1Jn, Lamentations → Lam, …). |
| **DB-07** | P3 | Chips use `chipSelected()` (prefer `verseVersion`). On failed/offline switch, `revertVersionToDisplayed()` restores `store.version` (+ mirror). |
| **DB-08** | P4 | Removed unused BarWidget `foreground`/`fontFamily`. Removed CLI rate-limit sleep (one HTTP call per process; commented). Defaults: schema `version` + code/`defaults` for `language=en`. |

## Verify

- `python3 scripts/votd.py --version web --language en` → ok JSON, network
- `python3 scripts/votd.py --dry-run --version web` → exit 2
- Invalid version → English `error` (not Portuguese)
- `rg '0\.1\.2' README.md docs/preview preview.svg` — only changelog / history if any

## 0.1.19 — HC-05 cache trust path

| ID | Finding | Fix |
|----|---------|-----|
| **HC-05** | `cacheReadProc` used `head -c` on `~/.cache/scriptural/votd.json` — follows a symlink and can block forever on a FIFO | `votd.py --load-cache` opens `O_RDONLY\|O_NOFOLLOW\|O_NONBLOCK`, requires `S_ISREG`, bounded read of `MAX_CACHE_BYTES` (256 KiB). Missing / symlink / FIFO / oversize / not-a-dict → **exit 1** (empty/tiny stdout). Valid dict → JSON on stdout, **exit 0**. Cache body is written directly (not via `emit()`, which caps at 64 KiB). FileView remains write-only. |

## 0.1.20 — open / redirect / cache write / clipboard

| ID | Finding | Fix |
|----|---------|-----|
| **Open** | `sanitizeOpenUrl` accepted any `https:` URL; `xdg-open` got the URL as a trailing argv without `--` | Parse `https`; allowlist `midvash.com` and `www.midvash.com`; length-cap `MAX_URL_CHARS`; `xdg-open --` URL. Same allowlist in `votd.py` `sanitize_https_url`. |
| **Redirect** | `http_get_json` followed 30x via default urllib; post-fetch `geturl()` is too late | `ApiHostRedirectHandler.redirect_request` refuses hops whose host is not `api.midvash.com` (https, port default/443) *before* following. |
| **Cache write** | `FileView.setText` can follow a dest symlink | `votd.py --save-cache`: dir 0700; unique temp `O_WRONLY\|O_CREAT\|O_EXCL\|O_NOFOLLOW` 0600; fsync; `os.replace`. Body on stdin. HC-05 `--load-cache` unchanged. |
| **PlainText** | `lastError` / `toastText` (and other remote Text) defaulted to RichText | `Text.PlainText` on lastError, toast; verse/ref/versionChip already PlainText. |
| **Copy** | Fallback put verse in argv (`$1`) | Keep Copy. Prefer `Quickshell.clipboardText`; else feed wl-copy/xclip/xsel on stdin. |
| **Caps** | Disk `applyPayload` did not re-apply field caps | Re-apply `MAX_TEXT_CHARS` / `MAX_REF_CHARS` / `MAX_URL_CHARS` in `applyPayload` (network and disk). |
| **PATH** | Process env did not pin PATH | `PATH=/usr/bin:/bin` on all Processes. `python3 -B` stays. |

