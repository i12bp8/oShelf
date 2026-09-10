import QtQuick
import qs.Commons
import "../native" as Native

FocusScope {
    id: root
    objectName: "oshelf-card"
    required property var entry
    required property var store
    property bool compact: false
    property bool matches: true
    property bool horizontal: false
    property bool reducedMotion: false
    signal pickedUp()
    signal settled()
    width: ListView.view ? ListView.view.width : 328
    visible: matches
    height: !matches ? 0 : horizontal && ListView.view ? ListView.view.height - 8 : (compact ? 100 : entry.thumbnail ? 228 : entry.thumbs && entry.thumbs.length ? 192 : entry.kind === "text" ? 152 : 112) + 10
    activeFocusOnTab: true
    Accessible.role: Accessible.ListItem
    Accessible.name: entry.title + ". " + entry.detail
    Keys.onDeletePressed: store.remove(entry.id)
    Keys.onPressed: event => {
        if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Up || event.key === Qt.Key_Down || (root.horizontal && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)))) {
            var index = store.items.findIndex(item => item.id === entry.id);
            var target = event.key === Qt.Key_Up || event.key === Qt.Key_Left ? index - 1 : index + 2;
            if (target >= 0) store.move(entry.id, target < store.items.length ? store.items[target].id : "");
            event.accepted = true;
        }
    }
    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 1
        anchors.bottomMargin: 11
        anchors.rightMargin: root.horizontal ? 11 : 1
        radius: 16
        color: Qt.tint(Color.background, Util.alpha(Color.foreground, pointer.containsMouse ? 0.065 : 0.025))
        border.width: 1
        border.color: root.activeFocus || target.containsDrag ? Color.accent : Util.alpha(Color.foreground, pointer.containsMouse ? 0.25 : 0.10)
        Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 140 } }
        Behavior on border.color { ColorAnimation { duration: root.reducedMotion ? 0 : 140 } }
        opacity: root.store.draggingId === root.entry.id ? 0.45 : 1
        Behavior on opacity { NumberAnimation { duration: root.reducedMotion ? 0 : 120 } }
        scale: 1
        Component.onCompleted: { if (!root.reducedMotion) arrival.start(); }
        SequentialAnimation {
            id: arrival
            NumberAnimation { target: card; property: "scale"; from: 0.97; to: 1; duration: 220; easing.type: Easing.OutCubic }
        }
        Thumbnail {
            id: thumbnail
            x: 10; y: 10; width: parent.width - 20; height: root.horizontal ? Math.max(40, card.height - 80) : 142
            rounded: true; radius: 10
            visible: !!root.entry.thumbnail && !root.compact
            source: root.entry.thumbnail
        }
        Rectangle {
            x: 13; y: 10; width: 30; height: 28; radius: 9
            visible: !root.entry.thumbnail || root.compact
            color: Util.alpha(Color.accent, 0.07)
            Glyph { anchors.centerIn: parent; width: 17; height: 17; kind: root.entry.kind; ink: Color.accent; opacity: 0.85 }
        }
        Text {
            x: root.entry.thumbnail && !root.compact ? 18 : 53; y: root.entry.thumbnail && !root.compact ? thumbnail.y + thumbnail.height + 8 : 19
            width: parent.width - x - 86
            text: root.entry.kind === "url" ? "LINK" : root.entry.kind === "folder" ? "FOLDER"
                : root.entry.kind === "text" ? "TEXT" : root.entry.kind === "image" || root.entry.thumbnail ? "IMAGE"
                : root.entry.kind === "file" ? "FILE" : "TRANSFER"
            textFormat: Text.PlainText
            color: Color.accent
            opacity: 0.85
            font.family: Style.fontFamily
            font.pixelSize: 10
            font.letterSpacing: 1.4
        }
        Text {
            x: 18; y: root.entry.thumbnail && !root.compact ? thumbnail.y + thumbnail.height + 27 : 47
            width: parent.width - 36
            height: root.compact ? 22 : root.entry.thumbnail ? 24 : root.entry.kind === "text" ? Math.min(70, card.height - 85) : 26
            text: root.entry.title
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: root.entry.kind === "text" && !root.compact ? 3 : 1
            elide: Text.ElideRight
            color: Color.foreground
            font.family: Style.fontFamily
            font.pixelSize: root.compact ? 14 : root.entry.kind === "text" ? 14 : 16
            font.weight: root.entry.kind === "text" ? Font.Normal : Font.DemiBold
            lineHeight: 1.15
        }
        Text {
            x: 18; y: parent.height - 29; width: parent.width - 84
            visible: !root.entry.thumbnail || root.compact
            text: root.entry.missing ? "Reference unavailable" : root.entry.paths.length === 1 ? root.entry.paths[0] : root.entry.detail
            textFormat: Text.PlainText
            elide: Text.ElideMiddle
            color: Color.foreground
            opacity: 0.48
            font.family: Style.fontFamily
            font.pixelSize: 11
        }
        Row {
            x: 18; y: 80
            visible: !root.compact && !!root.entry.thumbs && !!root.entry.thumbs.length
            spacing: 8
            Repeater {
                model: root.entry.thumbs ? root.entry.thumbs : []
                Thumbnail {
                    width: root.horizontal ? 42 : 54; height: width
                    rounded: true; radius: 8
                    quiet: true
                    borderColor: Util.alpha(Color.foreground, 0.08)
                    source: modelData
                }
            }
            Rectangle {
                visible: (root.entry.thumbMore || 0) > 0
                width: root.horizontal ? 42 : 54; height: width
                radius: 8
                color: Qt.tint(Color.background, Util.alpha(Color.foreground, 0.05))
                border.width: 1
                border.color: Util.alpha(Color.foreground, 0.10)
                Text {
                    anchors.centerIn: parent
                    text: "+" + root.entry.thumbMore
                    textFormat: Text.PlainText
                    color: Color.foreground
                    opacity: 0.5
                    font.family: Style.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
            }
        }
        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            drag.target: root.entry.missing ? null : dragHandle
            drag.threshold: 10
            onPressed: {
                root.forceActiveFocus();
                if (root.entry.missing) root.store.message = "This reference is unavailable. Restore the file or remove the card.";
            }
            drag.onActiveChanged: if (drag.active) nativeDrag.start(card, root.entry.mime)
        }
        ShelfAction {
            id: removeAction
            anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 6
            label: ""; icon: "close"; hint: "Remove card"
            visible: (pointer.containsMouse || root.activeFocus || activeFocus) && !root.store.busy
            onTriggered: root.store.remove(root.entry.id)
        }
    }
    Item { id: dragHandle }
    Native.NativeDrag {
        id: nativeDrag
        onActiveChanged: {
            if (active) {
                root.store.draggingId = root.entry.id;
                root.pickedUp();
            } else {
                root.store.draggingId = "";
            }
        }
        onFinished: root.settled()
    }
    DropArea {
        id: target
        anchors.fill: parent
        onEntered: drag => { drag.accepted = !!(drag.supportedActions & Qt.CopyAction); }
        onDropped: drop => root.store.accept(drop, root.entry.id)
    }
}
