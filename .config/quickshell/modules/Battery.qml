import Quickshell.Io
import QtQuick
import ".."

Item {
    id: root

    Theme { id: theme }
    implicitWidth: 20
    implicitHeight: parent.height

    property int pct: 0
    property string status: "Unknown"
    property bool charging: status === "Charging" || status === "Full"
    property int lastPct: -1
    property string lastStatus: ""
    property bool keepPopupOpen: false
    property bool showValue: mouseArea.containsMouse || keepPopupOpen || revealTimer.running
    property string popupText: pct + "%"
    property int popupWidth: Math.min(Math.max(valueMetrics.width, fitMetrics.width) + 20, 140)

    property string icon: {
        if (charging) return ""
        if (pct >= 90) return ""
        if (pct >= 70) return ""
        if (pct >= 40) return ""
        if (pct >= 20) return ""
        return ""
    }

    Process {
        id: batProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity && cat /sys/class/power_supply/BAT0/status"]
        stdout: StdioCollector {}
        onExited: {
            const lines = stdout.text.trim().split('\n')
            const nextPct = parseInt(lines[0]) || 0
            const nextStatus = lines[1] || "Unknown"
            if (lastPct >= 0 && (nextPct !== pct || nextStatus !== status)) {
                revealTimer.restart()
            }
            pct = nextPct
            status = nextStatus
            lastPct = nextPct
            lastStatus = nextStatus
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: batProc.running = true
    }

    Timer {
        id: revealTimer
        interval: 1500
        repeat: false
    }

    Text {
        id: iconText
        anchors.centerIn: parent
        text: icon
        color: pct <= 15 ? theme.error : pct <= 30 ? theme.warning : theme.fg
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
    }
}
