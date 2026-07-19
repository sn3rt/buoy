import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Item {
    id: root

    Theme { id: theme }
    implicitWidth: row.implicitWidth
    implicitHeight: parent.height

    property real cpuUsage: 0
    property real memPercent: 0
    property real tempC: 0
    property bool keepCpuPopupOpen: false
    property bool keepMemPopupOpen: false
    property bool keepTempPopupOpen: false
    property bool showCpuValue: cpuMouseArea.containsMouse || keepCpuPopupOpen
    property bool showMemValue: memMouseArea.containsMouse || keepMemPopupOpen
    property bool showTempValue: tempMouseArea.containsMouse || keepTempPopupOpen
    property string cpuPopupText: cpuUsage + "%"
    property string memPopupText: memPercent + "%"
    property string tempPopupText: tempC + "°C"
    property int cpuPopupWidth: Math.min(Math.max(cpuMetrics.width, percentFitMetrics.width) + 20, 140)
    property int memPopupWidth: Math.min(Math.max(memMetrics.width, percentFitMetrics.width) + 20, 140)
    property int tempPopupWidth: Math.min(Math.max(tempMetrics.width, tempFitMetrics.width) + 20, 140)
    property real cpuCenterX: row.x + content.x + cpuText.x + cpuText.width / 2
    property real memCenterX: row.x + content.x + memText.x + memText.width / 2
    property real tempCenterX: row.x + content.x + tempText.x + tempText.width / 2
    property color cpuColor: cpuUsage >= 80 ? theme.error : cpuUsage >= 50 ? theme.warning : theme.fg
    property color memColor: memPercent >= 80 ? theme.error : memPercent >= 50 ? theme.warning : theme.fg
    property color tempColor: tempC >= 80 ? theme.error : tempC >= 60 ? theme.warning : theme.fg

    property var _prevIdle: 0
    property var _prevTotal: 0

    Process {
        id: cpuProc
        command: ["sh", "-c", "awk '/^cpu /{print $2,$3,$4,$5,$6,$7,$8}' /proc/stat"]
        stdout: StdioCollector {}
        onExited: {
            const parts = stdout.text.trim().split(" ").map(Number)
            const idle = parts[3] + parts[4]
            const total = parts.reduce((a, b) => a + b, 0)
            if (_prevTotal > 0) {
                const diffIdle = idle - _prevIdle
                const diffTotal = total - _prevTotal
                cpuUsage = Math.round((1 - diffIdle / diffTotal) * 100)
            }
            _prevIdle = idle
            _prevTotal = total
        }
    }

    Process {
        id: memProc
        command: ["sh", "-c", "free -m | awk '/^Mem:/{print $3,$2}'"]
        stdout: StdioCollector {}
        onExited: {
            const parts = stdout.text.trim().split(" ").map(Number)
            if (parts[1] > 0) memPercent = Math.round(parts[0] / parts[1] * 100)
        }
    }

    Process {
        id: tempProc
        command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0"]
        stdout: StdioCollector {}
        onExited: {
            tempC = Math.round(parseInt(stdout.text.trim()) / 1000)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
            tempProc.running = true
        }
    }

    Item {
        id: row
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight
        anchors.centerIn: parent

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 2

            Text {
                id: cpuText
                width: 22
                horizontalAlignment: Text.AlignHCenter
                text: ""
                color: cpuColor
                font.pixelSize: 12
                font.family: "Hack Nerd Font"

                MouseArea {
                    id: cpuMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            Text {
                id: memText
                width: 22
                horizontalAlignment: Text.AlignHCenter
                text: String.fromCodePoint(0xEFC5)
                color: memColor
                font.pixelSize: 12
                font.family: "Hack Nerd Font"

                MouseArea {
                    id: memMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            Text {
                id: tempText
                width: 22
                horizontalAlignment: Text.AlignHCenter
                text: tempC >= 80 ? "" : tempC >= 60 ? "" : ""
                color: tempColor
                font.pixelSize: 12
                font.family: "Hack Nerd Font"

                MouseArea {
                    id: tempMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }
    }

    TextMetrics {
        id: cpuMetrics
        text: root.cpuPopupText
        font.pixelSize: 11
        font.family: "Hack Nerd Font"
    }

    TextMetrics {
        id: memMetrics
        text: root.memPopupText
        font.pixelSize: 11
        font.family: "Hack Nerd Font"
    }

    TextMetrics {
        id: tempMetrics
        text: root.tempPopupText
        font.pixelSize: 11
        font.family: "Hack Nerd Font"
    }

    TextMetrics {
        id: percentFitMetrics
        text: "100%"
        font.pixelSize: 11
        font.family: "Hack Nerd Font"
    }

    TextMetrics {
        id: tempFitMetrics
        text: "100°C"
        font.pixelSize: 11
        font.family: "Hack Nerd Font"
    }
}
