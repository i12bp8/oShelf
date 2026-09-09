import QtQuick
import qs.Commons
import "../native" as Native

FocusScope {
    id: root
    objectName: "oshelf-card"
    required property var entry
    required property var store
    signal pickedUp()
    signal settled()
    width: ListView.view ? ListView.view.width : 328
    height: entry.thumbnail ? 218 : entry.kind === "text" ? 152 : 112
    activeFocusOnTab: true
    Accessible.role: Accessible.ListItem
    Accessible.name: entry.title + ". " + entry.detail
    Keys.onDeletePressed: store.remove(entry.id)
    Keys.onPressed: event => {
        if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Up || event.key === Qt.Key_Down)) {
            var index = store.items.findIndex(item => item.id === entry.id);
            var target = event.key === Qt.Key_Up ? index - 1 : index + 2;
            if (target >= 0) store.move(entry.id, target < store.items.length ? store.items[target].id : "");
            event.accepted = true;
        }
    }
    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 1
        radius: 14
        color: Qt.tint(Color.background, Util.alpha(Color.foreground, pointer.containsMouse ? 0.075 : 0.035))
        border.width: 1
        border.color: root.activeFocus || target.containsDrag ? Color.accent : Util.alpha(Color.foreground, 0.14)
        opacity: root.store.draggingId === root.entry.id ? 0.45 : 1
        Behavior on opacity { NumberAnimation { duration: 100 } }
        scale: 1
        Component.onCompleted: arrival.start()
        SequentialAnimation {
            id: arrival
            NumberAnimation { target: card; property: "scale"; from: 0.965; to: 1; duration: 160; easing.type: Easing.OutCubic }
        }
        Thumbnail {
            id: thumbnail
            x: 10; y: 10; width: parent.width - 20; height: 142
            visible: !!root.entry.thumbnail
            source: root.entry.thumbnail
        }
        Glyph { x: 18; y: 12; kind: root.entry.kind; visible: !root.entry.thumbnail; opacity: 0.65 }
        Text {
            x: root.entry.thumbnail ? 18 : 50; y: root.entry.thumbnail ? 160 : 17
            width: parent.width - 36
            text: root.entry.kind === "url" ? "LINK" : root.entry.kind === "folder" ? "FOLDER"
                : root.entry.kind === "text" ? "TEXT" : root.entry.kind === "image" || root.entry.thumbnail ? "IMAGE"
                : root.entry.kind === "file" ? "FILE" : "TRANSFER"
            textFormat: Text.PlainText
            color: Color.foreground
            opacity: 0.48
            font.family: Style.fontFamily
            font.pixelSize: 10
            font.letterSpacing: 1.4
        }
        Text {
            x: 18; y: root.entry.thumbnail ? 179 : 39
            width: parent.width - 36
            height: root.entry.thumbnail ? 24 : root.entry.kind === "text" ? 75 : 29
            text: root.entry.title
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: root.entry.kind === "text" ? 3 : 1
            elide: Text.ElideRight
            color: Color.foreground
            font.family: Style.fontFamily
            font.pixelSize: root.entry.kind === "text" ? 16 : 19
            font.weight: root.entry.kind === "text" ? Font.Normal : Font.DemiBold
            lineHeight: 1.15
        }
        Text {
            x: 18; y: parent.height - 29; width: parent.width - 84
            visible: !root.entry.thumbnail
            text: root.entry.missing ? "Reference unavailable" : root.entry.detail
            textFormat: Text.PlainText
            elide: Text.ElideMiddle
            color: Color.foreground
            opacity: 0.48
            font.family: Style.fontFamily
            font.pixelSize: 11
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
        Action {
            anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 6
            label: "Remove"
            visible: (pointer.containsMouse || root.activeFocus) && !root.store.busy
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
