import Quickshell.Io
import QtQuick
import ".."

Item {
    id: root

    Theme { id: theme }
    implicitWidth: label.implicitWidth + 8
    implicitHeight: 22

    // Only present while an app is actively recording from the mic; RowLayout
    // drops invisible items from layout, so it collapses without leaving a gap.
    visible: inUse

    property string recorder: ""
    readonly property bool inUse: recorder.length > 0
    property bool muted: false

    property bool keepPopupOpen: false
    property bool showName: (mouseArea.containsMouse || keepPopupOpen) && inUse
    property int popupWidth: Math.min(Math.max(recorderMetrics.width + 32, 84), 260)

    Process {
        id: micProc
        command: ["sh", "-c", "pw-dump | jq -r '[.[] | select(.type==\"PipeWire:Interface:Node\") | select(.info.props[\"media.class\"]==\"Stream/Input/Audio\") | select(.info.state==\"running\") | (.info.props[\"application.name\"] // .info.props[\"node.name\"] // \"Mic\")] | unique | join(\", \")'"]
        stdout: StdioCollector {}
        onExited: root.recorder = stdout.text.trim()
    }

    Process {
        id: muteProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {}
        onExited: root.muted = /\[MUTED\]/.test(stdout.text)
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            micProc.running = true
            muteProc.running = true
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.muted
            ? String.fromCodePoint(0xF036D)  // mdi-microphone-off
            : String.fromCodePoint(0xF036C)  // mdi-microphone
        color: theme.fg
        font.pixelSize: 12
        font.family: "Hack Nerd Font"
    }

    TextMetrics {
        id: recorderMetrics
        text: root.recorder
        font.pixelSize: 12
        font.family: "Hack Nerd Font"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
