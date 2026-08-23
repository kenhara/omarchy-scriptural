# Daily Bread — design notes

**Status:** 0.1.0 (verse of the day · pause)  
**Id:** `harris.daily-bread`  
**Paths:** `/workspace/omarchy-daily-bread/` · playbook peers: Fair Witness, Yellow Pixels 0.2.0

## Why

*Daily Bread* — a quiet daily verse in the Omarchy bar. Personal
unofficial client for Midvash public VOTD. No API keys. No publisher chrome.

## Shape (playbook — Yellow Pixels / Fair Witness lessons)

| Lesson | Apply |
|--------|--------|
| `bar-widget` + nested `Panel.qml` | Same — no separate panel kind |
| Theme tokens | Soft amber accent on title + chips |
| Schema knobs early | `version` enum + reserved `language` (`en`) |
| Honest empty/error | Toast on miss; quiet Midvash / unofficial footer |
| Ship extras | `preview.png`, Remove / Security / Network |
| Cache last success | `~/.cache/daily-bread/votd.json` keyed by date+version |
| Middle-click useful | Refresh VOTD (force network) |
| MIT + manifest at root | Marketplace layout |
| Unofficial disclaimer | Not affiliated with Midvash or Bible publishers |
| Primary UI simple | Verse + ref + chips + three actions |

## Bar

Short ref when loaded (`Jer 33:3`) else `● Bread`. Left click toggles panel.
Tooltip: *Daily Bread — verse of the day · middle: refresh*. Middle click refreshes.

## Panel

1. Big **DAILY BREAD** + *verse of the day · pause*
2. Large verse text + reference + version chip
3. Actions: Copy verse · Copy reference · Open
4. Translation chips row (web|kjv|esv|niv; rest in settings)
5. Quiet footer: Midvash · unofficial · public API

## Data

- VOTD: `GET https://api.midvash.com/v1/votd?language=en&version=web`
- Versions: `GET https://api.midvash.com/v1/versions?language=en`
- Default: `web` (World English Bible, public domain / CC0)
- UA: `DailyBread/0.1 (Omarchy unofficial; harris.daily-bread)`

## Non-goals

Auth, multi-language UI, full Bible browser, publisher branding, offline dumps.
