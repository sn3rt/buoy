import QtQuick
import ".."

Canvas {
    id: root

    Theme { id: theme }

    property color fillColor: theme.panelStrong
    property int cornerRadius: 14
    property real openProgress: 0

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onCornerRadiusChanged: requestPaint()
    onOpenProgressChanged: requestPaint()

    Behavior on openProgress {
        NumberAnimation {
            duration: 520
            easing.type: Easing.OutCubic
        }
    }

    onPaint: {
        const ctx = getContext("2d");
        const w = width;
        const h = height;
        const r = cornerRadius;
        const p = Math.max(0, Math.min(1, openProgress));
        const ease = 1 - Math.pow(1 - p, 3);
        const bottom = 20 + (h - 20) * ease;

        ctx.reset();
        ctx.clearRect(0, 0, w, h);
        if (p <= 0.001) {
            return;
        }

        ctx.fillStyle = fillColor;
        ctx.beginPath();

        ctx.moveTo(0, 0);
        ctx.lineTo(w, 0);
        ctx.lineTo(w, bottom - r);
        ctx.quadraticCurveTo(w, bottom, w - r, bottom);
        ctx.lineTo(r, bottom);
        ctx.quadraticCurveTo(0, bottom, 0, bottom - r);
        ctx.lineTo(0, 0);
        ctx.closePath();
        ctx.fill();
    }
}
