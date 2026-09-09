pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

PanelWindow {
    id: root
    required property var store
    property bool expanded: false
    readonly property bool engaged: edgeHover.hovered || panelHover.hovered || landing.containsDrag || store.busy
    anchors { top: true; bottom: true; right: true }
    implicitWidth: 392
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "oshelf"
    WlrLayershell.keyboardFocus: expanded && !store.busy ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region {
        item: edge
        Region { item: surface; width: root.expanded ? surface.width : 0 }
    }
    function reveal() {
        expanded = true;
        closeTimer.stop();
        store.refresh();
        content.forceActiveFocus();
    }
    function collapse() { if (!store.busy) expanded = false; }
    onEngagedChanged: {
        if (engaged) closeTimer.stop();
        else closeTimer.restart();
    }
    Connections {
        target: root.store
        function onItemsChanged() {
            if (!root.store.items.length && !root.engaged) closeTimer.restart();
        }
    }
    Timer { id: closeTimer; interval: 850; onTriggered: root.collapse() }
    Timer { id: hoverTimer; interval: 180; onTriggered: root.reveal() }
    Rectangle {
        id: edge
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 8; height: Math.min(240, root.height * 0.45)
        color: "transparent"
        HoverHandler {
            id: edgeHover
            onHoveredChanged: { if (hovered) hoverTimer.restart(); else hoverTimer.stop(); }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: edgeHover.hovered || landing.containsDrag ? 4 : 2
            height: edgeHover.hovered || landing.containsDrag ? 64 : 32
            radius: 2
            color: Color.foreground
            opacity: root.expanded ? 0 : edgeHover.hovered || landing.containsDrag ? 0.7 : root.store.items.length ? 0.35 : 0.10
            Behavior on opacity { NumberAnimation { duration: 130 } }
            Behavior on height { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        }
        TapHandler { onTapped: root.reveal() }
    }
    Rectangle {
        id: surface
        width: root.width - 20
        height: Math.min(root.height - 64, Math.max(300, Math.min(744, list.contentHeight + 166)))
        anchors.verticalCenter: parent.verticalCenter
        x: root.expanded ? 0 : root.width + 4
        radius: 22
        color: Color.background
        border.width: 1
        border.color: Util.alpha(Color.foreground, 0.19)
        clip: true
        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        HoverHandler { id: panelHover }
        FocusScope {
            id: content
            anchors.fill: parent
            Keys.onEscapePressed: root.collapse()
            Keys.onPressed: event => {
                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Backspace) {
                    root.store.clear(); event.accepted = true;
                }
            }
            Text {
                x: 24; y: 23
                text: "oShelf"
                color: Color.foreground
                font.family: Style.fontFamily
                font.pixelSize: 28
                font.weight: Font.DemiBold
                font.letterSpacing: -1
            }
            Text {
                anchors.right: parent.right; anchors.rightMargin: 26; y: 32
                text: root.store.items.length ? String(root.store.items.length).padStart(2, "0") : ""
                color: Color.foreground; opacity: 0.4
                font.family: Style.fontFamily; font.pixelSize: 13
            }
            ListView {
                id: list
                x: 20; y: 78; width: parent.width - 40; height: parent.height - 137
                spacing: 10
                clip: true
                model: root.store.model
                boundsBehavior: Flickable.StopAtBounds
                delegate: ShelfCard {
                    store: root.store
                    onPickedUp: closeTimer.stop()
                    onSettled: { if (!root.engaged) closeTimer.restart(); }
                }
                move: Transition { NumberAnimation { properties: "x,y"; duration: 150; easing.type: Easing.OutCubic } }
            }
            Column {
                visible: !root.store.items.length
                anchors.centerIn: list
                width: list.width - 20
                spacing: 13
                Text {
                    width: parent.width; text: "Here for now."
                    horizontalAlignment: Text.AlignHCenter
                    color: Color.foreground
                    font.family: Style.fontFamily; font.pixelSize: 23; font.weight: Font.Medium
                }
                Text {
                    width: parent.width; text: "Drop something here.\nPick it up in another workspace."
                    horizontalAlignment: Text.AlignHCenter; lineHeight: 1.5
                    color: Color.foreground; opacity: 0.5
                    font.family: Style.fontFamily; font.pixelSize: 13
                }
            }
            Text {
                x: 24; y: parent.height - 41; width: parent.width - 120
                text: root.store.message || (landing.containsDrag ? "Release to park" : "Park anything. Pick it up anywhere.")
                textFormat: Text.PlainText
                wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                color: Color.foreground; opacity: root.store.message ? 0.85 : 0.45
                font.family: Style.fontFamily; font.pixelSize: 10
            }
            Action {
                anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 12
                label: root.store.items.length ? "Clear" : "Close"
                enabled: !root.store.busy
                onTriggered: { if (root.store.items.length) root.store.clear(); else root.collapse(); }
            }
        }
    }
    DropArea {
        id: landing
        anchors.fill: parent
        z: -1
        onEntered: drag => {
            drag.accepted = !!(drag.supportedActions & Qt.CopyAction);
            if (drag.accepted) root.reveal();
        }
        onExited: { if (!root.engaged) closeTimer.restart(); }
        onDropped: drop => { root.store.accept(drop, ""); root.reveal(); }
    }
}
