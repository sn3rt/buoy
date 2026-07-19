import Quickshell.Io
import QtQuick
import ".."

Item {
    id: root

    Theme { id: theme }
    implicitWidth: 20
    implicitHeight: parent.height

    property int vol: 0
    property bool muted: false
    property int lastVol: -1
    property bool lastMuted: false
    property bool keepPopupOpen: false
    property bool showValue: mouseArea.containsMouse || keepPopupOpen || revealTimer.running
    property string popupText: muted ? "muted" : vol + "%"
    property int popupWidth: Math.min(Math.max(valueMetrics.width, fitMetrics.width) + 20, 140)

    property string icon: {
        if (vol >= 70) return ""
        if (vol >= 30) return ""
        return ""
    }

    Process {
        id: volProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {}
        onExited: {
            const text = stdout.text.trim()
            const match = text.match(/Volume:\s+([\d.]+)(\s+\[MUTED\])?/)
            if (match) {
                const nextVol = Math.round(parseFloat(match[1]) * 100)
                const nextMuted = match[2] !== undefined
                if (lastVol >= 0 && (nextVol !== vol || nextMuted !== muted)) {
                    revealTimer.restart()
                }
                vol = nextVol
                muted = nextMuted
                lastVol = nextVol
                lastMuted = nextMuted
            }
        }
    }

    Process {
        id: muteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        onExited: volProc.running = true
    }

    Process {
        id: volUpProc
        command: ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", "5%+"]
        onExited: volProc.running = true
    }

    Process {
        id: volDownProc
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]
        onExited: volProc.running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: volProc.running = true
    }

    Timer {
        id: revealTimer
        interval: 1500
        repeat: false
    }

    Text {
        id: iconText
        anchors.centerIn: parent
        text: muted ? String.fromCodePoint(0xF075F) : icon
        color: theme.fg
        font.pixelSize: 11
        font.family: "Hack Nerd Font"
    }

    TextMetrics {
        id: valueMetrics
        text: root.popupText
        font.pixelSize: 11
        font.family: "Hack Nerd Font"
    }

    TextMetrics {
        id: fitMetrics
        text: "100%"
        font.pixelSize: 11
        font.family: "Hack Nerd Font"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            revealTimer.restart()
            muteProc.running = true
        }
        onWheel: (wheel) => {
            revealTimer.restart()
            if (wheel.angleDelta.y > 0) volUpProc.running = true
            else volDownProc.running = true
        }
    }
}
