import QtQuick
import ".."

Item {
    id: root

    Theme { id: theme }

    property color fillColor: theme.panel
    property string text: ""
    property real openProgress: 0
    property int barHeight: 22
    property int bubbleHeight: 30
    property int horizontalPadding: 14
    property int textPixelSize: 12
    property int contentWidth: label.implicitWidth
    property bool showText: true
    default property alias content: contentLayer.data

    implicitWidth: Math.min(Math.max(contentWidth + horizontalPadding * 2, 56), 320)
    implicitHeight: barHeight + bubbleHeight + 5
    opacity: openProgress > 0.01 ? 1 : 0

    Canvas {
        id: shape
        anchors.fill: parent

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: root

            function onFillColorChanged() { shape.requestPaint() }
            function onOpenProgressChanged() { shape.requestPaint() }
            function onBarHeightChanged() { shape.requestPaint() }
            function onBubbleHeightChanged() { shape.requestPaint() }
        }

        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const p = Math.max(0, Math.min(1, root.openProgress));
            const ease = 1 - Math.pow(1 - p, 3);

            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            if (p <= 0.001 || w <= 1) {
                return;
            }

            const center = w / 2;
            const joinY = root.barHeight;
            const bubbleWidth = 30 + (w - 30) * ease;
            const bubbleLeft = center - bubbleWidth / 2;
            const bubbleRight = center + bubbleWidth / 2;
            const bottom = root.barHeight + 4 + root.bubbleHeight * ease;
            const radius = Math.min(10, bubbleWidth / 2, Math.max(1, (bottom - joinY) / 2));

            ctx.fillStyle = root.fillColor;
            ctx.beginPath();
            ctx.moveTo(bubbleLeft, joinY);
            ctx.lineTo(bubbleRight, joinY);
            ctx.lineTo(bubbleRight, bottom - radius);
            ctx.lineTo(bubbleRight, bottom - radius);
            ctx.quadraticCurveTo(bubbleRight, bottom, bubbleRight - radius, bottom);
            ctx.lineTo(bubbleLeft + radius, bottom);
            ctx.quadraticCurveTo(bubbleLeft, bottom, bubbleLeft, bottom - radius);
            ctx.lineTo(bubbleLeft, joinY);
            ctx.closePath();
            ctx.fill();
        }
    }

    Text {
        id: label
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: root.barHeight + 2
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        height: root.bubbleHeight + 2
        text: root.text
        color: theme.fg
        opacity: Math.max(0, Math.min(1, (root.openProgress - 0.25) / 0.75))
        visible: root.showText
        font.pixelSize: root.textPixelSize
        font.family: "Hack Nerd Font"
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    Item {
        id: contentLayer
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: root.barHeight
            bottom: parent.bottom
        }
        clip: true
    }

    Behavior on openProgress {
        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
    }

    Behavior on bubbleHeight {
        NumberAnimation { duration: 360; easing.type: Easing.OutCubic }
    }

    Behavior on width {
        NumberAnimation { duration: 360; easing.type: Easing.OutCubic }
    }
}
