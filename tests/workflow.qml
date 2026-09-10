import QtQuick
import Quickshell
import "../components" as Shelf

ShellRoot {
    function surface(item) {
        if (item.objectName === "oshelf-surface") return item;
        for (var child of item.children || []) {
            var found = surface(child);
            if (found) return found;
        }
        return null;
    }
    Shelf.ShelfStore { id: store; preferences.path: "" }
    Shelf.ShelfPreferences { id: persisted; path: Quickshell.env("OSHELF_TEST_CONFIG") }
    Shelf.ShelfWindow { id: shelf; store: store }
    function check(condition, message) { if (!condition) throw new Error(message); }
    function drop(text) {
        return {supportedActions: Qt.CopyAction, formats: ["text/plain"], hasText: true,
            text: text, hasUrls: false, accepted: false,
            getDataAsArrayBuffer: function() { return new ArrayBuffer(12); },
            accept: function() { this.accepted = true; }};
    }
    Timer {
        interval: 500; running: true
        onTriggered: {
            try {
                check(persisted.ready && persisted.values.placement === "left" && persisted.values.sideWidth === 520, "preferences load from disk");
                check(persisted.values.closeDelay === 250, "disk preferences are bounded");
                persisted.apply({placement: "bottom", bottomWidth: 1100});
                store.accept(drop("first snippet"), "");
                store.accept(drop("second snippet"), "");
                var first = store.items[0].id;
                store.remove(first);
                check(store.canUndo && store.items.length === 1, "remove offers undo");
                store.draggingId = store.items[0].id;
                store.undo();
                check(store.items.length === 1, "undo blocked during drag");
                store.draggingId = "";
                store.undo();
                check(store.items.length === 2 && store.items[0].id === first && store.usedBytes === 24, "undo restores order and budget");
                store.clear();
                check(store.canUndo && store.usedBytes === 0, "clear offers undo");
                store.undo();
                check(store.model.count === 2 && store.usedBytes === 24, "clear undo restores model");
                store.remove(first);
                store.accept(drop("new snippet"), "");
                check(!store.canUndo && store.items.length === 2, "successful incoming drop releases undo");
                store.clear();
                store.accept({supportedActions: Qt.MoveAction}, "");
                check(store.canUndo, "rejected drop preserves undo");
                store.undo();
                shelf.reveal();
                check(shelf.matchCount === 2, "empty search matches all");
                shelf.query = "SECOND snippet";
                check(shelf.matchCount === 1, "search matches all words regardless of case");
                shelf.query = "not present";
                check(shelf.matchCount === 0, "search can have no results");
                shelf.query = "projects report";
                check(shelf.matches({title: "Report", detail: "File reference", kind: "file", paths: ["/home/example/Projects/report.pdf"]}), "search includes file paths");
                store.accept(drop("incoming item"), "");
                check(shelf.query === "" && shelf.matchCount === 3, "incoming drop resets search");
                shelf.query = "";
                shelf.compact = true;
                shelf.keepOpen = true;
                check(shelf.engaged, "keep open prevents auto close");
                shelf.collapse();
                check(!shelf.expanded, "explicit close works when kept open");
                for (var placement of ["left", "right", "bottom"]) {
                    store.preferences.apply({placement: placement, reducedMotion: true});
                    shelf.reveal();
                    var panel = surface(shelf.contentItem);
                    check(panel.width > 0 && panel.height > 0, "positive panel dimensions");
                    check(panel.x >= 0 && panel.y >= 0 && panel.x + panel.width <= shelf.width && panel.y + panel.height <= shelf.height, "panel fits on " + placement);
                    check(shelf.horizontal === (placement === "bottom"), "tray orientation");
                    shelf.collapse();
                }
                store.preferences.apply({sideWidth: 640, sideHeight: 1000});
                shelf.reveal();
                check(surface(shelf.contentItem).height <= shelf.height - 32, "large popup fits monitor");
                shelf.openSettings();
                check(shelf.settingsOpen && shelf.engaged, "settings stay open");
                shelf.collapse();
                store.preferences.apply({placement: Quickshell.env("OSHELF_VIEW") === "settings" ? "right" : Quickshell.env("OSHELF_VIEW")});
                console.log("PASS shelf workflow");
                if (Quickshell.env("OSHELF_CAPTURE")) {
                    shelf.compact = false;
                    store.clear();
                    store.accept(drop("Design notes\nKeep the everyday path quick, calm, and easy to discover."), "");
                    store.accept(drop("https://doc.qt.io/qt-6/qml-qtquick-item.html"), "");
                    store.accept(drop("git switch -c feature/shelf-polish"), "");
                    shelf.reveal();
                    if (Quickshell.env("OSHELF_VIEW") === "settings") shelf.openSettings();
                    capture.start();
                } else finish.start();
            } catch (error) {
                console.error("FAIL " + error.message);
                Qt.quit();
            }
        }
    }
    Timer { id: finish; interval: 400; onTriggered: Qt.quit() }
    Timer {
        id: capture; interval: 400
        onTriggered: surface(shelf.contentItem).grabToImage(function(result) {
            result.saveToFile(Quickshell.env("OSHELF_CAPTURE"));
            Qt.quit();
        })
    }
}
