# Audit — `kenhara.scriptural` (Omarchy plugin) v0.1.3

## Context

Scriptural is an Omarchy Quickshell `bar-widget` (`BarWidget.qml` → `Panel.qml` +
`ScripturalStore.qml`) that shells out to `scripts/votd.py` for Midvash public
VOTD. Target audited: **v0.1.3 @ 7a4f382**. Findings below are the user audit
applied as **0.1.5** (see `AUDIT-NOTES.md`).

## Severity summary

| ID | Severity | Area | One-line |
|----|----------|------|----------|
| DB-01 | **P2** | manifest / README / PRE-SHIP | Discoverability overstated: `keywords` / `barWidget.aliases` are marketplace/docs, not the bar-widget loader; category should be canonical `Info` |
| DB-02 | **P2** | ScripturalStore | Cache dir may be missing; `persistToDisk` empty catch + `printErrors: false` → silent forever |
| DB-03 | **P2** | BarWidget / Store / schema | Chip `setVersion()` does not write widget settings; NKJV/NLT/MSG only via shaky settings enum; single-option `language` enum noise |
| DB-04 | **P3** | README / preview | Stray **0.1.2** in layout / preview banner (non-changelog) |
| DB-05 | **P3** | votd.py / UI | Portuguese Midvash errors (`Versão não encontrada`) surface raw to users |
| DB-06 | **P3** | ScripturalStore | `shortReference` weak on multi-word books (Song of Solomon) and numbered epistles |
| DB-07 | **P3** | Panel / Store | Failed version switch leaves chip highlight on requested version, not displayed `verseVersion` |
| DB-08 | **P4** | BarWidget / votd.py | Unused `foreground`/`fontFamily` on bar; dead/no-op rate-limit; dual defaults sources |

---

## P2 — must fix

### DB-01 · Discoverability honesty

**Files:** `manifest.json` (`barWidget.category`), `README.md` Discoverability,
`PRE-SHIP.md`

- `keywords` / `barWidget.aliases` help marketplace filing drafts and human search
  docs. The bar-widget loader does **not** index them for add/search — docs must
  not imply otherwise.
- `barWidget.category` is **Widgets**; canonical peer weather uses **`Info`**.
  Prefer **`Info`**.
- Keep useful Bible/VOTD keywords; fix wording only.

### DB-02 · Cache dir silent failure

**Files:** `ScripturalStore.qml` (`persistToDisk`, `FileView`)

- Ensure `~/.cache/scriptural/` exists before write (`mkdir -p` from QML).
- Stop empty `catch` on persist — at least `console.log` / `lastError` on failure.
- May keep `printErrors: false` for quiet UI, but must not have zero feedback.

### DB-03 · Version persistence + schema reachability

**Files:** `BarWidget.qml`, `ScripturalStore.qml`, `Panel.qml`, `manifest.json`

- Chip `setVersion()` must mirror into widget settings when possible so choice
  survives reload.
- Expand in-panel chips to **web · kjv · esv · niv · nkjv · nlt · msg** (all
  schema versions reachable without relying on unverified settings form).
- Drop single-option `language` enum from schema; keep `language=en` in code /
  `defaults`.

---

## P3

### DB-04 · Version sync strays

No stray **0.1.2** in README layout, `docs/preview`, `preview.svg`, Panel
comment (changelog history OK).

### DB-05 · English user-facing errors

Map Portuguese Midvash API errors to generic English in `votd.py` (and/or store).
Raw detail optional in `lastError`, not toast.

### DB-06 · `shortReference` abbrev map

Multi-word books + better abbreviations (e.g. Song of Solomon → Song, 1 John →
sensible short form).

### DB-07 · Chip highlight on failed switch

On failed version switch, keep chip highlight aligned with displayed
`verseVersion` (revert `store.version` on failure **or** select by
`verseVersion`).

---

## P4

### DB-08 · Dead code / defaults

- Remove unused BarWidget `foreground` / `fontFamily` if unused.
- Remove dead rate-limit in `votd.py` or comment as no-op for single-call CLI.
- Prefer one defaults source of truth where easy (`manifest` + code `en`/`web`).

---

## Verify

- `python3 scripts/votd.py --version web --language en` (network)
- `--dry-run` exit 2
- grep stray old version in README/preview (non-changelog)
- Commit + push `main` (no marketplace submit)
