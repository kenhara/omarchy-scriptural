import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Nested details panel for Daily Bread (loaded by BarWidget — not a separate kind).
// 0.1.1 — verse of the day · pause. Midvash public VOTD.
Panel {
  id: root
  moduleName: "harris.daily-bread"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var store: null

  readonly property var barIdentity: hostWidget || root
  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : "monospace"
  readonly property color themeBackground: {
    try {
      if (typeof Color !== "undefined" && Color.popups && Color.popups.background)
        return Color.popups.background
      if (typeof Color !== "undefined" && Color.background)
        return Color.background
    } catch (e) {}
    return Qt.rgba(0.1, 0.1, 0.12, 1)
  }
  readonly property color surfaceColor: Qt.rgba(
    contentForeground.r, contentForeground.g, contentForeground.b, 0.06)
  readonly property color dimForeground: Qt.darker(contentForeground, 1.45)
  readonly property color dailyBreadAccent: Qt.rgba(0.91, 0.72, 0.38, 1.0)

  readonly property var liveStore: store

  // Popout-switch safety — bar may call this while switching panels.
  property bool popoutSwitchClosing: false
  function closeForPopoutSwitch() {
    root.popoutSwitchClosing = true
    try {
      if (typeof root.close === "function")
        root.close()
    } finally {
      Qt.callLater(function () { root.popoutSwitchClosing = false })
    }
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function handleSummonPayload(obj) {
    if (!liveStore) return false
    var acted = liveStore.handleSummonPayload(obj)
    if (acted && !root.opened)
      root.open()
    return acted
  }

  implicitWidth: Style.space(420)
  implicitHeight: Math.min(Style.space(640), contentCol.implicitHeight + Style.space(36))

  Rectangle {
    anchors.fill: parent
    color: root.themeBackground
    radius: Style.space(12)

    Flickable {
      id: flick
      anchors.fill: parent
      anchors.margins: Style.space(16)
      contentWidth: width
      contentHeight: contentCol.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: contentCol
        width: flick.width
        spacing: Style.space(14)
        opacity: liveStore && liveStore.loading ? 0.72 : 1.0

        Behavior on opacity {
          NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        // Header
        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            text: "DAILY BREAD"
            color: root.dailyBreadAccent
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.title
            font.bold: true
            font.letterSpacing: 3.2
          }

          Text {
            text: "verse of the day · pause"
            color: root.contentForeground
            opacity: 0.5
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.body
            width: parent.width
          }
        }

        // Toast / error
        Text {
          width: parent.width
          visible: liveStore && liveStore.lastError && liveStore.lastError.length
          text: liveStore ? liveStore.lastError : ""
          color: Color.urgent
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }

        Text {
          width: parent.width
          visible: liveStore && liveStore.toastText && liveStore.toastText.length
          text: liveStore ? liveStore.toastText : ""
          color: root.dailyBreadAccent
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
        }

        // Verse card
        Rectangle {
          width: parent.width
          visible: liveStore && liveStore.hasVerse
          height: visible ? verseInner.implicitHeight + Style.space(28) : 0
          radius: Style.space(12)
          color: Qt.rgba(root.dailyBreadAccent.r, root.dailyBreadAccent.g, root.dailyBreadAccent.b, 0.08)
          border.width: 1
          border.color: Qt.rgba(root.dailyBreadAccent.r, root.dailyBreadAccent.g, root.dailyBreadAccent.b, 0.35)

          Column {
            id: verseInner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(16)
            spacing: Style.space(12)

            Text {
              width: parent.width
              text: liveStore ? (liveStore.text || "") : ""
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.title
              font.italic: true
              wrapMode: Text.WordWrap
              lineHeight: 1.35
            }

            Row {
              spacing: Style.space(8)
              width: parent.width

              Text {
                text: liveStore ? (liveStore.reference || "") : ""
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.subtitle
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
              }

              Rectangle {
                width: chipLabel.implicitWidth + Style.space(14)
                height: Style.space(22)
                radius: Style.space(6)
                color: Qt.rgba(root.dailyBreadAccent.r, root.dailyBreadAccent.g, root.dailyBreadAccent.b, 0.2)
                border.width: 1
                border.color: Qt.rgba(root.dailyBreadAccent.r, root.dailyBreadAccent.g, root.dailyBreadAccent.b, 0.45)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  id: chipLabel
                  anchors.centerIn: parent
                  text: liveStore ? (liveStore.versionChip || "WEB") : "WEB"
                  color: root.dailyBreadAccent
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 1.2
                }
              }

              Rectangle {
                visible: liveStore && liveStore.showingCached
                width: cachedLabel.implicitWidth + Style.space(14)
                height: Style.space(22)
                radius: Style.space(6)
                color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.08)
                border.width: 1
                border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.16)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  id: cachedLabel
                  anchors.centerIn: parent
                  text: "cached"
                  color: root.contentForeground
                  opacity: 0.65
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }
              }
            }
          }
        }

        // Empty honesty
        Text {
          width: parent.width
          visible: liveStore && !liveStore.hasVerse && !(liveStore.loading)
          text: "No verse yet. Middle-click the bar to refresh."
          color: root.contentForeground
          opacity: 0.5
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.body
          wrapMode: Text.WordWrap
        }

        // Actions
        Row {
          spacing: Style.space(8)
          visible: liveStore && liveStore.hasVerse

          Rectangle {
            id: copyVerseBtn
            width: Style.space(92)
            height: Style.space(30)
            radius: Style.space(6)
            color: copyVerseMa.containsMouse
              ? Qt.rgba(root.dailyBreadAccent.r, root.dailyBreadAccent.g, root.dailyBreadAccent.b, 0.34)
              : Qt.rgba(root.dailyBreadAccent.r, root.dailyBreadAccent.g, root.dailyBreadAccent.b, 0.22)
            border.width: 1
            border.color: Qt.rgba(root.dailyBreadAccent.r, root.dailyBreadAccent.g, root.dailyBreadAccent.b, 0.5)
            Text {
              anchors.centerIn: parent
              text: "Copy verse"
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
            MouseArea {
              id: copyVerseMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (liveStore) liveStore.copyVerse()
            }
          }

          Rectangle {
            id: copyRefBtn
            width: Style.space(110)
            height: Style.space(30)
            radius: Style.space(6)
            color: copyRefMa.containsMouse
              ? Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.14)
              : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)
            Text {
              anchors.centerIn: parent
              text: "Copy reference"
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
            }
            MouseArea {
              id: copyRefMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (liveStore) liveStore.copyReference()
            }
          }

          Rectangle {
            id: openBtn
            width: Style.space(56)
            height: Style.space(30)
            radius: Style.space(6)
            color: openMa.containsMouse
              ? Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.14)
              : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)
            Text {
              anchors.centerIn: parent
              text: "Open"
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
            MouseArea {
              id: openMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (liveStore) liveStore.openVerse()
            }
          }
        }

        // Translation chips
        Column {
          width: parent.width
          spacing: Style.space(8)

          Text {
            text: "TRANSLATION"
            color: root.contentForeground
            opacity: 0.4
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.6
          }

          Flow {
            width: parent.width
            spacing: Style.space(8)

            Repeater {
              model: liveStore ? liveStore.quickVersions : [
                { slug: "web", label: "WEB" },
                { slug: "kjv", label: "KJV" },
                { slug: "esv", label: "ESV" },
                { slug: "niv", label: "NIV" }
              ]
              delegate: Rectangle {
                required property var modelData
                property bool selected: liveStore
                  && liveStore.normalizeVersion(liveStore.version) === String(modelData.slug)
                width: Style.space(48)
                height: Style.space(28)
                radius: Style.space(8)
                color: {
                  if (chipMa.containsMouse && !selected)
                    return Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)
                  if (selected)
                    return Qt.rgba(root.dailyBreadAccent.r, root.dailyBreadAccent.g, root.dailyBreadAccent.b, 0.28)
                  return Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.06)
                }
                border.width: 1
                border.color: selected
                  ? Qt.rgba(root.dailyBreadAccent.r, root.dailyBreadAccent.g, root.dailyBreadAccent.b, 0.55)
                  : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)

                Text {
                  anchors.centerIn: parent
                  text: modelData.label || String(modelData.slug || "").toUpperCase()
                  color: selected ? root.dailyBreadAccent : root.contentForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: selected
                }

                MouseArea {
                  id: chipMa
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: if (liveStore) liveStore.setVersion(modelData.slug)
                }
              }
            }
          }

          Text {
            width: parent.width
            text: "NKJV · NLT · MSG in widget settings"
            color: root.contentForeground
            opacity: 0.32
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }

        // Quiet footer
        Column {
          width: parent.width
          spacing: Style.space(4)

          Text {
            width: parent.width
            text: "Midvash · unofficial · public API · VOTD day = UTC"
            color: root.contentForeground
            opacity: 0.22
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Text {
            width: parent.width
            text: "WEB public domain · ESV/NIV/… personal display via API — translation © holders"
            color: root.contentForeground
            opacity: 0.18
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }
}
