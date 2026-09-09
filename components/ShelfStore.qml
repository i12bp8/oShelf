import QtQuick
import Quickshell.Io
import "../lib/Payload.js" as Payload

Item {
    id: root
    property var items: []
    readonly property alias model: rows
    ListModel { id: rows; dynamicRoles: true }
    property int usedBytes: 0
    property int nextId: 0
    property string draggingId: ""
    property string message: ""
    property var metadataQueue: []
    property string checkingId: ""
    readonly property bool busy: draggingId !== ""

    function find(id) { return items.find(function(item) { return item.id === id; }); }
    function accept(drop, before) {
        if (!(drop.supportedActions & Qt.CopyAction)) {
            message = "This source does not allow copying.";
            drop.accepted = false;
            return;
        }
        if (busy) {
            move(draggingId, before);
            drop.accept(Qt.CopyAction);
            return;
        }
        try {
            if (items.length >= Payload.maxItems) throw new Error("The shelf is full. Remove a card to make room.");
            var item = Payload.capture(drop, Payload.maxShelfBytes - usedBytes);
            item.id = String(++nextId);
            items = items.concat([item]);
            rows.append({entry: item});
            usedBytes += item.bytes;
            message = "";
            queueMetadata(item.id);
            drop.accept(Qt.CopyAction);
        } catch (error) {
            message = error.message;
            drop.accepted = false;
        }
    }
    function remove(id) {
        if (busy) return;
        var item = find(id);
        if (!item) return;
        rows.remove(items.findIndex(function(entry) { return entry.id === id; }));
        usedBytes -= item.bytes;
        items = items.filter(function(entry) { return entry.id !== id; });
    }
    function clear() {
        if (busy) return;
        rows.clear(); items = []; usedBytes = 0; message = ""; metadataQueue = [];
    }
    function move(id, before) {
        if (id === before) return;
        var item = find(id);
        if (!item) return;
        var reordered = items.filter(function(entry) { return entry.id !== id; });
        var index = reordered.findIndex(function(entry) { return entry.id === before; });
        reordered.splice(index < 0 ? reordered.length : index, 0, item);
        var oldIndex = items.findIndex(function(entry) { return entry.id === id; });
        rows.move(oldIndex, reordered.indexOf(item), 1);
        items = reordered;
    }
    function refresh() { items.forEach(function(item) { queueMetadata(item.id); }); }
    function queueMetadata(id) {
        var item = find(id);
        if (!item || !item.paths.length || metadataQueue.indexOf(id) >= 0) return;
        metadataQueue = metadataQueue.concat([id]);
        startMetadata();
    }
    function startMetadata() {
        if (metadata.running || !metadataQueue.length) return;
        checkingId = metadataQueue[0];
        metadataQueue = metadataQueue.slice(1);
        var item = find(checkingId);
        if (!item) { startMetadata(); return; }
        metadata.running = true;
    }
    Process {
        id: metadata
        command: ["python3", decodeURIComponent(Qt.resolvedUrl("../scripts/metadata.py").toString().replace(/^file:\/\//, ""))]
        stdinEnabled: true
        onStarted: {
            var item = root.find(root.checkingId);
            write(JSON.stringify(item ? item.paths : []) + "\n");
            stdinEnabled = false;
            deadline.restart();
        }
        stdout: StdioCollector {
            onStreamFinished: {
                var item = root.find(root.checkingId);
                if (!item) return;
                try {
                    var info = JSON.parse(text);
                    item.missing = info.some(function(entry) { return !entry.exists; });
                    if (item.paths.length === 1 && info.length === 1) {
                        item.kind = info[0].kind;
                        item.detail = item.missing ? "Reference unavailable" : item.kind === "folder" ? "Folder reference" : "File reference";
                        item.thumbnail = info[0].image ? "file://" + item.paths[0].split("/").map(encodeURIComponent).join("/") : "";
                        item.thumbs = [];
                        item.thumbMore = 0;
                    } else if (info.length === item.paths.length) {
                        var thumbs = [], images = 0;
                        for (var i = 0; i < info.length; i++) {
                            if (info[i].exists && info[i].image) {
                                images++;
                                if (thumbs.length < 4)
                                    thumbs.push("file://" + item.paths[i].split("/").map(encodeURIComponent).join("/"));
                            }
                        }
                        if (images > 4) {
                            thumbs = thumbs.slice(0, 3);
                            item.thumbMore = images - 3;
                        } else {
                            item.thumbMore = 0;
                        }
                        item.thumbs = thumbs;
                    }
                    rows.setProperty(root.items.indexOf(item), "entry", Object.assign({}, item));
                    root.items = root.items.slice();
                } catch (_) { root.message = "Could not check a file reference."; }
            }
        }
        onExited: {
            deadline.stop();
            stdinEnabled = true;
            Qt.callLater(root.startMetadata);
        }
    }
    Timer { id: deadline; interval: 2000; onTriggered: { metadata.running = false; root.message = "A file location is not responding."; } }
}
