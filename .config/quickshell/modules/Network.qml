import Quickshell.Io
import QtQuick
import ".."

Item {
    id: root

    Theme { id: theme }
    implicitWidth: label.implicitWidth + 8
    implicitHeight: 22

    property bool connected: false
    property bool isWifi: false
    property string networkName: ""
    property bool keepPopupOpen: false
    property bool showNetworkName: (mouseArea.containsMouse || keepPopupOpen) && connected && isWifi && networkName.length > 0
    property int popupWidth: Math.min(Math.max(networkNameMetrics.width + 32, 84), 260)

    Process {
        id: netProc
        command: ["sh", "-c", "eth=$(ip route | awk '/^default/{print $5}' | while IFS= read -r iface; do [ ! -d \"/sys/class/net/$iface/wireless\" ] && echo \"$iface\" && break; done); ssid=$(iwgetid -r 2>/dev/null || true); if [ -n \"$eth\" ]; then printf 'eth\\t%s\\n' \"$eth\"; elif [ -n \"$ssid\" ]; then printf 'wifi\\t%s\\n' \"$ssid\"; else printf 'none\\t\\n'; fi"]
        stdout: StdioCollector {}
        onExited: {
            const out = stdout.text.trim()
            const parts = out.split("\t")
            const kind = parts[0] || "none"
            const name = parts.slice(1).join("\t")
            if (kind === "wifi") {
                isWifi = true
                connected = true
                networkName = name
            } else if (kind === "eth") {
                isWifi = false
                connected = true
                networkName = name
            } else {
                connected = false
                isWifi = false
                networkName = ""
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: !connected ? "⚠" : isWifi ? "" : String.fromCodePoint(0xF0200)
        color: connected ? theme.fg : theme.warning
        font.pixelSize: 12
        font.family: "Hack Nerd Font"
    }

    TextMetrics {
        id: networkNameMetrics
        text: root.networkName
        font.pixelSize: 12
        font.family: "Hack Nerd Font"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
