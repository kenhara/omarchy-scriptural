# Daily Bread

Verse of the day. Pause. Unofficial.

Daily scripture for Omarchy — bar shows today’s short reference, panel shows
the verse. Named for the familiar prayer line — daily bread. Powered by the
**Midvash** public VOTD API. No API keys. No publisher chrome.

**ID:** `harris.daily-bread`  
**Author:** Harris Kenny  
**License:** MIT  
**Version:** 0.1.0

### 0.1.0
- MVP — bar short ref (`Jer 33:3`) or `● Bread`, panel verse + chips,
  `scripts/votd.py` → Midvash public VOTD, Copy verse / Copy reference / Open,
  daily disk cache, middle-click refresh, schema `version` + reserved `language`.

## Repository

**GitHub:** https://github.com/kenhara/omarchy-daily-bread  
Local folder: **`omarchy-daily-bread`**.

## Unofficial disclaimer

**Daily Bread is unofficial.** It is **not** affiliated with, endorsed by, or
sponsored by Midvash, any Bible publisher, or any related entity. “Daily Bread”
is a familiar prayer / scripture phrase. This plugin is a thin personal
client that calls a **public read** HTTP verse-of-the-day API.

Copyrighted translations (ESV, NIV, NKJV, NLT, MSG, …) are requested only for
**personal display** via Midvash’s public API. Default is **WEB** (World
English Bible), which Midvash documents as public domain / CC0. Do not
redistribute copyrighted translation text beyond what the API and publishers
allow. Attribution for the translation in use belongs to its copyright holder;
this plugin only surfaces Midvash’s `version` field and a quiet footer.

## Install

### From GitHub

```sh
omarchy plugin add https://github.com/kenhara/omarchy-daily-bread.git --enable
omarchy bar move harris.daily-bread --section right
```

### Local copy (this tree)

The **git repo root is the plugin** (`manifest.json` at root). On an Omarchy
machine:

```sh
mkdir -p ~/.config/omarchy/plugins
cp -a . ~/.config/omarchy/plugins/harris.daily-bread

omarchy plugin validate ~/.config/omarchy/plugins/harris.daily-bread
omarchy-shell shell rescanPlugins

omarchy bar move harris.daily-bread --section right
```

Hot reload applies on save under `~/.config/omarchy/plugins/`.

### Symlink (dev)

```sh
mkdir -p ~/.config/omarchy/plugins
ln -sfn /path/to/omarchy-daily-bread ~/.config/omarchy/plugins/harris.daily-bread
omarchy-shell shell rescanPlugins
```

## Configure

Open **widget settings** for Daily Bread (optional):

| Schema key | Label | Default |
|------------|-------|---------|
| `version` | Bible version (`web` `kjv` `esv` `niv` `nkjv` `nlt` `msg`) | `web` |
| `language` | Language (MVP English-only) | `en` |

No API keys. Public read only. Panel chips cover web|kjv|esv|niv; the rest live
in settings.

CLI smoke:

```sh
python3 scripts/votd.py --version web --language en
python3 scripts/votd.py --dry-run --version web
python3 scripts/votd.py --list-versions --language en
```

## Usage

1. **Left-click** bar (`Jer 33:3` or `● Bread`) → panel.
2. Read today’s verse, reference, and version chip.
3. **Copy verse** / **Copy reference** / **Open** (Midvash URL).
4. Tap a translation chip (WEB · KJV · ESV · NIV) to switch; rest in settings.
5. **Middle-click** bar forces a network refresh (cache bypass).

Offline: last successful verse for that date+version stays on screen.

### Controls

| Input | Action |
|-------|--------|
| Left-click bar | Toggle panel |
| Middle-click bar | Force refresh VOTD |
| Copy verse | Clipboard: `"text" — Reference (VER)` |
| Copy reference | Clipboard: reference only |
| Open | Midvash verse URL |
| Translation chips | Switch version + refetch / cache |

## Remove

```sh
omarchy plugin remove harris.daily-bread
```

Optional cache cleanup:

```sh
rm -rf ~/.cache/daily-bread
```

## Network

- VOTD: `GET https://api.midvash.com/v1/votd?language=en&version=web`
- Versions list: `GET https://api.midvash.com/v1/versions?language=en`
- Verse pages: `https://midvash.com/en/{version}/{book}/{chapter}/{verse}`

Outbound HTTPS on bootstrap (if cache miss), version change, or middle-click
refresh. No auth. No signup.

User-Agent: `DailyBread/0.1 (Omarchy unofficial; harris.daily-bread)`.

Cache (daily, keyed by **date + version**): `~/.cache/daily-bread/votd.json`.

English version slugs known live (2026-08-23): `web`, `kjv`, `esv`, `niv`,
`nkjv`, `nlt`, `msg`, `asv`, `ylt`, `dra`, `bbe`, `geneva1599` (schema exposes
the common seven; chips show four).

## Scripts

`scripts/votd.py` — urllib only, no extra deps.

```sh
python3 scripts/votd.py --help
python3 scripts/votd.py --version web --language en
# stdout JSON: {ok, reference, text, version, url, date, error}
```

`--dry-run` and network errors emit structured error JSON (non-zero exit).

## Layout

```
manifest.json          # harris.daily-bread @ 0.1.0
BarWidget.qml          # bar entry + Loader → Panel; middle-click refresh
Panel.qml              # verse + chips + actions
DailyBreadStore.qml         # cache, Process → votd.py
qmldir
scripts/votd.py
docs/preview/index.html
preview.svg
preview.png
DESIGN.md
REPO.md
LICENSE                # MIT
README.md
```

## Security baseline

- **No API keys.** Public read VOTD only.
- Cache stores the last successful verse for date+version — no credentials.
- Outbound HTTPS on cache miss, version change, or explicit middle-click
  refresh. No paid calls.
- MIT at repo root. Unofficial — not affiliated with Midvash or Bible
  publishers. Daily Bread is scripture, not a publisher product.

## Preview

Open `docs/preview/index.html` in a browser for a filled HTML mock (v0.1.0)
with today’s sample (Jeremiah 33:3 WEB). Marketplace card: `preview.png`.

## License

MIT — see [LICENSE](LICENSE).

Scripture text in previews and live responses is supplied by Midvash; WEB is
public domain. Other translations remain under their publishers’ copyrights.
