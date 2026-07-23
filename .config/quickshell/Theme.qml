import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property string paletteText: ""
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"
    readonly property string palettePath: stateHome + "/theme/palette"
    readonly property var palette: parsePalette(paletteText)

    readonly property color bg: colorValue("background", "#150e0e")
    readonly property color bgAlt: colorValue("inactive_tab_background", "#3c280f")
    readonly property color fg: colorValue("foreground", "#eeebe2")
    readonly property color muted: colorValue("color8", "#86817c")
    readonly property color subtle: colorValue("color12", "#c6ac81")
    readonly property color primary: colorValue("color5", "#ee9f11")
    readonly property color accent: colorValue("color6", "#c79b61")
    readonly property color warning: colorValue("color3", "#e2b24e")
    readonly property color error: colorValue("color1", "#e5575d")
    readonly property bool isLight: relativeLuminance(bg) > 0.5
    readonly property color panel: isLight ? alphaColor(bgAlt, 0.94) : mixColor(bg, primary, 0.18, 0.90)
    readonly property color panelStrong: isLight ? mixColor(bgAlt, primary, 0.06, 0.98) : mixColor(bg, primary, 0.18, 0.96)

    readonly property FileView paletteFile: FileView {
        id: paletteFile
        path: root.palettePath
        watchChanges: true
        preload: true
        blockLoading: false
        printErrors: false

        onLoaded: root.paletteText = text()
        onTextChanged: root.paletteText = text()
        onFileChanged: reload()
    }

    function parsePalette(text) {
        const values = {};
        for (const line of text.split("\n")) {
            const trimmed = line.trim();
            if (trimmed.length === 0 || trimmed.startsWith("#"))
                continue;

            const fields = trimmed.split(/\s+/, 2);
            if (fields.length !== 2)
                continue;

            values[fields[0]] = fields[1];
        }
        return values;
    }

    function colorValue(key, fallback) {
        const value = palette[key];
        return value && /^#[0-9a-fA-F]{6}$/.test(value) ? value : fallback;
    }

    function mixColor(a, b, amount, alpha) {
        const clamped = Math.max(0, Math.min(1, amount));
        return Qt.rgba(
            a.r * (1 - clamped) + b.r * clamped,
            a.g * (1 - clamped) + b.g * clamped,
            a.b * (1 - clamped) + b.b * clamped,
            alpha
        );
    }

    function alphaColor(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    function relativeLuminance(color) {
        function linear(channel) {
            return channel <= 0.04045
                ? channel / 12.92
                : Math.pow((channel + 0.055) / 1.055, 2.4);
        }

        return 0.2126 * linear(color.r)
            + 0.7152 * linear(color.g)
            + 0.0722 * linear(color.b);
    }
}
