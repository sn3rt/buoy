import Quickshell
import QtQuick
import ".."

Item {
    id: root

    Theme { id: theme }
    implicitWidth: timeText.implicitWidth + 16
    implicitHeight: parent.height
    width: implicitWidth
    height: implicitHeight

    property bool keepPopupOpen: false
    property bool hovered: mouseArea.containsMouse
    property string dateText: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
    property bool showDate: hovered || keepPopupOpen
    property int popupWidth: Math.min(Math.max(dateWidth.width + 40, 190), 520)

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Text {
        id: timeText
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "hh:mm")
        color: theme.fg
        font.pixelSize: 12
        font.family: "Roboto"
    }

    Text {
        id: dateWidth
        visible: false
        text: root.dateText
        font.pixelSize: timeText.font.pixelSize
        font.family: timeText.font.family
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
