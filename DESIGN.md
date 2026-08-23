# Daily Bread — design notes

**Status:** 0.1.2 (verse of the day · pause)  
**Id:** `harris.daily-bread`  
**Peers:** Fair Witness, Yellow Pixels, Security Theater, Space Jockey

## Why

*Daily Bread* — give us this day the verse. A quiet pause in the Omarchy
bar. Personal unofficial client for Midvash public VOTD. No API keys.

## Shape (playbook lessons)

| Lesson | Apply |
|--------|--------|
| `bar-widget` + nested `Panel.qml` | Same — no separate panel kind |
| Named `Style.font.*` tokens | No `Style.font.size(N)` |
| Theme tokens | Soft amber accent on title + chips; `Style.space` / `bar.foreground` |
| Schema knobs early | `version` enum + reserved `language` (`en`) |
| Honest empty/error/cache | Toast on miss; **cached** chip offline; quiet Midvash footer |
| Ship extras | `preview.png` README hero, Remove / Security / Network |
| Cache last success | `~/.cache/daily-bread/votd.json` keyed by **UTC date + version** |
| Middle-click useful | Refresh VOTD (force network); tip documents it |
| MIT + manifest at root | Marketplace layout |
| Unofficial disclaimer | Not affiliated with Midvash or Bible publishers |
| Primary UI simple | Verse + ref + chips + three actions |
| Hover + pointer | `containsMouse` on actionable only |
| PlainText on API text | Verse + reference `textFormat: Text.PlainText` |
| https-only Open | Refuse non-`https:` remote URLs |
| UA from manifest | `scripts/votd.py` reads `manifest.json` |

## Bar

Short ref **lingers** when loaded (`Jer 33:3`) else `● Bread`. Left click
toggles panel. Tooltip: *Daily Bread — verse of the day · middle: refresh*.
Middle click refreshes. Right-click: none (host default).

## Panel

1. Big **DAILY BREAD** + *verse of the day · pause*
2. Large verse text + reference + version chip (+ **cached** when disk/offline)
3. Actions: Copy verse · Copy reference · Open (hover feedback)
4. Translation chips row (web|kjv|esv|niv; rest in settings)
5. Quiet footer: Midvash · unofficial · public API · VOTD day = UTC

## Data

- VOTD: `GET https://api.midvash.com/v1/votd?language=en&version=web`
- Versions: `GET https://api.midvash.com/v1/versions?language=en`
- Default: `web` (World English Bible, public domain / CC0)
- UA: `DailyBread/<manifest version> (Omarchy unofficial; harris.daily-bread)`
- Day key: **UTC** calendar date

## Non-goals

Auth, multi-language UI, full Bible browser, publisher branding, offline dumps.
