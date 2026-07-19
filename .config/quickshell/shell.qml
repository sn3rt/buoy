import Quickshell
import Quickshell.Io
import "."

ShellRoot {
    function mainScreen() {
        for (let s of Quickshell.screens.values())
            if (s.name === "eDP-1") return s;
        return null;
    }

    Bar {
        screen: mainScreen()
    }

    CapturePopup {
        screen: mainScreen()
    }

    Variants {
        model: Quickshell.screens
        WorkspaceBar {}
    }
}
