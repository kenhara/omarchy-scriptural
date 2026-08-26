import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Nested details panel for Scriptural (loaded by BarWidget — not a separate kind).
// KeyboardPanel shell (Compliantish/Rocketlauncher).
// Verse of the day. Midvash public VOTD.
Panel {
  id: root
  moduleName: "kenhara.scriptural"
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
  readonly property color scripturalAccent: Qt.rgba(0.91, 0.72, 0.38, 1.0)

  readonly property var liveStore: store

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  readonly property int panelBaseHeight: Style.space(640)

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(390))
    contentHeight: panel.fittedContentHeight(root.panelBaseHeight)
    popoutSwitching: root.popoutSwitching
    popoutSwitchClosing: root.popoutSwitchClosing

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

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

            Row {
              spacing: Style.space(8)
              Text {
                text: "\uf02d"
                color: root.scripturalAccent
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                anchors.verticalCenter: parent.verticalCenter
              }
              Text {
                text: "SCRIPTURAL"
                color: root.scripturalAccent
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                font.letterSpacing: 3.2
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            Text {
              text: "Bible verse of the day"
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
            textFormat: Text.PlainText
            color: Color.urgent
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Text {
            width: parent.width
            visible: liveStore && liveStore.toastText && liveStore.toastText.length
            text: liveStore ? liveStore.toastText : ""
            textFormat: Text.PlainText
            color: root.scripturalAccent
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.bodySmall
          }

          // Verse card
          Rectangle {
            width: parent.width
            visible: liveStore && liveStore.hasVerse
            height: visible ? verseInner.implicitHeight + Style.space(28) : 0
            radius: Style.space(12)
            color: Qt.rgba(root.scripturalAccent.r, root.scripturalAccent.g, root.scripturalAccent.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(root.scripturalAccent.r, root.scripturalAccent.g, root.scripturalAccent.b, 0.35)

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
                textFormat: Text.PlainText
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                font.italic: true
                wrapMode: Text.WordWrap
                lineHeight: 1.35
              }

              Row {
                spacing: Style.space(8)
                width: parent.width

                Text {
                  text: liveStore ? (liveStore.reference || "") : ""
                  textFormat: Text.PlainText
                  color: root.contentForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                  width: chipLabel.implicitWidth + Style.space(14)
                  height: Style.space(22)
                  radius: Style.space(6)
                  color: Qt.rgba(root.scripturalAccent.r, root.scripturalAccent.g, root.scripturalAccent.b, 0.2)
                  border.width: 1
                  border.color: Qt.rgba(root.scripturalAccent.r, root.scripturalAccent.g, root.scripturalAccent.b, 0.45)
                  anchors.verticalCenter: parent.verticalCenter

                  Text {
                    id: chipLabel
                    anchors.centerIn: parent
                    text: liveStore ? (liveStore.versionChip || "WEB") : "WEB"
                    textFormat: Text.PlainText
                    color: root.scripturalAccent
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

          // Actions — compact glyph+label chips (Encyclopedic style)
          Row {
            spacing: Style.space(8)
            visible: liveStore && liveStore.hasVerse

            ActionChip {
              glyph: "\uf0c5"
              label: "Copy"
              accent: true
              onClicked: if (liveStore) liveStore.copyVerse()
            }
            ActionChip {
              glyph: "\uf02d"
              label: "Copy ref"
              onClicked: if (liveStore) liveStore.copyReference()
            }
            ActionChip {
              glyph: "\uf08e"
              label: "Open"
              onClicked: if (liveStore) liveStore.openVerse()
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
                  { slug: "niv", label: "NIV" },
                  { slug: "nkjv", label: "NKJV" },
                  { slug: "nlt", label: "NLT" },
                  { slug: "msg", label: "MSG" }
                ]
                delegate: Rectangle {
                  required property var modelData
                  property bool selected: liveStore
                    ? liveStore.chipSelected(modelData.slug)
                    : false
                  width: Math.max(Style.space(48), chipText.implicitWidth + Style.space(16))
                  height: Style.space(28)
                  radius: Style.space(8)
                  color: {
                    if (chipMa.containsMouse && !selected)
                      return Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)
                    if (selected)
                      return Qt.rgba(root.scripturalAccent.r, root.scripturalAccent.g, root.scripturalAccent.b, 0.28)
                    return Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.06)
                  }
                  border.width: 1
                  border.color: selected
                    ? Qt.rgba(root.scripturalAccent.r, root.scripturalAccent.g, root.scripturalAccent.b, 0.55)
                    : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)

                  Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: modelData.label || String(modelData.slug || "").toUpperCase()
                    color: selected ? root.scripturalAccent : root.contentForeground
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

          }

          // Quiet footer
          Text {
            width: parent.width
            text: "Unofficial · Bible · Midvash · WEB public domain"
            color: root.contentForeground
            opacity: 0.22
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }

  // Compact glyph+label chips (FA/Nerd, tintable). Copy / Copy ref / Open.
  component ActionChip: Rectangle {
    id: chip
    property string glyph: ""
    property string label: ""
    property bool accent: false
    signal clicked()

    readonly property bool hovered: chipMa.containsMouse

    implicitWidth: chipRow.implicitWidth + Style.space(16)
    implicitHeight: Style.space(26)
    width: implicitWidth
    height: implicitHeight
    radius: 6
    color: chip.accent
      ? (chip.hovered
          ? Qt.rgba(root.scripturalAccent.r, root.scripturalAccent.g, root.scripturalAccent.b, 0.34)
          : Qt.rgba(root.scripturalAccent.r, root.scripturalAccent.g, root.scripturalAccent.b, 0.22))
      : (chip.hovered
          ? Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.14)
          : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.08))
    border.width: 1
    border.color: chip.accent
      ? Qt.rgba(root.scripturalAccent.r, root.scripturalAccent.g, root.scripturalAccent.b, 0.5)
      : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)

    Row {
      id: chipRow
      anchors.centerIn: parent
      spacing: Style.space(6)
      Text {
        text: chip.glyph
        color: chip.accent ? root.scripturalAccent : root.contentForeground
        font.family: root.contentFontFamily
        font.pixelSize: Style.font.caption
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        text: chip.label
        color: root.contentForeground
        font.family: root.contentFontFamily
        font.pixelSize: Style.font.caption
        font.bold: chip.accent
        anchors.verticalCenter: parent.verticalCenter
      }
    }
    MouseArea {
      id: chipMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: chip.clicked()
    }
  }
}
