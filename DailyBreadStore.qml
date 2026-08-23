import QtQuick
import Quickshell
import Quickshell.Io

// Daily Bread — runs scripts/votd.py via Process; parses JSON stdout.
// Midvash public VOTD only. No API keys.
// Caches daily verse to ~/.cache/daily-bread/votd.json keyed by date+version.
QtObject {
  id: store

  property string version: "web"
  property string language: "en"
  property bool panelOpen: false

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
  property bool forceRefresh: false

  readonly property var quickVersions: [
    { slug: "web", label: "WEB" },
    { slug: "kjv", label: "KJV" },
    { slug: "esv", label: "ESV" },
    { slug: "niv", label: "NIV" }
  ]

  readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/daily-bread"
  readonly property string cachePath: cacheDir + "/votd.json"
  readonly property string pluginDir: String(Qt.resolvedUrl("."))
    .replace(/^file:\/\//, "")
    .replace(/\/$/, "")
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
    // Jeremiah 33:3 → Jer 33:3 (first word truncated to 3–4 letters when long)
    var m = ref.match(/^([1-3]?\s*[A-Za-z]+)\s+(\d+:\d+(?:-\d+)?)/)
    if (!m) return ref
    var book = String(m[1] || "").trim()
    var nums = String(m[2] || "").trim()
    var parts = book.split(/\s+/)
    var abbr
    if (parts.length === 2 && /^[1-3]$/.test(parts[0])) {
      abbr = parts[0] + parts[1].slice(0, 3)
    } else {
      abbr = book.length > 4 ? book.slice(0, 3) : book
    }
    return abbr + " " + nums
  }

  readonly property string versionChip: {
    var v = String(store.verseVersion || store.version || "web").toUpperCase()
    return v
  }

  readonly property bool hasVerse: !!(store.text && String(store.text).length
                                      && store.reference && String(store.reference).length)

  readonly property string lastUpdatedText: formatUpdated(store.fetchedAt)

  signal dataChanged()

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
        // Version change → refresh (cache miss or new key)
        Qt.callLater(function() { store.refresh(false) })
      } else {
        store.version = next
      }
    }
    if (opts.language !== undefined)
      store.language = store.normalizeLanguage(opts.language)
    store.dataChanged()
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

  function todayIso() {
    var d = new Date()
    var y = d.getFullYear()
    var m = d.getMonth() + 1
    var day = d.getDate()
    return y + "-" + (m < 10 ? "0" : "") + m + "-" + (day < 10 ? "0" : "") + day
  }

  function copyText(text) {
    var t = String(text || "")
    if (!t.length) {
      store.showToast("Nothing to copy")
      return false
    }
    try {
      if (typeof Quickshell !== "undefined" && Quickshell.clipboard) {
        Quickshell.clipboard.text = t
        store.showToast("Copied")
        return true
      }
    } catch (e) {}
    copyProc.command = [
      "bash", "-lc",
      "printf '%s' \"$1\" | (command -v wl-copy >/dev/null && wl-copy || command -v xclip >/dev/null && xclip -selection clipboard || command -v xsel >/dev/null && xsel --clipboard --input || cat >/dev/null)",
      "daily-bread-copy", t
    ]
    copyProc.running = true
    store.showToast("Copied")
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

  function openUrlExternal(url) {
    var u = String(url || "").trim()
    if (!u.length) {
      store.showToast("No URL")
      return false
    }
    try {
      Qt.openUrlExternally(u)
      store.showToast("Opened")
      return true
    } catch (e) {
      openUrlProc.command = ["xdg-open", u]
      openUrlProc.running = true
      store.showToast("Opened")
      return true
    }
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

  function persistToDisk(obj) {
    var body = JSON.stringify(obj || store.buildCacheObject(), null, 2) + "\n"
    ensureCacheDir.running = true
    Qt.callLater(function() {
      try {
        cacheFile.setText(body)
      } catch (e) {}
    })
  }

  function applyPayload(obj, source) {
    if (!obj || typeof obj !== "object") return false
    var payload = obj.payload !== undefined ? obj.payload : obj
    if (!payload || typeof payload !== "object") return false
    if (payload.ok === false && !(payload.text && payload.reference)) {
      store.lastError = String(payload.error || "fetch failed")
      store.dataSource = source || store.dataSource
      store.dataChanged()
      return false
    }
    store.reference = String(payload.reference || "")
    store.text = String(payload.text || "")
    store.url = String(payload.url || "")
    store.verseVersion = String(payload.version || store.version || "web").toLowerCase()
    store.verseDate = String(payload.date || obj.date || store.todayIso())
    store.fetchedAt = obj.fetchedAt || payload.fetchedAt || store.fetchedAt || ""
    store.bookSlug = String(payload.book_slug || "")
    store.chapter = payload.chapter !== undefined ? payload.chapter : null
    store.verseStart = payload.verse_start !== undefined ? payload.verse_start : null
    store.verseEnd = payload.verse_end !== undefined ? payload.verse_end : null
    store.lastError = payload.error ? String(payload.error) : ""
    store.dataSource = source || "network"
    store.dataChanged()
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
    store.forceRefresh = !!force
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
    votdProc.command = [
      "python3",
      store.votdPath,
      "--version", store.normalizeVersion(store.version),
      "--language", store.normalizeLanguage(store.language)
    ]
    votdProc.running = true
    store.dataChanged()
  }

  function onVotdFinished(exitCode) {
    store.loading = false
    var raw = store.votdBuf || ""
    store.votdBuf = ""
    if (!raw.length) {
      // Keep last verse if we have one (offline)
      if (store.hasVerse) {
        store.lastError = "offline — showing last verse"
        store.showToast("Offline")
      } else {
        store.lastError = "votd produced no output (exit " + exitCode + ")"
        store.showToast("Failed")
      }
      store.dataChanged()
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
        store.lastError = String(obj.error || "fetch failed")
        if (!store.hasVerse)
          store.applyPayload({ payload: obj }, "network")
        store.showToast(store.lastError)
      }
      store.dataChanged()
    } catch (e) {
      store.lastError = "votd JSON parse failed"
      store.showToast("Failed")
      store.dataChanged()
    }
  }

  function bootstrap() {
    cacheFile.reload()
  }

  function handleSummonPayload(obj) {
    if (obj === undefined || obj === null || obj === "")
      return false
    if (typeof obj === "string") {
      var raw = String(obj).trim()
      if (!raw.length) return false
      try { obj = JSON.parse(raw) } catch (e) {
        // Treat bare string as version slug
        store.setVersion(raw)
        return true
      }
    }
    if (typeof obj !== "object") return false
    var acted = false
    if (obj.version || obj.v || obj.translation) {
      store.setVersion(obj.version || obj.v || obj.translation)
      acted = true
    }
    if (obj.language || obj.lang) {
      store.language = store.normalizeLanguage(obj.language || obj.lang)
      acted = true
    }
    if (obj.refresh === true || obj.refresh === "true" || obj.refresh === 1
        || obj.reload === true) {
      store.refresh(true)
      acted = true
    }
    return acted
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
    printErrors: false
    onLoaded: store.onCacheLoaded(text())
    onLoadFailed: { store.refresh(false) }
  }

  Process {
    id: ensureCacheDir
    command: ["mkdir", "-p", store.cacheDir]
    running: false
  }

  Process {
    id: copyProc
    running: false
  }

  Process {
    id: openUrlProc
    running: false
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
