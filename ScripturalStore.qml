import QtQuick
import Quickshell
import Quickshell.Io

// Scriptural — runs scripts/votd.py via Process; parses JSON stdout.
// Midvash public VOTD only. No API keys.
// Caches daily verse to ~/.cache/scriptural/votd.json keyed by UTC date+version.
QtObject {
  id: store

  property string version: "web"
  property string language: "en"

  property bool loading: false
  property string lastError: ""
  property string toastText: ""
  property string reference: ""
  property string text: ""
  property string url: ""
  property string verseVersion: ""
  property string verseDate: ""
  property string fetchedAt: ""
  property string bookSlug: ""
  property var chapter: null
  property var verseStart: null
  property var verseEnd: null
  property string dataSource: "none"  // disk | network | none
  property string votdBuf: ""
  // Version requested by the latest in-flight fetch (for chip revert on failure).
  property string pendingVersion: ""

  // Best-effort write-back so chip choice survives reload (BarWidget mirrors).
  signal versionChosen(string slug)

  readonly property var quickVersions: [
    { slug: "web", label: "WEB" },
    { slug: "kjv", label: "KJV" },
    { slug: "esv", label: "ESV" },
    { slug: "niv", label: "NIV" },
    { slug: "nkjv", label: "NKJV" },
    { slug: "nlt", label: "NLT" },
    { slug: "msg", label: "MSG" }
  ]

  // Sensible bar abbreviations for multi-word / numbered books.
  readonly property var bookAbbrevMap: ({
    "song of solomon": "Song",
    "song of songs": "Song",
    "psalms": "Ps",
    "psalm": "Ps",
    "lamentations": "Lam",
    "philippians": "Phil",
    "thessalonians": "Thess",
    "revelation": "Rev",
    "ecclesiastes": "Eccl",
    "deuteronomy": "Deut",
    "chronicles": "Chr",
    "corinthians": "Cor",
    "colossians": "Col",
    "ephesians": "Eph",
    "galatians": "Gal",
    "hebrews": "Heb",
    "jeremiah": "Jer",
    "zechariah": "Zech",
    "zephaniah": "Zeph",
    "habakkuk": "Hab",
    "malachi": "Mal",
    "matthew": "Matt",
    "james": "Jas",
    "jude": "Jude",
    "job": "Job",
    "joel": "Joel",
    "amos": "Amos",
    "obadiah": "Obad",
    "jonah": "Jonah",
    "micah": "Mic",
    "nahum": "Nah",
    "haggai": "Hag",
    "hosea": "Hos",
    "isaiah": "Isa",
    "ezekiel": "Ezek",
    "daniel": "Dan",
    "joshua": "Josh",
    "judges": "Judg",
    "ruth": "Ruth",
    "ezra": "Ezra",
    "nehemiah": "Neh",
    "esther": "Esth",
    "proverbs": "Prov",
    "mark": "Mark",
    "luke": "Luke",
    "john": "Jn",
    "acts": "Acts",
    "romans": "Rom",
    "titus": "Titus",
    "philemon": "Phlm",
    "peter": "Pet",
    "timothy": "Tim",
    "samuel": "Sam",
    "kings": "Kgs",
    "genesis": "Gen",
    "exodus": "Exod",
    "leviticus": "Lev",
    "numbers": "Num",
  })

  readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/scriptural"
  readonly property string cachePath: cacheDir + "/votd.json"
  // Percent-decode so paths with spaces work for python3
  readonly property string pluginDir: {
    var raw = String(Qt.resolvedUrl("."))
      .replace(/^file:\/\//, "")
      .replace(/\/$/, "")
    try {
      return decodeURIComponent(raw)
    } catch (e) {
      return raw
    }
  }
  readonly property string votdPath: pluginDir + "/scripts/votd.py"

  readonly property string barGlyph: "●"
  readonly property string barLabel: {
    var shortRef = store.shortReference
    if (shortRef && shortRef.length)
      return shortRef
    return store.barGlyph + " Bread"
  }

  readonly property string shortReference: {
    var ref = String(store.reference || "").trim()
    if (!ref.length) return ""
    // Book (multi-word OK) + chapter:verse — e.g. "Song of Solomon 1:1", "1 John 3:16"
    var m = ref.match(/^(.+?)\s+(\d+:\d+(?:-\d+)?)\s*$/)
    if (!m) return ref
    var book = String(m[1] || "").trim()
    var nums = String(m[2] || "").trim()
    var lower = book.toLowerCase()
    var mapped = store.bookAbbrevMap[lower]
    if (mapped)
      return mapped + " " + nums
    // Numbered books: "1 John" → look up "john" with number prefix
    var numBook = lower.match(/^([1-3])\s+(.+)$/)
    if (numBook) {
      var restMap = store.bookAbbrevMap[numBook[2]]
      if (restMap)
        return numBook[1] + restMap + " " + nums
      var rest = String(numBook[2] || "")
      var shortRest = rest.length > 3 ? rest.slice(0, 3) : rest
      return numBook[1] + shortRest.charAt(0).toUpperCase() + shortRest.slice(1) + " " + nums
    }
    // Fallback: first three letters of first word when long
    var parts = book.split(/\s+/)
    if (parts.length >= 2) {
      // Multi-word unknown: first letters of significant words (Song of X → SoX-ish) or first word trunc
      var significant = parts.filter(function(p) {
        var l = p.toLowerCase()
        return l !== "of" && l !== "the" && l !== "and"
      })
      if (significant.length >= 2) {
        var abbr = significant.map(function(p) { return p.charAt(0).toUpperCase() }).join("")
        return abbr + " " + nums
      }
    }
    var one = parts[0] || book
    var abbrOne = one.length > 4 ? one.slice(0, 3) : one
    return abbrOne + " " + nums
  }

  readonly property string versionChip: {
    var v = String(store.verseVersion || store.version || "web").toUpperCase()
    return v
  }

  readonly property bool hasVerse: !!(store.text && String(store.text).length
                                      && store.reference && String(store.reference).length)

  readonly property bool showingCached: store.hasVerse
    && (store.dataSource === "disk"
        || (store.lastError && String(store.lastError).indexOf("offline") >= 0))

  readonly property string lastUpdatedText: formatUpdated(store.fetchedAt)

  // Chip highlight: prefer displayed verseVersion so a failed switch doesn't lie.
  function chipSelected(slug) {
    var want = String(slug || "").toLowerCase()
    if (store.hasVerse && store.verseVersion && String(store.verseVersion).length) {
      return store.normalizeVersion(store.verseVersion) === want
    }
    return store.normalizeVersion(store.version) === want
  }

  function normalizeVersion(slug) {
    var s = String(slug || "web").trim().toLowerCase()
    return s.length ? s : "web"
  }

  function normalizeLanguage(lang) {
    var s = String(lang || "en").trim().toLowerCase()
    return s.length ? s : "en"
  }

  function applySettings(opts) {
    opts = opts || {}
    if (opts.version !== undefined) {
      var next = store.normalizeVersion(opts.version)
      if (next !== store.version) {
        store.version = next
        Qt.callLater(function() { store.refresh(false) })
      } else {
        store.version = next
      }
    }
    if (opts.language !== undefined)
      store.language = store.normalizeLanguage(opts.language)
  }

  function formatUpdated(iso) {
    if (!iso) return "never"
    var t = Date.parse(iso)
    if (!isFinite(t)) return String(iso)
    var sec = Math.max(0, Math.floor((Date.now() - t) / 1000))
    if (sec < 60) return "just now"
    if (sec < 3600) return Math.floor(sec / 60) + "m ago"
    if (sec < 86400) return Math.floor(sec / 3600) + "h ago"
    return Math.floor(sec / 86400) + "d ago"
  }

  function showToast(msg) {
    store.toastText = String(msg || "")
    toastClear.restart()
  }

  // VOTD day key is UTC (same verse worldwide for a given UTC calendar day).
  function todayIso() {
    var d = new Date()
    var y = d.getUTCFullYear()
    var m = d.getUTCMonth() + 1
    var day = d.getUTCDate()
    return y + "-" + (m < 10 ? "0" : "") + m + "-" + (day < 10 ? "0" : "") + day
  }

  function copyText(text) {
    var t = String(text || "")
    if (!t.length) {
      store.showToast("Nothing to copy")
      return false
    }
    try {
      if (typeof Quickshell !== "undefined" && Quickshell.clipboardText !== undefined) {
        Quickshell.clipboardText = t
        store.showToast("Copied")
        return true
      }
    } catch (e) {}
    // Shell fallback: exactly one of wl-copy / xclip / xsel; bash -c (not -lc).
    // Toast only on copyProc success (onExited) — never claim Copied early.
    copyProc.command = [
      "bash", "-c",
      't="$1"; if command -v wl-copy >/dev/null 2>&1; then printf "%s" "$t" | wl-copy; elif command -v xclip >/dev/null 2>&1; then printf "%s" "$t" | xclip -selection clipboard; elif command -v xsel >/dev/null 2>&1; then printf "%s" "$t" | xsel --clipboard --input; else exit 127; fi',
      "scriptural-copy", t
    ]
    copyProc.running = true
    return true
  }

  function copyVerse() {
    if (!store.hasVerse)
      return store.copyText("")
    var body = "\"" + store.text + "\" — " + store.reference
    if (store.verseVersion)
      body += " (" + String(store.verseVersion).toUpperCase() + ")"
    return store.copyText(body)
  }

  function copyReference() {
    return store.copyText(store.reference || "")
  }

  function sanitizeOpenUrl(url) {
    var u = String(url || "").trim()
    if (!u.length)
      return ""
    // https only — refuse file:/mailto:/custom schemes from remote payload
    if (u.toLowerCase().indexOf("https://") === 0)
      return u
    return ""
  }

  function openUrlExternal(url) {
    var u = store.sanitizeOpenUrl(url)
    if (!u.length) {
      store.showToast(String(url || "").trim().length ? "Refused — https only" : "No URL")
      return false
    }
    try {
      var ok = Qt.openUrlExternally(u)
      if (ok !== false) {
        store.showToast("Opened")
        return true
      }
    } catch (e) {}
    openUrlProc.command = ["xdg-open", u]
    openUrlProc.running = true
    return true
  }

  function openVerse() {
    return store.openUrlExternal(store.url || "")
  }

  function setVersion(slug) {
    var next = store.normalizeVersion(slug)
    if (next === store.version && store.hasVerse
        && String(store.verseVersion || "").toLowerCase() === next
        && store.verseDate === store.todayIso()) {
      store.showToast(next.toUpperCase())
      return
    }
    store.version = next
    store.versionChosen(next)
    store.refresh(false)
  }

  function buildCacheObject(payload, atIso) {
    return {
      version: 1,
      date: (payload && payload.date) || store.verseDate || store.todayIso(),
      bibleVersion: store.normalizeVersion(
        (payload && payload.version) || store.verseVersion || store.version),
      language: store.normalizeLanguage(
        (payload && payload.language) || store.language),
      fetchedAt: atIso || store.fetchedAt || "",
      payload: payload || ({})
    }
  }

  function ensureCacheDir() {
    mkdirProc.command = ["mkdir", "-p", "--", store.cacheDir]
    mkdirProc.running = true
  }

  function persistToDisk(obj) {
    // Ensure ~/.cache/scriptural exists, then FileView.setText (mkpath belt+suspenders).
    store.ensureCacheDir()
    var body = JSON.stringify(obj || store.buildCacheObject(), null, 2) + "\n"
    try {
      cacheFile.setText(body)
    } catch (e) {
      console.log("Scriptural: cache write failed:", e)
      store.lastError = "cache write failed"
    }
  }

  function applyPayload(obj, source) {
    if (!obj || typeof obj !== "object") return false
    var payload = obj.payload !== undefined ? obj.payload : obj
    if (!payload || typeof payload !== "object") return false
    if (payload.ok === false && !(payload.text && payload.reference)) {
      store.lastError = String(payload.error || "fetch failed")
      store.dataSource = source || store.dataSource
      return false
    }
    store.reference = String(payload.reference || "")
    store.text = String(payload.text || "")
    store.url = store.sanitizeOpenUrl(payload.url || "")
    store.verseVersion = String(payload.version || store.version || "web").toLowerCase()
    store.verseDate = String(payload.date || obj.date || store.todayIso())
    store.fetchedAt = obj.fetchedAt || payload.fetchedAt || store.fetchedAt || ""
    store.bookSlug = String(payload.book_slug || "")
    store.chapter = payload.chapter !== undefined ? payload.chapter : null
    store.verseStart = payload.verse_start !== undefined ? payload.verse_start : null
    store.verseEnd = payload.verse_end !== undefined ? payload.verse_end : null
    store.lastError = payload.error ? String(payload.error) : ""
    store.dataSource = source || "network"
    return !!(store.reference && store.text)
  }

  function cacheMatches(obj) {
    if (!obj || typeof obj !== "object") return false
    var wantVer = store.normalizeVersion(store.version)
    var wantDate = store.todayIso()
    var gotVer = store.normalizeVersion(obj.bibleVersion
      || (obj.payload && obj.payload.version) || "")
    var gotDate = String(obj.date || (obj.payload && obj.payload.date) || "")
    return gotVer === wantVer && gotDate === wantDate
  }

  function loadDiskText(text) {
    try {
      var obj = JSON.parse(text || "{}")
      if (!store.cacheMatches(obj))
        return false
      return store.applyPayload(obj, "disk")
    } catch (e) {
      return false
    }
  }

  function onCacheLoaded(text) {
    var ok = false
    if (text && text.length > 2)
      ok = store.loadDiskText(text)
    if (!ok)
      store.refresh(false)
  }

  function refresh(force) {
    if (store.loading && votdProc.running)
      return
    // Try cache first unless forced
    if (!force) {
      try {
        var existing = cacheFile.text()
        if (existing && existing.length > 2 && store.loadDiskText(existing)) {
          store.showToast("Cached")
          return
        }
      } catch (e) {}
    }
    store.loading = true
    store.lastError = ""
    store.votdBuf = ""
    store.pendingVersion = store.normalizeVersion(store.version)
    votdProc.command = [
      "python3",
      store.votdPath,
      "--version", store.normalizeVersion(store.version),
      "--language", store.normalizeLanguage(store.language)
    ]
    votdProc.running = true
  }

  function revertVersionToDisplayed() {
    var shown = store.normalizeVersion(store.verseVersion || "")
    if (shown && shown.length && shown !== store.normalizeVersion(store.version)) {
      store.version = shown
      store.versionChosen(shown)
    }
  }

  function onVotdFinished(exitCode) {
    store.loading = false
    var raw = store.votdBuf || ""
    store.votdBuf = ""
    if (!raw.length) {
      // Keep last verse if we have one (offline honesty — never fake fresh)
      if (store.hasVerse) {
        store.lastError = "offline — showing last verse (cached)"
        store.dataSource = "disk"
        store.revertVersionToDisplayed()
        store.showToast("Offline · cached")
      } else {
        store.lastError = "votd produced no output (exit " + exitCode + ")"
        store.showToast("Failed")
      }
      store.pendingVersion = ""
      return
    }
    var lines = raw.split("\n")
    var blob = ""
    for (var i = lines.length - 1; i >= 0; i--) {
      var line = String(lines[i] || "").trim()
      if (line.charAt(0) === "{") {
        blob = line
        break
      }
    }
    if (!blob.length)
      blob = raw.trim()
    try {
      var obj = JSON.parse(blob)
      store.fetchedAt = new Date().toISOString()
      if (obj.ok) {
        store.applyPayload({ payload: obj, fetchedAt: store.fetchedAt, date: obj.date }, "network")
        store.persistToDisk(store.buildCacheObject(obj, store.fetchedAt))
        store.showToast(store.shortReference || "Updated")
      } else {
        var eng = String(obj.error || "fetch failed")
        var detail = obj.error_detail ? String(obj.error_detail) : ""
        store.lastError = detail && detail !== eng ? (eng + " (" + detail + ")") : eng
        if (!store.hasVerse)
          store.applyPayload({ payload: obj }, "network")
        else {
          store.lastError = eng + " — showing last verse (cached)"
          store.revertVersionToDisplayed()
          store.showToast("Cached")
          store.pendingVersion = ""
          return
        }
        // Toast stays English / short — not raw Portuguese
        store.showToast(eng)
      }
    } catch (e) {
      store.lastError = "votd JSON parse failed"
      store.revertVersionToDisplayed()
      store.showToast("Failed")
    }
    store.pendingVersion = ""
  }

  function bootstrap() {
    store.ensureCacheDir()
    cacheFile.reload()
  }

  Component.onCompleted: {
    store.bootstrap()
  }

  Timer {
    id: toastClear
    interval: 1800
    repeat: false
    onTriggered: store.toastText = ""
  }

  FileView {
    id: cacheFile
    path: store.cachePath
    watchChanges: false
    // Quiet UI: Framework errors off; persistToDisk logs failures itself.
    printErrors: false
    onLoaded: store.onCacheLoaded(text())
    onLoadFailed: {
      console.log("Scriptural: cache load failed — fetching network")
      store.refresh(false)
    }
  }

  Process {
    id: mkdirProc
    running: false
  }

  Process {
    id: copyProc
    running: false
    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0)
        store.showToast("Copied")
      else if (exitCode === 127)
        store.showToast("No clipboard tool")
      else
        store.showToast("Copy failed")
    }
  }

  Process {
    id: openUrlProc
    running: false
    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0)
        store.showToast("Opened")
      else
        store.showToast("Open failed")
    }
  }

  Process {
    id: votdProc
    running: false
    stdout: SplitParser {
      onRead: function(line) { store.votdBuf += line + "\n" }
    }
    stderr: SplitParser {
      onRead: function(line) {
        var s = String(line || "")
        if (s.length)
          store.lastError = s
      }
    }
    onExited: function(exitCode, exitStatus) {
      store.onVotdFinished(exitCode)
    }
  }
}
