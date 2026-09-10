pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "components"

Item {
    id: root
    property var shell: null
    ShelfStore { id: shelf }
    Variants {
        id: windows
        model: Quickshell.screens
        ShelfWindow {
            required property var modelData
            screen: modelData
            store: shelf
        }
    }
    IpcHandler {
        target: "oshelf"
        function show(): void { for (var window of windows.instances) window.reveal(); }
        function hide(): void { for (var window of windows.instances) window.collapse(); }
        function clear(): void { shelf.clear(); }
        function settings(): void { for (var window of windows.instances) window.openSettings(); }
    }
}
