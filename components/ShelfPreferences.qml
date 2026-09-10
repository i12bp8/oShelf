import QtQuick
import Quickshell
import Quickshell.Io
import "../lib/Preferences.js" as Preferences

QtObject {
    id: root
    property string path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omarchy/oshelf.json"
    property var values: Preferences.normalize({})
    property string error: ""
    property bool ready: path === ""
    function defaults() { return Preferences.normalize({}); }
    function apply(candidate) {
        if (!ready) { error = "Preferences are still loading. Try again in a moment."; return false; }
        values = Preferences.normalize(candidate);
        error = "";
        if (path) file.setText(JSON.stringify(values, null, 2) + "\n");
        return true;
    }
    property FileView file: FileView {
        path: root.path
        watchChanges: !!root.path
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.values = Preferences.normalize(JSON.parse(text()));
                root.error = "";
            } catch (_) { root.error = "Preferences could not be read. Safe defaults are available below."; }
            root.ready = true;
        }
        onLoadFailed: root.ready = true
        onSaveFailed: root.error = "Could not save preferences. Changes apply only until reload."
    }
}
