# Daily Bread — pre-ship checklist (0.1.2)

Omarchy Quattro pre-ship pass for `harris.daily-bread`. Builds on
`PRE-AUDIT.md` (0.1.1) plus Fair Witness 0.1.2 marketplace lessons.

## Checklist

| Item | Status | Notes |
|------|--------|-------|
| `Style.font.size` | OK | Named tokens only (`caption` / `bodySmall` / `body` / `subtitle` / `title`) |
| `clipboardText` | OK | `Quickshell.clipboardText`; shell fallback `bash -c` if/elif |
| `bash -c` if/elif | OK | wl-copy → xclip → xsel; no `bash -lc`; toast on exit |
| no `/workspace` docs | OK | Public docs scrubbed |
| LICENSE | OK | Canonical MIT (second `Software` unquoted) |
| README hero | OK | `preview.png` above the fold |
| FileView cache | OK | `setText` mkpath; no mkdir + `Qt.callLater` race |
| dead `dataChanged` | OK | Removed in 0.1.1 |
| honest toasts | OK | Copied / Opened / Failed only on real outcome |
| PlainText on verse text from API | OK | Verse + reference + version chip |
| https allow-list for Open | OK | `sanitizeOpenUrl` + votd.py `sanitize_https_url` |
| version sync | OK | **0.1.2** across manifest / README / DESIGN / preview / UA |
| integer/enum schema | OK | `version` + `language` enums |
| no summon fakes | OK | Dropped `handleSummonPayload` / payload `open()` (bar-widget can't summon) |
| hover | OK | `containsMouse` + `hoverEnabled` on actionable |
| Controls L/R/M | OK | L toggle · R none (host) · M force refresh — documented |
| pitch | OK | *Give us this day the verse. Pause. Unofficial.* |
| UTC votd | OK | Store `todayIso` + `votd.py` UTC day key |
| cached chip honesty | OK | `showingCached` when disk/offline — never fake fresh |
| UA from manifest | OK | `scripts/votd.py` reads `manifest.json` |
| bar linger of ref | OK | Short ref stays on bar while verse present |
| drop `barWidget.aliases` | OK | Ignored for bar-widget; keywords remain |

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
