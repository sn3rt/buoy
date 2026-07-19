import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    Theme { id: theme }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-notifications"

    anchors {
        top: true
        right: true
    }

    implicitWidth: 390
    implicitHeight: Math.max(1, notificationStack.implicitHeight + 34)
    visible: notificationServer.trackedNotifications.values.length > 0
    color: "transparent"

    mask: Region { item: notificationStack }

    function trimNotifications() {
        const notifications = notificationServer.trackedNotifications.values;
        while (notifications.length > 4)
            notifications[0].dismiss();
    }

    NotificationServer {
        id: notificationServer

        keepOnReload: false
        persistenceSupported: false
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: false
        actionIconsSupported: false
        imageSupported: false
        inlineReplySupported: false

        onNotification: notification => {
            notification.tracked = true;
            Qt.callLater(root.trimNotifications);
        }
    }

    Column {
        id: notificationStack

        anchors {
            top: parent.top
            right: parent.right
            topMargin: 28
            rightMargin: 12
        }
        width: 360
        spacing: 8

        Repeater {
            model: notificationServer.trackedNotifications

            Rectangle {
                id: card

                required property var modelData
                readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                readonly property int displayTime: modelData.expireTimeout > 0
                    ? Math.max(2000, modelData.expireTimeout)
                    : (critical ? 10000 : 6000)

                width: notificationStack.width
                height: modelData.body.length > 0 ? 94 : 70
                radius: 10
                color: theme.panelStrong
                border.width: 1
                border.color: critical
                    ? Qt.rgba(theme.error.r, theme.error.g, theme.error.b, 0.72)
                    : Qt.rgba(theme.primary.r, theme.primary.g, theme.primary.b, 0.38)

                HoverHandler {
                    id: cardHover
                    cursorShape: Qt.PointingHandCursor
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: card.modelData.dismiss()
                }

                Timer {
                    interval: card.displayTime
                    running: !cardHover.hovered && card.modelData.expireTimeout !== 0
                    repeat: false
                    onTriggered: card.modelData.expire()
                }

                RowLayout {
                    anchors {
                        fill: parent
                        margins: 12
                    }
                    spacing: 10

                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 9
                        color: card.critical
                            ? Qt.rgba(theme.error.r, theme.error.g, theme.error.b, 0.20)
                            : Qt.rgba(theme.primary.r, theme.primary.g, theme.primary.b, 0.20)

                        Text {
                            anchors.centerIn: parent
                            text: card.critical ? "" : "󰂚"
                            color: card.critical ? theme.error : theme.primary
                            font.family: "Hack Nerd Font"
                            font.pixelSize: 17
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.appName || "Notification"
                            color: theme.muted
                            font.family: "Hack Nerd Font"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.summary || "Notification"
                            color: theme.fg
                            font.family: "Hack Nerd Font"
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: card.modelData.body.length > 0
                            text: card.modelData.body
                            textFormat: Text.PlainText
                            color: theme.subtle
                            font.family: "Hack Nerd Font"
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignTop
                        text: ""
                        color: closeHover.hovered ? theme.fg : theme.muted
                        font.family: "Hack Nerd Font"
                        font.pixelSize: 12

                        HoverHandler {
                            id: closeHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            onClicked: card.modelData.dismiss()
                        }
                    }
                }
            }
        }
    }
}
