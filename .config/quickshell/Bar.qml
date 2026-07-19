import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "./modules"

PanelWindow {
    id: root

    Theme { id: theme }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: 22
    WlrLayershell.namespace: "quickshell-bar"

    anchors {
        top: true
        left: true
        right: true
    }

    property bool overPopup: clockDateMouseArea.containsMouse || clockAgendaMouseArea.containsMouse
    property bool clockAreaHovered: clock.hovered || overPopup

    // The agenda expands only while the pointer is over the popup body. Hovering
    // the time itself collapses back to the plain date view, and leaving the
    // clock area entirely closes the popup — both immediate, no hold timer, like
    // the cpu/temp/etc. dropdowns. The bubble's openProgress animation handles
    // the smooth transition.
    property bool agendaOpen: overPopup && !clock.hovered
    property bool agendaVisible: agendaOpen
    property bool agendaLoaded: false

    // Lazy-load the calendar the first time the agenda is reached; keep it loaded.
    onOverPopupChanged: if (overPopup) agendaLoaded = true

    implicitHeight: 238
    color: "transparent"

    mask: Region {
        Region { item: barSurface }
        Region { item: networkPopup; width: networkPopup.openProgress > 0.01 ? networkPopup.width : 0; height: networkPopup.openProgress > 0.01 ? networkPopup.height : 0 }
        Region { item: bluetoothPopup; width: bluetoothPopup.openProgress > 0.01 ? bluetoothPopup.width : 0; height: bluetoothPopup.openProgress > 0.01 ? bluetoothPopup.height : 0 }
        Region { item: micPopup; width: micPopup.openProgress > 0.01 ? micPopup.width : 0; height: micPopup.openProgress > 0.01 ? micPopup.height : 0 }
        Region { item: clockPopup; width: clockPopup.openProgress > 0.01 ? clockPopup.width : 0; height: clockPopup.openProgress > 0.01 ? clockPopup.height : 0 }
        Region { item: cpuPopup; width: cpuPopup.openProgress > 0.01 ? cpuPopup.width : 0; height: cpuPopup.openProgress > 0.01 ? cpuPopup.height : 0 }
        Region { item: memPopup; width: memPopup.openProgress > 0.01 ? memPopup.width : 0; height: memPopup.openProgress > 0.01 ? memPopup.height : 0 }
        Region { item: tempPopup; width: tempPopup.openProgress > 0.01 ? tempPopup.width : 0; height: tempPopup.openProgress > 0.01 ? tempPopup.height : 0 }
        Region { item: audioPopup; width: audioPopup.openProgress > 0.01 ? audioPopup.width : 0; height: audioPopup.openProgress > 0.01 ? audioPopup.height : 0 }
        Region { item: batteryPopup; width: batteryPopup.openProgress > 0.01 ? batteryPopup.width : 0; height: batteryPopup.openProgress > 0.01 ? batteryPopup.height : 0 }
    }

    Rectangle {
        id: barSurface
        z: 2
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 22
        radius: 0
        color: theme.panel

        RowLayout {
            id: leftStatus
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: 10
            }
            spacing: 0
            SysStats {
                id: sysStats
            }
        }

        Clock {
            id: clock
            anchors.centerIn: parent
        }

        RowLayout {
            id: rightStatus
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                rightMargin: 10
            }
            spacing: 0
            Mpd {}
            RecordingStatus {}
            Network {
                id: network
            }
            BluetoothStatus {
                id: bluetooth
            }
            MicStatus {
                id: mic
            }
            Audio {
                id: audio
            }
            Battery {
                id: battery
            }
        }
    }

    function popupX(centerX, popupWidth) {
        return Math.max(0, Math.min(root.width - popupWidth, centerX - popupWidth / 2))
    }

    LiquidStatusPopout {
        id: networkPopup
        x: root.popupX(barSurface.x + rightStatus.x + network.x + network.width / 2, width)
        y: 0
        z: 1
        width: network.popupWidth
        text: network.networkName
        openProgress: network.showNetworkName ? 1 : 0
    }

    LiquidStatusPopout {
        id: bluetoothPopup
        x: root.popupX(barSurface.x + rightStatus.x + bluetooth.x + bluetooth.width / 2, width)
        y: 0
        z: 1
        width: bluetooth.popupWidth
        text: bluetooth.deviceName
        openProgress: bluetooth.showDeviceName ? 1 : 0
    }

    LiquidStatusPopout {
        id: micPopup
        x: root.popupX(barSurface.x + rightStatus.x + mic.x + mic.width / 2, width)
        y: 0
        z: 1
        width: mic.popupWidth
        text: mic.recorder
        openProgress: mic.showName ? 1 : 0
    }

    LiquidStatusPopout {
        id: clockPopup
        x: root.popupX(barSurface.x + clock.x + clock.width / 2, width)
        y: 0
        z: 1
        width: root.agendaOpen || root.agendaVisible ? 284 : clock.popupWidth
        bubbleHeight: root.agendaOpen || root.agendaVisible ? 208 : 30
        text: clock.dateText
        showText: !root.agendaOpen && !root.agendaVisible
        openProgress: root.clockAreaHovered || root.agendaOpen || root.agendaVisible ? 1 : 0

        Loader {
            id: inlineAgendaCalendar
            anchors {
                fill: parent
                topMargin: 10
            }
            source: root.agendaLoaded ? "modules/AgendaCalendar.qml" : ""
            opacity: root.agendaVisible ? 1 : 0
            y: root.agendaOpen ? 0 : -8
            scale: root.agendaOpen ? 1 : 0.96
            transformOrigin: Item.Top

            onLoaded: {
                if (!root.agendaOpen && item && item.resetMonth) item.resetMonth()
            }

            Connections {
                target: root
                function onAgendaOpenChanged() {
                    if (!root.agendaOpen && inlineAgendaCalendar.item && inlineAgendaCalendar.item.resetMonth) {
                        inlineAgendaCalendar.item.resetMonth()
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
            }

            Behavior on y {
                NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
                NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
            }
        }
    }

    LiquidStatusPopout {
        id: cpuPopup
        x: root.popupX(barSurface.x + leftStatus.x + sysStats.x + sysStats.cpuCenterX, width)
        y: 0
        z: 1
        width: sysStats.cpuPopupWidth
        text: sysStats.cpuPopupText
        textPixelSize: 11
        horizontalPadding: 9
        bubbleHeight: 24
        openProgress: sysStats.showCpuValue ? 1 : 0
    }

    LiquidStatusPopout {
        id: memPopup
        x: root.popupX(barSurface.x + leftStatus.x + sysStats.x + sysStats.memCenterX, width)
        y: 0
        z: 1
        width: sysStats.memPopupWidth
        text: sysStats.memPopupText
        textPixelSize: 11
        horizontalPadding: 9
        bubbleHeight: 24
        openProgress: sysStats.showMemValue ? 1 : 0
    }

    LiquidStatusPopout {
        id: tempPopup
        x: root.popupX(barSurface.x + leftStatus.x + sysStats.x + sysStats.tempCenterX, width)
        y: 0
        z: 1
        width: sysStats.tempPopupWidth
        text: sysStats.tempPopupText
        textPixelSize: 11
        horizontalPadding: 9
        bubbleHeight: 24
        openProgress: sysStats.showTempValue ? 1 : 0
    }

    LiquidStatusPopout {
        id: audioPopup
        x: root.popupX(barSurface.x + rightStatus.x + audio.x + audio.width / 2, width)
        y: 0
        z: 1
        width: audio.popupWidth
        text: audio.popupText
        textPixelSize: 11
        horizontalPadding: 9
        bubbleHeight: 24
        openProgress: audio.showValue ? 1 : 0
    }

    LiquidStatusPopout {
        id: batteryPopup
        x: root.popupX(barSurface.x + rightStatus.x + battery.x + battery.width / 2, width)
        y: 0
        z: 1
        width: battery.popupWidth
        text: battery.popupText
        textPixelSize: 11
        horizontalPadding: 9
        bubbleHeight: 24
        openProgress: battery.showValue ? 1 : 0
    }

    MouseArea {
        x: networkPopup.x
        y: barSurface.height
        z: 3
        width: networkPopup.width
        height: networkPopup.height - barSurface.height
        enabled: networkPopup.openProgress > 0.01
        hoverEnabled: true
        onContainsMouseChanged: network.keepPopupOpen = containsMouse
    }

    MouseArea {
        x: bluetoothPopup.x
        y: barSurface.height
        z: 3
        width: bluetoothPopup.width
        height: bluetoothPopup.height - barSurface.height
        enabled: bluetoothPopup.openProgress > 0.01
        hoverEnabled: true
        onContainsMouseChanged: bluetooth.keepPopupOpen = containsMouse
    }

    MouseArea {
        x: micPopup.x
        y: barSurface.height
        z: 3
        width: micPopup.width
        height: micPopup.height - barSurface.height
        enabled: micPopup.openProgress > 0.01
        hoverEnabled: true
        onContainsMouseChanged: mic.keepPopupOpen = containsMouse
    }

    MouseArea {
        id: clockDateMouseArea
        x: root.popupX(barSurface.x + clock.x + clock.width / 2, clock.popupWidth)
        y: barSurface.height
        z: 3
        width: clock.popupWidth
        height: 35
        enabled: clockPopup.openProgress > 0.01 && !root.agendaOpen
        hoverEnabled: true
    }

    MouseArea {
        id: clockAgendaMouseArea
        x: clockPopup.x
        y: barSurface.height
        z: root.agendaOpen ? 0 : 3
        width: clockPopup.width
        height: clockPopup.height - barSurface.height
        enabled: root.agendaOpen || root.agendaVisible
        hoverEnabled: true
    }

    MouseArea {
        x: cpuPopup.x
        y: barSurface.height
        z: 3
        width: cpuPopup.width
        height: cpuPopup.height - barSurface.height
        enabled: cpuPopup.openProgress > 0.01
        hoverEnabled: true
        onContainsMouseChanged: sysStats.keepCpuPopupOpen = containsMouse
    }

    MouseArea {
        x: memPopup.x
        y: barSurface.height
        z: 3
        width: memPopup.width
        height: memPopup.height - barSurface.height
        enabled: memPopup.openProgress > 0.01
        hoverEnabled: true
        onContainsMouseChanged: sysStats.keepMemPopupOpen = containsMouse
    }

    MouseArea {
        x: tempPopup.x
        y: barSurface.height
        z: 3
        width: tempPopup.width
        height: tempPopup.height - barSurface.height
        enabled: tempPopup.openProgress > 0.01
        hoverEnabled: true
        onContainsMouseChanged: sysStats.keepTempPopupOpen = containsMouse
    }

    MouseArea {
        x: audioPopup.x
        y: barSurface.height
        z: 3
        width: audioPopup.width
        height: audioPopup.height - barSurface.height
        enabled: audioPopup.openProgress > 0.01
        hoverEnabled: true
        onContainsMouseChanged: audio.keepPopupOpen = containsMouse
    }

    MouseArea {
        x: batteryPopup.x
        y: barSurface.height
        z: 3
        width: batteryPopup.width
        height: batteryPopup.height - barSurface.height
        enabled: batteryPopup.openProgress > 0.01
        hoverEnabled: true
        onContainsMouseChanged: battery.keepPopupOpen = containsMouse
    }

}
