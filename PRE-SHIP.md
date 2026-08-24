# Daily Bread — pre-ship checklist (0.1.4)

## PRE-SHIP note — audit 0.1.4

P2–P4 audit fixes (see `AUDIT.md` / `AUDIT-NOTES.md`): honest discoverability
(`Info` category; keywords/aliases = marketplace/docs only — **shell ignores**
them for bar widgets); cache mkdir + persist logging; chip→settings write-back;
all seven versions on chips; drop `language` schema enum; English Midvash
errors; shortReference map; chip highlight follows `verseVersion`.

## PRE-SHIP note — discoverability (0.1.3)

Patch bump for marketplace discoverability before UTM smoke: `barWidget.category`
Lifestyle → Widgets (0.1.3); 0.1.4 moves Widgets → **Info**. Expanded `keywords`
+ `barWidget.aliases` kept for filing drafts only.

Omarchy Quattro pre-ship pass for `harris.daily-bread`. Builds on
`PRE-AUDIT.md` (0.1.1) plus Fair Witness marketplace lessons.

## Checklist

| Item | Status | Notes |
|------|--------|-------|
| `Style.font.size` | OK | Named tokens only (`caption` / `bodySmall` / `body` / `subtitle` / `title`) |
| `clipboardText` | OK | `Quickshell.clipboardText`; shell fallback `bash -c` if/elif |
| `bash -c` if/elif | OK | wl-copy → xclip → xsel; no `bash -lc`; toast on exit |
| no `/workspace` docs | OK | Public docs scrubbed |
| LICENSE | OK | Canonical MIT (second `Software` unquoted) |
| README hero | OK | `preview.png` above the fold |
| FileView cache | OK | `mkdir -p` + `setText`; persist failures logged |
| dead `dataChanged` | OK | Removed in 0.1.1 |
| honest toasts | OK | Copied / Opened / Failed only on real outcome; English errors |
| PlainText on verse text from API | OK | Verse + reference + version chip |
| https allow-list for Open | OK | `sanitizeOpenUrl` + votd.py `sanitize_https_url` |
| version sync | OK | **0.1.4** across manifest / README / DESIGN / preview / UA |
| enum schema | OK | `version` enum (seven); language in defaults/code only |
| no summon fakes | OK | Dropped `handleSummonPayload` / payload `open()` |
| hover | OK | `containsMouse` + `hoverEnabled` on actionable |
| Controls L/R/M | OK | L toggle · R none (host) · M force refresh — documented |
| pitch | OK | *Give us this day the verse. Pause. Unofficial.* |
| UTC votd | OK | Store `todayIso` + `votd.py` UTC day key |
| cached chip honesty | OK | `showingCached` when disk/offline — never fake fresh |
| UA from manifest | OK | `scripts/votd.py` reads `manifest.json` |
| bar linger of ref | OK | Short ref stays on bar while verse present |
| keywords / aliases | OK | Filing/docs only — bar loader does **not** index (DB-01) |
| category | OK | **Info** (canonical with weather-style info widgets) |
| chip write-back | OK | `versionChosen` → `mirrorVersion` (DB-03) |

## Pre-ship grep (expect empty)

```
Style.font.size(
Quickshell.clipboard[^T]
env .*API_KEY=
bash -lc
/workspace/
handleSummonPayload
```

Also confirm remote `Text` elements set `textFormat: Text.PlainText`.

## Still for live Omarchy VM

- Confirm `Style.font.*` named tokens resolve on target shell
- Confirm Quickshell `clipboardText` + https Open + popout-switch host behavior
- Confirm settings write-back for `version` when host exposes mutable `settings`
