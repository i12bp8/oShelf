import QtQuick
import QtQuick.Effects
import qs.Commons

Item {
    id: root
    property url source
    property bool failed: false
    property bool ready: false
    property bool rounded: false
    property real radius: 8
    property color borderColor: "transparent"
    property bool quiet: false
    implicitWidth: 64
    implicitHeight: 64
    Image {
        id: pic
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        source: root.source
        sourceSize: Qt.size(Math.round(root.width), Math.round(root.height))
        layer.enabled: root.rounded
        layer.effect: MultiEffect {
            maskSource: mask
        }
        onStatusChanged: {
            if (status === Image.Ready) {
                root.ready = true;
                root.failed = false;
            } else if (status === Image.Error) {
                root.failed = true;
                root.ready = false;
            }
        }
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
    }
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: root.borderColor === "transparent" ? 0 : 1
        border.color: root.borderColor
        visible: root.rounded && root.borderColor !== "transparent"
    }
    Text {
        anchors.centerIn: parent
        visible: root.failed && !root.quiet
        text: "Preview unavailable"
        color: Color.foreground
        opacity: 0.5
        font.family: Style.fontFamily
        font.pixelSize: 12
    }
}
