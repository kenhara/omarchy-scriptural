# Daily Bread — pre-audit harden (0.1.1)

Proactive locks applied from sibling audits **before** a Daily Bread audit pass.
Sources: Space Jockey 1.5, Security Theater 0.5.1, Yellow Pixels 0.2.1, Fair Witness.

## Locked in

| Pattern | Source | Applied |
|---------|--------|---------|
| No `Style.font.size(N)` — named tokens only | YP | Panel uses `caption` / `bodySmall` / `body` / `subtitle` / `title` |
| Font: `bar.fontFamily` / `contentFontFamily`; concrete `"monospace"` fallback | SJ | BarWidget + Panel |
| `Quickshell.clipboardText` (not `.clipboard.text`) | YP / ST | `copyText` |
| Shell clipboard: `bash -c` if/elif wl-copy → xclip → xsel; no clobber | YP / ST | `copyProc`; toast only on exit 0 |
| Toast “Copied” / “Opened” only on real success | ST / YP | `copyProc` / `openUrlProc` `onExited` |
| No secrets in argv; clean `Process.command` | YP | votd Process is argv-only (no keys) |
| Cache: `FileView.setText` direct (mkpath); no mkdir + `Qt.callLater` race | YP / ST | `persistToDisk` |
| Tall panel → `Flickable` + clip | SJ | Panel already wrapped; kept |
| Hover (`containsMouse` + `hoverEnabled`) on actionable | ST | Copy / Open / translation chips |
| Pointer cursor only on actionable | ST / playbook | MouseAreas on buttons/chips only |
| Middle-click = refresh; tip documents it | playbook | BarWidget tooltip + README |
| Offline / cache honesty — show last verse + **cached**; never fake fresh | ST honesty | `showingCached` chip + offline toast |
| Dead `dataChanged` (0 consumers) removed | YP | Store |
| Unused `panelOpen` / `forceRefresh` removed | YP | Store + BarWidget |
| Popout-switch: `popoutSwitchClosing` + `closeForPopoutSwitch` → `close()` | YP | Panel + BarWidget forward |
| README hero `preview.png`; no WIP / no `/workspace/` in public docs | SJ / ST | README + DESIGN |
| Prefer Omarchy / omarchy-shell (not internal Quattro) in public copy | ST | votd docstring + docs |
| Version sync 0.1.1 across manifest / README / DESIGN / preview banner / UA | ST | All ship surfaces |
| Canonical MIT (second `Software` unquoted) | ST | LICENSE |
| Honest network/deps + Midvash attribution + translation © note | playbook | README Network & deps |
| Default WEB (public domain); copyrighted versions show attribution | VOTD | Footer + disclaimer |
| Same **UTC** day verse; document timezone | VOTD | Store `todayIso`, `votd.py`, README |
| UA `DailyBread/0.1.1` | VOTD | `scripts/votd.py` |

## Pre-ship grep (expect empty)

```
Style.font.size(
Quickshell.clipboard[^T]
env .*API_KEY=
bash -lc
/workspace/
```

## Still for live Omarchy VM

- Confirm `Style.font.*` named tokens resolve on target shell
- Confirm Quickshell `clipboardText` + popout-switch host behavior
