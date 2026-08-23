import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Daily Bread bar entry — Yellow Pixels / Fair Witness pattern:
// BarWidget loads nested Panel.qml via Loader. kinds: ["bar-widget"] only.
BarWidget {
  id: root
  moduleName: "harris.daily-bread"

  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  readonly property color foreground: root.bar ? root.bar.foreground : Color.foreground
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : "monospace"

  // Soft amber / parchment accent — quiet pause vibe
  readonly property color dailyBreadAccent: Qt.rgba(0.91, 0.72, 0.38, 1.0)

  property string version: {
    try {
      if (root.settings && root.settings.version !== undefined)
        return dailyBreadStore.normalizeVersion(root.settings.version)
      if (typeof root.setting === "function")
        return dailyBreadStore.normalizeVersion(root.setting("version", "web"))
    } catch (e) {}
    return "web"
  }

  property string language: {
    try {
      if (root.settings && root.settings.language !== undefined)
        return dailyBreadStore.normalizeLanguage(root.settings.language)
      if (typeof root.setting === "function")
        return dailyBreadStore.normalizeLanguage(root.setting("language", "en"))
    } catch (e) {}
    return "en"
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function handleSummonPayload(obj) {
    return dailyBreadStore.handleSummonPayload(obj)
  }

  function open(payloadJson) {
    if (payloadJson !== undefined && payloadJson !== null && String(payloadJson).length)
      root.handleSummonPayload(payloadJson)
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

  function onBarMiddleClick() {
    // Useful middle-click: force refresh VOTD with toast.
    dailyBreadStore.refresh(true)
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("store" in target) target.store = dailyBreadStore
  }

  function syncStoreSettings() {
    dailyBreadStore.applySettings({
      version: root.version,
      language: root.language
    })
  }

  onBarChanged: injectPanel()
  onSettingsChanged: {
    injectPanel()
    syncStoreSettings()
  }
  onVersionChanged: syncStoreSettings()
  onLanguageChanged: syncStoreSettings()

  DailyBreadStore {
    id: dailyBreadStore
  }

  Component.onCompleted: {
    syncStoreSettings()
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: dailyBreadStore.barLabel || "● Bread"
    horizontalMargin: 8.5
    tooltipText: {
      var tip = "Daily Bread — verse of the day · middle: refresh"
      if (dailyBreadStore.loading)
        tip = "Daily Bread — refreshing… · middle: refresh"
      else if (dailyBreadStore.reference) {
        tip = "Daily Bread — " + dailyBreadStore.reference
        if (dailyBreadStore.showingCached)
          tip += " (cached)"
        tip += " · middle: refresh"
      }
      return tip
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
      else if (buttonCode === Qt.MiddleButton) root.onBarMiddleClick()
    }
  }
}
