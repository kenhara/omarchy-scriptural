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
