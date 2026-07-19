import Quickshell
import QtQuick
import ".."

Item {
    Theme { id: theme }
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    property int todayYear: clock.date.getFullYear()
    property int todayMonth: clock.date.getMonth()
    property int todayDay: clock.date.getDate()
    property int visibleYear: todayYear
    property int visibleMonth: todayMonth
    property int firstWeekday: (new Date(visibleYear, visibleMonth, 1).getDay() + 6) % 7
    property int daysInMonth: new Date(visibleYear, visibleMonth + 1, 0).getDate()
    property var weekdays: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    function resetMonth() {
        visibleYear = todayYear
        visibleMonth = todayMonth
    }

    // Step by whole months, rolling the year over at the Dec/Jan boundary.
    function stepMonth(delta) {
        let m = visibleMonth + delta
        let y = visibleYear
        while (m < 0) { m += 12; y -= 1 }
        while (m > 11) { m -= 12; y += 1 }
        visibleMonth = m
        visibleYear = y
    }

    // Mouse wheel / two-finger vertical scroll changes the month. Accumulate to
    // one notch (120) per month so a single scroll gesture doesn't skip several.
    property real _wheelAccum: 0
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            _wheelAccum += event.angleDelta.y
            while (_wheelAccum >= 120) { stepMonth(-1); _wheelAccum -= 120 }
            while (_wheelAccum <= -120) { stepMonth(1); _wheelAccum += 120 }
        }
    }

    Column {
        anchors {
            fill: parent
            margins: 8
        }
        spacing: 8

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Text {
                width: 22
                height: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "<"
                color: theme.fg
                font.pixelSize: 13
                font.family: "Roboto"

                MouseArea {
                    anchors.fill: parent
                    onClicked: stepMonth(-1)
                }
            }

            Text {
                width: 160
                height: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: Qt.formatDateTime(new Date(visibleYear, visibleMonth, 1), "MMMM yyyy")
                color: theme.fg
                font.pixelSize: 13
                font.family: "Roboto"
            }

            Text {
                width: 22
                height: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: ">"
                color: theme.fg
                font.pixelSize: 13
                font.family: "Roboto"

                MouseArea {
                    anchors.fill: parent
                    onClicked: stepMonth(1)
                }
            }
        }

        Grid {
            columns: 7
            rows: 1
            columnSpacing: 4
            rowSpacing: 0
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: weekdays

                Text {
                    required property string modelData
                    width: 34
                    height: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: theme.subtle
                    font.pixelSize: 10
                    font.family: "Roboto"
                }
            }
        }

        Grid {
            columns: 7
            rows: 6
            columnSpacing: 4
            rowSpacing: 3
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: 42

                Rectangle {
                    required property int index

                    property int dayNumber: index - firstWeekday + 1
                    property bool inMonth: dayNumber >= 1 && dayNumber <= daysInMonth
                    property bool isToday: inMonth
                        && visibleYear === todayYear
                        && visibleMonth === todayMonth
                        && dayNumber === todayDay

                    width: 34
                    height: 18
                    radius: 9
                    color: isToday ? theme.primary : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: parent.inMonth ? parent.dayNumber : ""
                        color: parent.isToday ? theme.fg : theme.subtle
                        font.pixelSize: 11
                        font.family: "Roboto"
                    }
                }
            }
        }
    }
}
