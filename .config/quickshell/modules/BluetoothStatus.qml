import Quickshell.Bluetooth
import QtQuick
import ".."

Item {
    id: root

    Theme { id: theme }
    implicitWidth: label.implicitWidth + 8
    implicitHeight: 22

    // Only present when a device is connected; RowLayout drops invisible items
    // from layout, so the icon collapses without leaving a gap.
    visible: connected

    // Bump periodically so the connected-device computation re-evaluates even when
    // only a single device's `connected` flips (a filter over devices.values does
    // not re-fire on a nested device signal).
    property int _rev: 0
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._rev++
    }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter ? adapter.enabled : false
    readonly property var connectedDevices: {
        root._rev // dependency: force re-eval on tick
        if (!Bluetooth.devices) return []
        return Bluetooth.devices.values.filter(d => d.connected)
    }
    readonly property bool connected: connectedDevices.length > 0
    readonly property string deviceName: {
        if (!connected) return ""
        let d = connectedDevices[0]
        let name = d.deviceName || d.name || "Device"
        return connectedDevices.length > 1
            ? name + " +" + (connectedDevices.length - 1)
            : name
    }

    property bool keepPopupOpen: false
    property bool showDeviceName: (mouseArea.containsMouse || keepPopupOpen) && connected && deviceName.length > 0
    property int popupWidth: Math.min(Math.max(deviceNameMetrics.width + 32, 84), 260)

    Text {
        id: label
        anchors.centerIn: parent
        text: !root.powered
            ? String.fromCodePoint(0xF00B2)  // mdi-bluetooth-off
            : root.connected
                ? String.fromCodePoint(0xF00B1)  // mdi-bluetooth-connect
                : String.fromCodePoint(0xF00AF)  // mdi-bluetooth
        color: root.powered ? theme.fg : theme.muted
        font.pixelSize: 12
        font.family: "Hack Nerd Font"
    }

    TextMetrics {
        id: deviceNameMetrics
        text: root.deviceName
        font.pixelSize: 12
        font.family: "Hack Nerd Font"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
