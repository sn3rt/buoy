import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Item {
    id: root

    Theme { id: theme }
    implicitWidth: label.implicitWidth + 8
    implicitHeight: 22
    visible: recording

    property bool recording: false

    Process {
        id: recordProc
        command: ["pgrep", "-x", "wf-recorder"]
        onExited: (exitCode) => root.recording = exitCode === 0
    }

    Process {
        id: stopProc
        command: [Quickshell.env("HOME") + "/.local/bin/capture-action", "record-stop"]
        onExited: recordProc.running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: recordProc.running = true
    }

    Rectangle {
        anchors.centerIn: parent
        width: 14
        height: 14
        radius: 7
        color: Qt.rgba(theme.error.r, theme.error.g, theme.error.b, 0.18)
        border.color: theme.error
        border.width: 1
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: "●"
        color: theme.error
        font.pixelSize: 12
        font.family: "Hack Nerd Font"
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: stopProc.running = true
    }
}
