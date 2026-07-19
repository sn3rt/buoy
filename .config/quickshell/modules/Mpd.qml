import Quickshell.Io
import QtQuick
import ".."

Item {
    Theme { id: theme }
    implicitWidth: visible ? (playBtn.implicitWidth + track.implicitWidth + 12) : 0
    implicitHeight: parent.height

    property string trackInfo: ""
    property bool playing: false

    visible: trackInfo !== ""

    Process {
        id: statusProc
        command: ["mpc", "status", "%state%"]
        stdout: StdioCollector {}
        onExited: {
            const state = stdout.text.trim()
            playing = (state === "playing")
            if (state === "playing" || state === "paused") {
                trackProc.running = true
            } else {
                trackInfo = ""
            }
        }
    }

    Process {
        id: trackProc
        command: ["mpc", "--format", "%artist% - %title%", "current"]
        stdout: StdioCollector {}
        onExited: {
            trackInfo = stdout.text.trim()
        }
    }

    Process {
        id: toggleProc
        command: ["mpc", "toggle"]
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }

    Row {
        anchors.centerIn: parent
        spacing: 4

        Text {
            id: playBtn
            text: playing ? " " : " "
            color: theme.fg
            font.pixelSize: 12

            MouseArea {
                anchors.fill: parent
                onClicked: toggleProc.running = true
            }
        }

        Text {
            id: track
            text: trackInfo.length > 35 ? trackInfo.slice(0, 35) + "…" : trackInfo
            color: theme.fg
            font.pixelSize: 12
            font.family: "Roboto"
        }
    }
}
