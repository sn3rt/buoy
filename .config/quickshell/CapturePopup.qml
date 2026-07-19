import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    Theme { id: theme }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-capture"

    anchors {
        left: true
        right: true
        bottom: true
    }

    implicitHeight: 126
    visible: opened || openProgress > 0.01
    color: "transparent"

    property bool opened: false
    property real openProgress: opened ? 1 : 0

    mask: Region {
        Region {
            item: popupSurface
            width: root.openProgress > 0.01 ? popupSurface.width : 0
            height: root.openProgress > 0.01 ? popupSurface.height : 0
        }
    }

    function show() {
        opened = true
        closeTimer.restart()
    }

    function hide() {
        closeTimer.stop()
        opened = false
    }

    function runAction(action) {
        hide()
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/capture-action", action])
    }

    IpcHandler {
        target: "capture"

        function open() {
            root.show()
        }

        function close() {
            root.hide()
        }

        function toggle() {
            if (root.opened) root.hide()
            else root.show()
        }
    }

    Timer {
        id: closeTimer
        interval: 8000
        repeat: false
        onTriggered: root.hide()
    }

    Behavior on openProgress {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: popupSurface
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 18
        }
        width: Math.min(root.width - 28, 490)
        height: 74
        radius: 8
        color: theme.panelStrong
        border.color: Qt.rgba(theme.primary.r, theme.primary.g, theme.primary.b, 0.32)
        border.width: 1
        opacity: root.openProgress
        scale: 0.96 + root.openProgress * 0.04
        transformOrigin: Item.Bottom
        enabled: root.visible
        visible: root.openProgress > 0.01

        RowLayout {
            anchors {
                fill: parent
                margins: 8
            }
            spacing: 8

            CaptureButton {
                icon: ""
                label: "Screen"
                tooltip: "Full screenshot"
                onClicked: root.runAction("screenshot-full")
            }

            CaptureButton {
                icon: "󰩭"
                label: "Area"
                tooltip: "Area screenshot"
                onClicked: root.runAction("screenshot-area")
            }

            CaptureButton {
                icon: ""
                label: "Record"
                tooltip: "Fullscreen recording"
                onClicked: root.runAction("record-full")
            }

            CaptureButton {
                icon: "󰹑"
                label: "Clip"
                tooltip: "Area recording"
                onClicked: root.runAction("record-area")
            }

            CaptureButton {
                icon: "󰓛"
                label: "Stop"
                tooltip: "Stop recording"
                onClicked: root.runAction("record-stop")
            }

            CaptureButton {
                icon: ""
                label: "Close"
                tooltip: "Close"
                onClicked: root.hide()
            }
        }
    }

    component CaptureButton: Rectangle {
        id: buttonRoot

        signal clicked()

        required property string icon
        required property string label
        property string tooltip: label

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 6
        color: hoverHandler.hovered ? Qt.rgba(theme.primary.r, theme.primary.g, theme.primary.b, 0.22) : "transparent"
        border.color: hoverHandler.hovered ? Qt.rgba(theme.primary.r, theme.primary.g, theme.primary.b, 0.42) : "transparent"
        border.width: 1

        HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: if (hovered) closeTimer.restart()
        }

        MouseArea {
            anchors.fill: parent
            enabled: popupSurface.visible
            onClicked: buttonRoot.clicked()
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: buttonRoot.icon
                color: theme.fg
                font.pixelSize: 18
                font.family: "Hack Nerd Font"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: buttonRoot.label
                color: theme.muted
                font.pixelSize: 10
                font.family: "Hack Nerd Font"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }
}
