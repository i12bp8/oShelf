pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons

PanelWindow {
    id: root
    required property var store
    readonly property var preferences: store.preferences.values
    readonly property string placement: preferences.placement
    readonly property bool horizontal: placement === "bottom"
    readonly property bool reducedMotion: preferences.reducedMotion
    property bool expanded: false
    property bool keepOpen: false
    property bool compact: false
    property bool settingsOpen: false
    property alias query: search.text
    property real openness: expanded ? 1 : 0
    property real dwellProgress: 0
    property point hoverOrigin: Qt.point(0, 0)
    readonly property bool engaged: edgeHover.hovered || panelHover.hovered || landing.containsDrag || store.busy || keepOpen || settingsOpen || search.activeFocus
    readonly property int matchCount: store.items.filter(entry => matches(entry)).length
    readonly property real zoneLength: Math.min(preferences.activationLength, (horizontal ? width : height) * 0.8)
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "oshelf"
    WlrLayershell.keyboardFocus: expanded && !store.busy ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    // Only these regions receive input; the rest of the desktop passes through.
    mask: Region {
        item: edge
        Region { item: surface; width: root.expanded ? surface.width : 0; radius: surface.radius }
    }
    Behavior on openness {
        NumberAnimation { duration: root.reducedMotion ? 0 : root.expanded ? root.preferences.motionDuration : Math.round(root.preferences.motionDuration * 0.75); easing.type: Easing.OutCubic }
    }
    function matches(entry) {
        var haystack = [entry.title, entry.detail, entry.kind].concat(entry.paths || []).join(" ").toLowerCase();
        return search.text.toLowerCase().trim().split(/\s+/).every(function(word) { return haystack.indexOf(word) >= 0; });
    }
    function reveal() {
        closeTimer.stop(); stopDwell();
        if (expanded) return;
        expanded = true;
        store.refresh();
        content.forceActiveFocus();
    }
    function collapse() {
        if (store.busy) return;
        expanded = false;
        settingsOpen = false;
        content.forceActiveFocus();
        stopDwell();
    }
    function openSettings() { if (!store.busy) { reveal(); settings.begin(); settingsOpen = true; } }
    function stopDwell() { hoverTimer.stop(); dwell.stop(); dwellProgress = 0; }
    function startDwell() {
        if (expanded || !edgeHover.hovered) return;
        stopDwell(); hoverOrigin = edgeHover.point.position;
        hoverTimer.restart(); dwell.restart();
    }
    function moveHover(point) {
        if (expanded || !preferences.steadyHover || !edgeHover.hovered) return;
        var dx = point.x - hoverOrigin.x, dy = point.y - hoverOrigin.y;
        if (dx * dx + dy * dy > 36) startDwell();
    }
    function scrollBy(amount) {
        if (horizontal) list.contentX = Math.max(0, Math.min(list.contentWidth - list.width, list.contentX + amount));
        else list.contentY = Math.max(0, Math.min(list.contentHeight - list.height, list.contentY + amount));
    }
    onEngagedChanged: { if (engaged) closeTimer.stop(); else if (expanded) closeTimer.restart(); }
    onPlacementChanged: stopDwell()
    Connections {
        target: root.store
        function onItemAdded() { search.clear(); Qt.callLater(function() { list.positionViewAtEnd(); }); }
    }
    Timer { id: closeTimer; interval: root.preferences.closeDelay; onTriggered: { if (!root.engaged) root.collapse(); } }
    Timer { id: hoverTimer; interval: root.preferences.openDelay; onTriggered: { if (edgeHover.hovered) root.reveal(); } }
    NumberAnimation { id: dwell; target: root; property: "dwellProgress"; from: 0; to: 1; duration: root.preferences.openDelay }

    Item {
        id: edge
        objectName: "oshelf-edge"
        width: root.horizontal ? root.zoneLength : root.preferences.activationDepth
        height: root.horizontal ? root.preferences.activationDepth : root.zoneLength
        x: root.horizontal ? (root.width - width) * root.preferences.activationPosition / 100 : root.placement === "left" ? 0 : root.width - width
        y: root.horizontal ? root.height - height : (root.height - height) * root.preferences.activationPosition / 100
        HoverHandler {
            id: edgeHover
            onHoveredChanged: { if (hovered) root.startDwell(); else root.stopDwell(); }
            onPointChanged: root.moveHover(point.position)
        }
        Rectangle {
            anchors.centerIn: parent
            width: root.horizontal ? (edgeHover.hovered ? 76 : 44) : 3
            height: root.horizontal ? 3 : (edgeHover.hovered ? 76 : 44)
            radius: 2
            color: Util.alpha(Color.foreground, edgeHover.hovered ? 0.3 : root.store.items.length ? 0.3 : 0.13)
            opacity: 1 - root.openness
            Behavior on width { NumberAnimation { duration: root.reducedMotion ? 0 : 180; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: root.reducedMotion ? 0 : 180; easing.type: Easing.OutCubic } }
            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left }
                width: root.horizontal ? parent.width * root.dwellProgress : parent.width
                height: root.horizontal ? parent.height : parent.height * root.dwellProgress
                radius: 2; color: Color.accent
            }
        }
        TapHandler { onTapped: root.reveal() }
    }

    Rectangle {
        id: surface
        objectName: "oshelf-surface"
        readonly property real inset: 16
        readonly property real openX: root.placement === "left" ? inset : root.horizontal ? (root.width - width) / 2 : root.width - width - inset
        readonly property real openY: root.horizontal ? root.height - height - inset : Math.max(inset, Math.min(root.height - height - inset, (root.height - height) * root.preferences.activationPosition / 100))
        width: Math.min(root.width - 32, root.settingsOpen ? 400 : root.horizontal ? root.preferences.bottomWidth : root.preferences.sideWidth)
        height: Math.min(root.height - 32, root.settingsOpen ? 620 : root.horizontal ? root.preferences.bottomHeight : root.preferences.sideHeight)
        x: openX + (root.reducedMotion ? 0 : (1 - root.openness) * (root.placement === "left" ? -32 : root.horizontal ? 0 : 32))
        y: openY + (root.reducedMotion || !root.horizontal ? 0 : (1 - root.openness) * 32)
        scale: root.reducedMotion ? 1 : 0.97 + root.openness * 0.03
        opacity: root.openness
        visible: root.openness > 0
        radius: 24
        color: Color.background
        border.width: 1
        border.color: landing.containsDrag ? Util.alpha(Color.accent, 0.75) : Util.alpha(Color.foreground, 0.15)
        layer.enabled: visible
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#000000"; shadowOpacity: 0.35; shadowBlur: 0.65; shadowVerticalOffset: 8 }
        HoverHandler { id: panelHover }
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 1 }
            height: Math.min(parent.height, 160); radius: 23
            gradient: Gradient {
                GradientStop { position: 0; color: Util.alpha(Color.accent, 0.085) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        FocusScope {
            id: content
            anchors.fill: parent
            Keys.onEscapePressed: { if (root.settingsOpen) root.settingsOpen = false; else if (search.text) search.clear(); else root.collapse(); }
            Keys.onPressed: event => {
                if (root.settingsOpen) return;
                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
                    search.forceActiveFocus(); event.accepted = true;
                } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Z) {
                    root.store.undo(); event.accepted = true;
                } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Backspace) {
                    root.store.clear(); event.accepted = true;
                } else if (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) {
                    root.scrollBy((event.key === Qt.Key_PageDown ? 1 : -1) * (root.horizontal ? list.width : list.height) * 0.85);
                    event.accepted = true;
                } else if (event.key === Qt.Key_End || event.key === Qt.Key_Home) {
                    if (event.key === Qt.Key_End) list.positionViewAtEnd(); else list.positionViewAtBeginning();
                    event.accepted = true;
                }
            }
            Rectangle {
                x: 22; y: 22; width: 40; height: 40; radius: 13
                color: Util.alpha(Color.accent, 0.12)
                border.width: 1; border.color: Util.alpha(Color.accent, 0.17)
                Glyph { anchors.centerIn: parent; kind: root.settingsOpen ? "settings" : "shelf"; ink: Color.accent; width: 23; height: 23 }
            }
            Text {
                x: 74; y: 20
                text: root.settingsOpen ? "Make it yours" : "oShelf"
                color: Color.foreground
                font.family: Style.fontFamily; font.pixelSize: root.settingsOpen ? 19 : 23; font.weight: Font.DemiBold; font.letterSpacing: -0.6
            }
            Text {
                x: 74; y: 49
                text: root.settingsOpen ? "A shelf that fits your flow" : "A place between apps"
                color: Util.alpha(Color.foreground, 0.5)
                font.family: Style.fontFamily; font.pixelSize: 10
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 16; y: 23; spacing: 2
                ShelfAction { label: ""; icon: "settings"; hint: "Shelf settings"; visible: !root.settingsOpen; enabled: !root.store.busy; onTriggered: root.openSettings() }
                ShelfAction { label: ""; icon: "close"; hint: "Close shelf"; onTriggered: root.collapse() }
            }
            ShelfSettings {
                id: settings
                x: 22; y: 91; width: parent.width - 44; height: parent.height - 111
                visible: root.settingsOpen; preferences: root.store.preferences
                onApplied: { root.settingsOpen = false; content.forceActiveFocus(); }
                onCancelled: { root.settingsOpen = false; content.forceActiveFocus(); }
            }
            Item {
                id: browsing
                anchors.fill: parent; visible: !root.settingsOpen
                TextField {
                    id: search
                    x: 22; y: 84; width: parent.width - 44; height: 40
                    placeholderText: "Find anything on your shelf"
                    color: Color.foreground; placeholderTextColor: Util.alpha(Color.foreground, 0.4)
                    selectionColor: Color.accent; selectedTextColor: Color.background
                    font.family: Style.fontFamily; font.pixelSize: 12
                    leftPadding: 38; rightPadding: 12
                    enabled: !root.store.busy; selectByMouse: true
                    Accessible.name: "Search shelf"
                    onTextChanged: list.positionViewAtBeginning()
                    Keys.onEscapePressed: { if (text) clear(); else root.collapse(); }
                    Keys.onReturnPressed: {
                        for (var i = 0; i < root.store.items.length; i++) {
                            if (root.matches(root.store.items[i])) {
                                list.currentIndex = i; list.positionViewAtIndex(i, ListView.Contain);
                                if (list.currentItem) list.currentItem.forceActiveFocus();
                                break;
                            }
                        }
                    }
                    background: Rectangle {
                        radius: 12; color: Util.alpha(Color.foreground, 0.035)
                        border.width: 1; border.color: search.activeFocus ? Util.alpha(Color.accent, 0.65) : Util.alpha(Color.foreground, 0.09)
                        Glyph { x: 12; anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; kind: "search"; ink: Util.alpha(Color.foreground, 0.4) }
                    }
                }
                Text {
                    x: 24; y: 143
                    text: search.text ? root.matchCount + " MATCHES" : root.store.items.length ? "ON YOUR SHELF  ·  " + root.store.items.length : "READY WHEN YOU ARE"
                    color: Util.alpha(Color.foreground, 0.45)
                    font.family: Style.fontFamily; font.pixelSize: 9; font.letterSpacing: 1
                }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 18; y: 130; spacing: 2
                    ShelfAction { label: ""; icon: "pin"; hint: "Keep open"; selected: root.keepOpen; onTriggered: root.keepOpen = !root.keepOpen }
                    ShelfAction { label: ""; icon: "compact"; hint: root.compact ? "Comfortable cards" : "Compact cards"; selected: root.compact; enabled: !root.store.busy; onTriggered: root.compact = !root.compact }
                }
                ListView {
                    id: list
                    x: 20; y: 175; width: parent.width - 40; height: Math.max(0, parent.height - 243)
                    spacing: 0; clip: true
                    orientation: root.horizontal ? ListView.Horizontal : ListView.Vertical
                    model: root.store.model; boundsBehavior: Flickable.StopAtBounds
                    delegate: ShelfCard {
                        store: root.store; compact: root.compact; matches: root.matches(entry)
                        horizontal: root.horizontal; reducedMotion: root.reducedMotion
                        width: !matches && root.horizontal ? 0 : root.horizontal ? 268 : list.width
                        onPickedUp: closeTimer.stop()
                        onSettled: { if (!root.engaged) closeTimer.restart(); }
                    }
                    move: Transition { NumberAnimation { properties: "x,y"; duration: root.reducedMotion ? 0 : 200; easing.type: Easing.OutCubic } }
                    ScrollBar.vertical: ScrollBar { policy: root.horizontal ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded }
                    ScrollBar.horizontal: ScrollBar { policy: root.horizontal ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
                    WheelHandler {
                        acceptedModifiers: Qt.NoModifier
                        onWheel: event => {
                            var pixels = root.horizontal && event.pixelDelta.x ? event.pixelDelta.x : event.pixelDelta.y;
                            var angle = root.horizontal && event.angleDelta.x ? event.angleDelta.x : event.angleDelta.y;
                            root.scrollBy(-(pixels || angle / 120 * 100)); event.accepted = true;
                        }
                    }
                }
                Column {
                    visible: !root.matchCount; anchors.centerIn: list
                    width: Math.min(list.width - 24, 320); spacing: 14
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: list.height >= 170
                        width: root.horizontal ? 48 : 64; height: visible ? width : 0; radius: 20
                        color: Util.alpha(Color.accent, 0.065)
                        border.width: 1; border.color: Util.alpha(Color.accent, 0.13)
                        rotation: landing.containsDrag && !root.reducedMotion ? -5 : 0
                        Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Glyph { anchors.centerIn: parent; width: 28; height: 28; kind: search.text ? "search" : "shelf"; ink: Color.accent }
                    }
                    Text {
                        width: parent.width; text: search.text ? "No matches. Yet." : landing.containsDrag ? "Make yourself at home." : "Leave it here for a moment."
                        wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter
                        color: Color.foreground; font.family: Style.fontFamily; font.pixelSize: 17; font.weight: Font.Medium
                    }
                    Text {
                        width: parent.width; text: search.text ? "Try a filename, a link, or a few words." : "Files, links, images, little thoughts.\nDrop here. Pick up wherever you go."
                        horizontalAlignment: Text.AlignHCenter; lineHeight: 1.45; wrapMode: Text.Wrap
                        color: Util.alpha(Color.foreground, 0.5); font.family: Style.fontFamily; font.pixelSize: 11
                    }
                }
                Rectangle {
                    x: 22; y: parent.height - 61; width: parent.width - 44; height: 1
                    color: Util.alpha(Color.foreground, 0.075)
                }
                Text {
                    x: 24; y: parent.height - 42; width: parent.width - 174
                    text: root.store.message || (root.store.canUndo ? "Removed · undo available" : landing.containsDrag ? "Release to park" : "Temporary by design")
                    textFormat: Text.PlainText; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                    color: landing.containsDrag ? Color.accent : Util.alpha(Color.foreground, root.store.message ? 0.8 : 0.45)
                    font.family: Style.fontFamily; font.pixelSize: 10
                }
                Row {
                    anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 12
                    ShelfAction { label: "Undo"; visible: root.store.canUndo; enabled: !root.store.busy; onTriggered: root.store.undo() }
                    ShelfAction { label: "Clear"; enabled: !!root.store.items.length && !root.store.busy; onTriggered: root.store.clear() }
                }
            }
        }
    }
    DropArea {
        id: landing
        anchors.fill: parent; z: -1
        onEntered: drag => { drag.accepted = !!(drag.supportedActions & Qt.CopyAction); if (drag.accepted) root.reveal(); }
        onExited: { if (!root.engaged) closeTimer.restart(); }
        onDropped: drop => { root.store.accept(drop, ""); root.reveal(); }
    }
}
