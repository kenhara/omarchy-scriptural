import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Scriptural bar entry — Enricherino / Encyclopedic pattern:
// BarWidget loads nested Panel.qml via Loader. kinds: ["bar-widget"] only.
BarWidget {
  id: root
  moduleName: "kenhara.scriptural"

  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  // Soft amber / parchment accent — quiet pause vibe
  readonly property color scripturalAccent: Qt.rgba(0.91, 0.72, 0.38, 1.0)

  property string version: {
    try {
      if (root.settings && root.settings.version !== undefined)
        return scripturalStore.normalizeVersion(root.settings.version)
      if (typeof root.setting === "function")
        return scripturalStore.normalizeVersion(root.setting("version", "web"))
    } catch (e) {}
    return "web"
  }

  property string language: {
    try {
      if (root.settings && root.settings.language !== undefined)
        return scripturalStore.normalizeLanguage(root.settings.language)
      if (typeof root.setting === "function")
        return scripturalStore.normalizeLanguage(root.setting("language", "en"))
    } catch (e) {}
    return "en"
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  // Local name — middle-click force-refreshes VOTD (not a framework hook).
  function refreshVotd() {
    scripturalStore.refresh(true)
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("store" in target) target.store = scripturalStore
  }

  function syncStoreSettings() {
    scripturalStore.applySettings({
      version: root.version,
      language: root.language
    })
  }

  // Best-effort write-back so chip setVersion survives reload.
  function mirrorVersion(slug) {
    if (!root.settings) return
    try {
      root.settings.version = scripturalStore.normalizeVersion(slug)
    } catch (e) {}
  }

  onBarChanged: injectPanel()
  onSettingsChanged: {
    injectPanel()
    syncStoreSettings()
  }
  onVersionChanged: syncStoreSettings()
  onLanguageChanged: syncStoreSettings()

  ScripturalStore {
    id: scripturalStore
    onVersionChosen: function(slug) {
      root.mirrorVersion(slug)
    }
  }

  Component.onCompleted: {
    syncStoreSettings()
  }

  property string panelLoadError: ""

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.panelLoadError = ""
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
    onStatusChanged: {
      if (status === Loader.Error) {
        var err = ""
        try {
          if (sourceComponent)
            err = String(sourceComponent.errorString || "")
        } catch (e) {}
        root.panelLoadError = err.length ? err : "Panel.qml failed to load"
        console.warn(moduleName + " panel load failed: " + root.panelLoadError)
      }
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: scripturalStore.barLabel || "● SCR"
    horizontalMargin: 8.5
    tooltipText: {
      var tip = "Scriptural — verse of the day · middle: refresh"
      if (scripturalStore.loading)
        tip = "Scriptural — refreshing… · middle: refresh"
      else if (scripturalStore.reference) {
        tip = "Scriptural — " + scripturalStore.reference
        if (scripturalStore.showingCached)
          tip += " (cached)"
        tip += " · middle: refresh"
      }
      if (root.panelLoadError && root.panelLoadError.length) {
        var pe = root.panelLoadError
        if (pe.length > 120)
          pe = pe.substring(0, 117) + "…"
        tip += " · panel load error — " + pe
      }
      return tip
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
      else if (buttonCode === Qt.MiddleButton) root.refreshVotd()
    }
  }
}
