import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: root

    Theme { id: theme }
    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: 5
    WlrLayershell.namespace: "quickshell-workspaces"

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: 48
    color: "transparent"

    property bool hovered: false
    property real scaleFactor: hovered ? 5 : 1

    Behavior on scaleFactor {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    // Only the hover zone grabs input; the rest of the (tall) window is
    // click-through so windows below stay interactive.
    mask: Region { item: hoverZone }

    property var thisMonitor: screen ? Hyprland.monitorFor(screen) : null

    ScriptModel {
        id: workspaceModel
        values: {
            if (!root.thisMonitor) return [];
            const monitorName = root.thisMonitor.name;
            return [...Hyprland.workspaces.values]
                .filter(workspace => workspace.id > 0
                    && workspace.monitor
                    && workspace.monitor.name === monitorName)
                .sort((left, right) => left.id - right.id);
        }
    }

    Component.onCompleted: {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
    }

    // Hyprland does not emit events for every action that can invalidate
    // workspace/monitor state. Keep the model accurate even after a missed
    // event or a transient event-socket interruption.
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            Hyprland.refreshMonitors();
            Hyprland.refreshWorkspaces();
        }
    }

    Item {
        id: hoverZone
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 1
        }
        width: pill.width
        // Slightly taller than the visible pill so the thin bar is easy to hit,
        // without blocking the bottom edge of normal windows when collapsed.
        height: Math.max(7, pill.height + 2)

        // HoverHandler (not MouseArea) so nested per-dot hover handlers don't
        // steal the hover and make the bar flicker.
        HoverHandler {
            onHoveredChanged: root.hovered = hovered
        }

        Rectangle {
            id: pill
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
            }
            height: 4 * root.scaleFactor
            width: dotRow.implicitWidth + 10
            radius: 2 * root.scaleFactor
            color: theme.panel

            Row {
                id: dotRow
                anchors.centerIn: parent
                spacing: 4 * root.scaleFactor

                Repeater {
                    model: workspaceModel

                    Rectangle {
                        id: dot
                        required property var modelData

                        readonly property bool isActive: modelData.active

                        width: isActive ? 60 : 30
                        height: 2 * root.scaleFactor
                        radius: 1 * root.scaleFactor
                        color: isActive
                            ? (dotHover.hovered ? Qt.lighter(theme.primary, 1.3) : theme.primary)
                            : (dotHover.hovered ? theme.accent : theme.bgAlt)
                        opacity: 1

                        Behavior on width {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }

                        // Passive hover (no grab) so it doesn't fight the click MouseArea
                        // or the bar's grow HoverHandler.
                        HoverHandler {
                            id: dotHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: false
                            // This Hyprland uses a Lua config, so dispatchers are the
                            // hl.dsp.* API; switching workspace is hl.dsp.focus({workspace=N}).
                            onClicked: {
                                Quickshell.execDetached(["/usr/bin/hyprctl", "dispatch",
                                    "hl.dsp.focus({ workspace = " + dot.modelData.id + " })"])
                            }
                        }
                    }
                }
            }
        }
    }
}
